import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

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

class RecorderScreen extends StatefulWidget {
  const RecorderScreen({super.key});

  @override
  State<RecorderScreen> createState() => _RecorderScreenState();
}

class _RecorderScreenState extends State<RecorderScreen> {
  bool _isRecording = false;
  int _duration = 0;
  bool _isPublic = true;
  String _quality = 'Clean';
  String _mask = 'Off';
  double _audioLevel = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleRecording() {
    if (_isRecording) {
      _timer?.cancel();
      setState(() => _isRecording = false);
      final summary = RecordingSummary(
        duration: _duration,
        isPublic: _isPublic,
        quality: _quality,
        mask: _mask,
      );
      context.push('/publish', extra: summary);
    } else {
      setState(() {
        _isRecording = true;
        _duration = 0;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          _duration++;
          _audioLevel = (_audioLevel + 15) % 100;
        });
      });
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
                    _buildControlsCard(),
                    const SizedBox(height: AppTheme.spaceXl),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/live/host'),
                      icon: const Icon(Icons.radio),
                      label: const Text('Почати Live'),
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
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary),
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
            color: index * 10 < _audioLevel ? AppTheme.stateSuccess : AppTheme.surfaceChip,
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
            'Рекомендовано: 1 хвилина',
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
              backgroundColor: _isRecording ? AppTheme.stateDanger : AppTheme.brandPrimary,
              shape: const CircleBorder(),
              minimumSize: const Size(96, 96),
            ),
            onPressed: _toggleRecording,
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
            label: 'Публічно',
            value: _isPublic,
            onChanged: _isRecording
                ? null
                : (value) => setState(() => _isPublic = value ?? true),
          ),
          const SizedBox(height: AppTheme.spaceLg),
          _buildSegmentControl(
            label: 'Якість',
            values: const ['Raw', 'Clean'],
            current: _quality,
            onChanged: (value) => setState(() => _quality = value),
          ),
          const SizedBox(height: AppTheme.spaceLg),
          _buildSegmentControl(
            label: 'Маскування',
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
                  onSelected: _isRecording ? null : (selected) {
                    if (selected) onChanged(value);
                  },
                  selectedColor: AppTheme.brandPrimary,
                  backgroundColor: AppTheme.surfaceChip,
                  labelStyle: TextStyle(
                    color: current == value ? AppTheme.textInverse : AppTheme.textSecondary,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
