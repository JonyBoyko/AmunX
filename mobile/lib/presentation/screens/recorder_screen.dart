import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../app/theme.dart';
import '../../core/logging/app_logger.dart';
import '../../data/api/api_client.dart';
import '../providers/feed_provider.dart';
import '../providers/session_provider.dart';

@immutable
class RecordingSummary {
  final int duration;
  final bool isPublic;
  final String quality;
  final String mask;

  const RecordingSummary({
    required this.duration,
    required this.isPublic,
    required this.quality,
    required this.mask,
  });
}

class RecorderScreen extends ConsumerStatefulWidget {
  const RecorderScreen({super.key});

  @override
  ConsumerState<RecorderScreen> createState() => _RecorderScreenState();
}

class _RecorderScreenState extends ConsumerState<RecorderScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final TextEditingController _titleController = TextEditingController();
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  Timer? _timer;
  String? _activeRecordingPath;

  bool _isRecording = false;
  bool _isUploading = false;
  bool _isPublic = true;
  String _quality = 'Clean';
  String _mask = 'Off';
  int _duration = 0;
  double _audioLevel = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _amplitudeSubscription?.cancel();
    unawaited(_recorder.dispose());
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'РќР°РґР°Р№С‚Рµ РґРѕСЃС‚СѓРї РґРѕ РјС–РєСЂРѕС„РѕРЅР° Сѓ РЅР°Р»Р°С€С‚СѓРІР°РЅРЅСЏС…'),
          ),
        );
      }
      return;
    }

    final directory = await getTemporaryDirectory();
    final fileName = 'amunx-${DateTime.now().millisecondsSinceEpoch}.m4a';
    _activeRecordingPath = p.join(directory.path, fileName);

    AppLogger.info('Starting audio recording', tag: 'Recorder');
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        bitRate: 128000,
      ),
      path: _activeRecordingPath!,
    );

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _duration++;
      });
    });

    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 250))
        .listen((amp) {
      final normalized = ((amp.current + 45) / 45).clamp(0.0, 1.0);
      setState(() => _audioLevel = normalized.isNaN ? 0 : normalized);
    });

    setState(() {
      _isRecording = true;
      _duration = 0;
    });
  }

  Future<void> _stopRecording() async {
    AppLogger.info('Stopping audio recording', tag: 'Recorder');
    final path = await _recorder.stop();
    final resolvedPath = path ?? _activeRecordingPath;
    _activeRecordingPath = null;
    await _amplitudeSubscription?.cancel();
    _timer?.cancel();

    setState(() {
      _isRecording = false;
      _audioLevel = 0;
    });

    if (resolvedPath != null) {
      await _uploadRecording(resolvedPath);
      unawaited(File(resolvedPath).delete().catchError(
            (e) => AppLogger.warning('Failed to delete temp recording: $e',
                tag: 'Recorder'),
          ));
    }
  }

  Future<void> _uploadRecording(String filePath) async {
    final session = ref.read(sessionProvider);
    final token = session.token;
    if (token == null) {
      _showSnack("Увійди, щоб завантажити", isError: true);
      return;
    }

    setState(() => _isUploading = true);
    try {
      final client = createApiClient(token: token);
      final createResponse = await client.createEpisode({
        'visibility': _isPublic ? 'public' : 'private',
        'mask': _maskValue(),
        'quality': _qualityValue(),
        'duration_sec': _duration,
        'content_type': 'audio/mp4',
      });
      final episodeId = createResponse['id'] as String;
      final uploadUrl = createResponse['upload_url'] as String;
      final headers = Map<String, String>.from(
        (createResponse['upload_headers'] as Map?) ?? const {},
      );

      await _uploadToSignedUrl(uploadUrl, headers, filePath);
      await client.finalizeEpisode(episodeId);

      ref.invalidate(feedProvider);
      _showSnack("Епізод завантажено 🎧");
      if (mounted) {
        context.go('/feed');
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to upload recording',
        tag: 'Recorder',
        error: e,
        stackTrace: stackTrace,
      );
      _showSnack("Не вдалося завантажити: $e", isError: true);
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _uploadToSignedUrl(
    String url,
    Map<String, String> headers,
    String filePath,
  ) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final requestHeaders = <String, String>{};
    requestHeaders.addAll(headers);
    requestHeaders.putIfAbsent('Content-Type', () => 'audio/mp4');
    requestHeaders['Content-Length'] = bytes.length.toString();

    final response = await http.put(
      Uri.parse(url),
      headers: requestHeaders,
      body: bytes,
    );
    if (response.statusCode >= 400) {
      throw Exception('Upload failed (${response.statusCode})');
    }
  }

  String _maskValue() {
    switch (_mask.toLowerCase()) {
      case 'basic':
        return 'basic';
      case 'studio':
        return 'studio';
      default:
        return 'none';
    }
  }

  String _qualityValue() {
    switch (_quality.toLowerCase()) {
      case 'raw':
        return 'raw';
      case 'clean':
      default:
        return 'clean';
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.stateDanger : null,
      ),
    );
  }

  @override
  ConsumerState<RecorderScreen> createState() => _RecorderScreenState();
}

class _RecorderScreenState extends ConsumerState<RecorderScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final TextEditingController _titleController = TextEditingController();
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  Timer? _timer;
  String? _activeRecordingPath;

  bool _isRecording = false;
  bool _isUploading = false;
  bool _isPublic = true;
  String _quality = 'Clean';
  String _mask = 'Off';
  int _duration = 0;
  double _audioLevel = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _amplitudeSubscription?.cancel();
    unawaited(_recorder.dispose());
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'РќР°РґР°Р№С‚Рµ РґРѕСЃС‚СѓРї РґРѕ РјС–РєСЂРѕС„РѕРЅР° Сѓ РЅР°Р»Р°С€С‚СѓРІР°РЅРЅСЏС…'),
          ),
        );
      }
      return;
    }

    final directory = await getTemporaryDirectory();
    final fileName = 'amunx-${DateTime.now().millisecondsSinceEpoch}.m4a';
    _activeRecordingPath = p.join(directory.path, fileName);

    AppLogger.info('Starting audio recording', tag: 'Recorder');
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        bitRate: 128000,
      ),
      path: _activeRecordingPath!,
    );

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _duration++;
      });
    });

    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 250))
        .listen((amp) {
      final normalized = ((amp.current + 45) / 45).clamp(0.0, 1.0);
      setState(() => _audioLevel = normalized.isNaN ? 0 : normalized);
    });

    setState(() {
      _isRecording = true;
      _duration = 0;
    });
  }

  Future<void> _stopRecording() async {
    AppLogger.info('Stopping audio recording', tag: 'Recorder');
    final path = await _recorder.stop();
    final resolvedPath = path ?? _activeRecordingPath;
    _activeRecordingPath = null;
    await _amplitudeSubscription?.cancel();
    _timer?.cancel();

    setState(() {
      _isRecording = false;
      _audioLevel = 0;
    });

    if (resolvedPath != null) {
      await _uploadRecording(resolvedPath);
      unawaited(File(resolvedPath).delete().catchError(
            (e) => AppLogger.warning('Failed to delete temp recording: $e',
                tag: 'Recorder'),
          ));
    }
  }

  Future<void> _uploadRecording(String filePath) async {
    final session = ref.read(sessionProvider);
    final token = session.token;
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('РЎРїРѕС‡Р°С‚РєСѓ СѓРІС–Р№РґС–С‚СЊ Сѓ Р°РєР°СѓРЅС‚'),
          ),
        );
      }
      return;
    }

    setState(() => _isUploading = true);
    try {
      final client = createApiClient(token: token);
      await client.uploadDevEpisode(
        filePath: filePath,
        durationSeconds: _duration.clamp(1, 600),
        title: _titleController.text.trim().isEmpty
            ? 'Moweton entry'
            : _titleController.text.trim(),
      );
      ref.invalidate(feedProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Р•РїС–Р·РѕРґ Р·Р±РµСЂРµР¶РµРЅРѕ')),
        );
        context.go('/feed');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to upload recording',
          tag: 'Recorder', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('РќРµ РІРґР°Р»РѕСЃСЏ Р·Р°РІР°РЅС‚Р°Р¶РёС‚Рё: $e'),
            backgroundColor: AppTheme.stateDanger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spaceXl),
                child: Column(
                  children: [
                    if (_isRecording) _buildAudioLevel(),
                    const SizedBox(height: AppTheme.spaceXl),
                    _buildTimer(),
                    const SizedBox(height: AppTheme.spaceXl),
                    _buildRecordButton(),
                    const SizedBox(height: AppTheme.spaceXl),
                    _buildTitleField(),
                    const SizedBox(height: AppTheme.spaceXl),
                    _buildControlsCard(),
                    const SizedBox(height: AppTheme.spaceXl),
                    if (_isUploading)
                      const CircularProgressIndicator(
                          color: AppTheme.brandPrimary),
                    if (!_isUploading)
                      OutlinedButton.icon(
                        onPressed: () => context.push('/live/host'),
                        icon: const Icon(Icons.radio),
                        label: const Text('РџРѕС‡Р°С‚Рё Live'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.brandPrimary,
                          side: const BorderSide(color: AppTheme.brandPrimary),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLg,
        vertical: AppTheme.spaceMd,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _isUploading ? null : () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppTheme.textPrimary),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isPublic ? AppTheme.brandPrimary : AppTheme.surfaceChip,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              _isPublic ? 'PUBLIC' : 'ANON',
              style: const TextStyle(
                color: AppTheme.textInverse,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioLevel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        12,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 6,
          height: 24 + (index * 4),
          decoration: BoxDecoration(
            color: index / 12 < _audioLevel
                ? AppTheme.stateSuccess
                : AppTheme.surfaceChip,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  Widget _buildTimer() {
    final minutes = (_duration ~/ 60).toString().padLeft(2, '0');
    final seconds = (_duration % 60).toString().padLeft(2, '0');
    return Column(
      children: [
        Text(
          '$minutes:$seconds',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 48,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        if (_duration >= 60)
          const Text(
            'Р РµРєРѕРјРµРЅРґРѕРІР°РЅРѕ: 1 С…РІРёР»РёРЅР°',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
      ],
    );
  }

  Widget _buildRecordButton() {
    final progress = (_duration / 60).clamp(0.0, 1.0);
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: CircularProgressIndicator(
              value: _isRecording ? progress : 0,
              strokeWidth: 4,
              backgroundColor: AppTheme.surfaceBorder,
              valueColor: const AlwaysStoppedAnimation(AppTheme.brandPrimary),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  _isRecording ? AppTheme.stateDanger : AppTheme.brandPrimary,
              shape: const CircleBorder(),
              minimumSize: const Size(96, 96),
            ),
            onPressed: _isUploading ? null : _toggleRecording,
            child: Icon(
              _isRecording ? Icons.stop_rounded : Icons.mic,
              size: 36,
              color: AppTheme.textInverse,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      enabled: !_isRecording && !_isUploading,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: 'РќР°Р·РІР° РµРїС–Р·РѕРґСѓ',
        hintText: 'РќР°РїСЂРёРєР»Р°Рґ: рџ¤– РџСЂРѕ РЅРѕРІС– С„С–С‡С– GPT-5',
        filled: true,
        fillColor: AppTheme.bgRaised,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildControlsCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        color: AppTheme.bgRaised,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSwitch(
            label: 'РџСѓР±Р»С–С‡РЅРѕ',
            value: _isPublic,
            onChanged: _isRecording || _isUploading
                ? null
                : (value) => setState(() => _isPublic = value ?? true),
          ),
          const SizedBox(height: AppTheme.spaceLg),
          _buildSegmentControl(
            label: 'РЇРєС–СЃС‚СЊ',
            values: const ['Raw', 'Clean'],
            current: _quality,
            onChanged: (value) => setState(() => _quality = value),
          ),
          const SizedBox(height: AppTheme.spaceLg),
          _buildSegmentControl(
            label: 'РњР°СЃРєСѓРІР°РЅРЅСЏ',
            values: const ['Off', 'Basic', 'Studio'],
            current: _mask,
            onChanged: (value) => setState(() => _mask = value),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch({
    required String label,
    required bool value,
    required ValueChanged<bool?>? onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textPrimary)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.brandPrimary,
        ),
      ],
    );
  }

  Widget _buildSegmentControl({
    required String label,
    required List<String> values,
    required String current,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: values
              .map(
                (value) => ChoiceChip(
                  label: Text(value),
                  selected: current == value,
                  onSelected: (_isRecording || _isUploading)
                      ? null
                      : (selected) {
                          if (selected) onChanged(value);
                        },
                  selectedColor: AppTheme.brandPrimary,
                  backgroundColor: AppTheme.surfaceChip,
                  labelStyle: TextStyle(
                    color: current == value
                        ? AppTheme.textInverse
                        : AppTheme.textSecondary,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
