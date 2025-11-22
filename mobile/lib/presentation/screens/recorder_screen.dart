import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
              'Microphone permission is required to start recording.',
            ),
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
      try {
        await File(resolvedPath).delete();
      } catch (error) {
        AppLogger.warning(
          'Failed to delete temp recording: $error',
          tag: 'Recorder',
        );
      }
    }
  }

  Future<void> _uploadRecording(String filePath) async {
    final session = ref.read(sessionProvider);
    final token = session.token;
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in before uploading.'),
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
          const SnackBar(content: Text('Upload complete.')), 
        );
        context.go('/feed');
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to upload recording',
        tag: 'Recorder',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
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
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppTheme.heroGradient)),
          Positioned(
            left: -120,
            top: 60,
            child: Opacity(
              opacity: 0.22,
              child: Container(
                width: 240,
                height: 240,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.neonGradient,
                ),
              ),
            ),
          ),
          Positioned(
            right: -80,
            bottom: -40,
            child: Opacity(
              opacity: 0.16,
              child: Container(
                width: 200,
                height: 200,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppTheme.bgPopover, AppTheme.neonPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceLg,
                    vertical: AppTheme.spaceMd,
                  ),
                  child: _buildHeader(context),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.spaceXl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (_isRecording) ...[
                          _GlassPanel(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spaceLg,
                                vertical: AppTheme.spaceMd,
                              ),
                              child: _buildAudioLevel(),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceXl),
                        ],
                        _GlassPanel(
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spaceLg),
                            child: Column(
                              children: [
                                _buildTimer(),
                                const SizedBox(height: AppTheme.spaceXl),
                                _buildRecordButton(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceXl),
                        _GlassPanel(
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spaceLg),
                            child: _buildTitleField(),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceXl),
                        _GlassPanel(
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spaceLg),
                            child: _buildControlsCard(),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceXl),
                        if (_isUploading)
                          const CircularProgressIndicator(
                            color: AppTheme.brandPrimary,
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () => context.push('/live/host'),
                            icon: const Icon(Icons.radio),
                            label: const Text('Go live'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.brandPrimary,
                              side: const BorderSide(color: AppTheme.brandPrimary),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spaceLg,
                                vertical: AppTheme.spaceMd,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Row(
          children: [
            IconButton(
              onPressed: _isUploading ? null : () => context.pop(),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMd,
                vertical: AppTheme.spaceXs,
              ),
              decoration: BoxDecoration(
                gradient: _isPublic
                    ? AppTheme.neonGradient
                    : const LinearGradient(
                        colors: [AppTheme.surfaceChip, AppTheme.glassSurfaceDense],
                      ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.glassStroke),
                boxShadow: _isPublic
                    ? [
                        ...AppTheme.glowPrimary,
                        ...AppTheme.glowAccent,
                      ]
                    : null,
              ),
              child: Text(
                _isPublic ? 'PUBLIC' : 'ANON',
                style: TextStyle(
                  color: _isPublic ? AppTheme.textInverse : AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioLevel() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(14, (index) {
            final normalizedIndex = (index + 1) / 14;
            final isActive = normalizedIndex <= _audioLevel + 0.08;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 24 + (index * 4),
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(
                        colors: [AppTheme.neonBlue, AppTheme.neonPink],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      )
                    : null,
                color: isActive ? null : AppTheme.surfaceChip,
                borderRadius: BorderRadius.circular(6),
                boxShadow: isActive
                    ? [
                        ...AppTheme.glowPrimary,
                        BoxShadow(
                          color: AppTheme.neonPink.withValues(alpha: 0.2),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
            );
          }),
        ),
        const SizedBox(height: AppTheme.spaceSm),
        Text(
          _isRecording
              ? 'Recording in progress...'
              : 'Ready to record',
          style: TextStyle(
            color: _isRecording
                ? AppTheme.neonPink
                : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: _isRecording ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildTimer() {
    final minutes = (_duration ~/ 60).toString().padLeft(2, '0');
    final seconds = (_duration % 60).toString().padLeft(2, '0');
    return Column(
      children: [
        Text(
          '$minutes:$seconds',
          style: TextStyle(
            color: _isRecording
                ? AppTheme.neonPink
                : AppTheme.textPrimary,
            fontSize: 48,
            fontFeatures: const [FontFeature.tabularFigures()],
            shadows: _isRecording
                ? [
                    BoxShadow(
                      color: AppTheme.neonPink.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSm),
        Text(
          _isRecording ? 'Recording in progress' : 'Ready to record',
          style: TextStyle(
            color: _isRecording
                ? AppTheme.neonPink
                : AppTheme.textSecondary,
            fontWeight: _isRecording ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordButton() {
    final progress = (_duration / 60).clamp(0.0, 1.0);
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: _isRecording ? 1.08 : 1.0),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.glassSurface,
                border: Border.all(color: AppTheme.glassStroke),
              ),
              child: CircularProgressIndicator(
                value: _isRecording ? progress : 1,
                strokeWidth: 6,
                backgroundColor: AppTheme.surfaceBorder,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.neonBlue),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: _isRecording
                  ? const LinearGradient(
                      colors: [AppTheme.stateDanger, AppTheme.neonPink],
                    )
                  : AppTheme.neonGradient,
              shape: BoxShape.circle,
              boxShadow: _isRecording
                  ? [
                      ...AppTheme.glowPink,
                      BoxShadow(
                        color: AppTheme.neonPink.withValues(alpha: 0.4),
                        blurRadius: 30,
                        spreadRadius: -4,
                        offset: const Offset(0, 16),
                      ),
                    ]
                  : [
                      ...AppTheme.glowPrimary,
                      ...AppTheme.glowAccent,
                    ],
            ),
            child: IconButton(
              iconSize: 48,
              onPressed: _isUploading ? null : _toggleRecording,
              icon: Icon(
                _isRecording ? Icons.stop_rounded : Icons.mic,
                color: AppTheme.textInverse,
              ),
              padding: const EdgeInsets.all(28),
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
        labelText: 'Add a title',
        hintText: 'Summarize this drop (optional)',
        filled: true,
        fillColor: AppTheme.glassSurface,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        hintStyle: const TextStyle(color: AppTheme.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: const BorderSide(color: AppTheme.glassStroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: const BorderSide(color: AppTheme.glassStroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: const BorderSide(color: AppTheme.neonBlue),
        ),
      ),
    );
  }

  Widget _buildControlsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSwitch(
          label: 'Share publicly',
          value: _isPublic,
          onChanged: _isRecording || _isUploading
              ? null
              : (value) => setState(() => _isPublic = value ?? true),
        ),
        const SizedBox(height: AppTheme.spaceLg),
        _buildSegmentControl(
          label: 'Quality',
          values: const ['Raw', 'Clean'],
          current: _quality,
          onChanged: (value) => setState(() => _quality = value),
        ),
        const SizedBox(height: AppTheme.spaceLg),
        _buildSegmentControl(
          label: 'Voice mask',
          values: const ['Off', 'Basic', 'Studio'],
          current: _mask,
          onChanged: (value) => setState(() => _mask = value),
        ),
      ],
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
          activeColor: AppTheme.neonBlue,
          activeTrackColor: AppTheme.neonBlue.withValues(alpha: 0.3),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    side: const BorderSide(color: AppTheme.glassStroke),
                  ),
                  selectedColor: AppTheme.neonBlue.withValues(alpha: 0.2),
                  backgroundColor: AppTheme.glassSurfaceDense,
                  labelStyle: TextStyle(
                    color: current == value
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    fontWeight:
                        current == value ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppTheme.blurMd,
          sigmaY: AppTheme.blurMd,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.glassSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: AppTheme.glassStroke),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 28,
                offset: Offset(0, 18),
                spreadRadius: -8,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
