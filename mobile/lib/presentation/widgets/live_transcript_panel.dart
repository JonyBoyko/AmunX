import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../services/livekit_service.dart';

class LiveTranscriptPanel extends StatelessWidget {
  const LiveTranscriptPanel({
    super.key,
    required this.status,
    required this.segments,
    this.title = 'Live transcript',
    this.emptyLabel = 'Start speaking to see text appear here.',
    this.maxItems = 6,
  });

  final LivekitStatus status;
  final List<TranscriptSegment> segments;
  final String title;
  final String emptyLabel;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        color: AppTheme.bgRaised,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          if ((status == LivekitStatus.connected ||
                  status == LivekitStatus.reconnecting) &&
              segments.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: segments
                  .take(maxItems)
                  .map(
                    (segment) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TranscriptLine(segment: segment),
                    ),
                  )
                  .toList(),
            )
          else
            Text(
              emptyLabel,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
        ],
      ),
    );
  }
}

class TranscriptLine extends StatelessWidget {
  const TranscriptLine({super.key, required this.segment});

  final TranscriptSegment segment;

  @override
  Widget build(BuildContext context) {
    final meta = _languageLabel(segment);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          segment.speakerLabel,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          segment.text,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
        if (meta != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              meta,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

String? _languageLabel(TranscriptSegment segment) {
  final language = segment.language?.trim();
  if (language == null || language.isEmpty) {
    return null;
  }
  final code = language.toUpperCase();
  if (segment.isTranslation) {
    return 'Translated ($code)';
  }
  return code;
}
