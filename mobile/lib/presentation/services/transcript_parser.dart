import 'dart:convert';

String parseTranscriptPayload(List<int> data) {
  try {
    final decoded = utf8.decode(data);
    return decoded.trim();
  } catch (_) {
    return '';
  }
}

String normalizeTranscriptText(String payload) {
  final trimmed = payload.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  try {
    final parsed = jsonDecode(trimmed);
    if (parsed is Map<String, dynamic>) {
      final type = parsed['type'] as String?;
      final text = parsed['text'] as String?;
      if (type == null || type == 'transcript') {
        return text?.trim() ?? '';
      }
    }
  } catch (_) {
    // fall through
  }
  return trimmed;
}

TranscriptMessage? decodeTranscriptMessage(List<int> data) {
  final payload = parseTranscriptPayload(data);
  if (payload.isEmpty) {
    return null;
  }
  final message = _tryDecodeJson(payload);
  if (message != null) {
    if (!message.isFinal || message.text.isEmpty) {
      return null;
    }
    return message;
  }
  final fallback = normalizeTranscriptText(payload);
  if (fallback.isEmpty) {
    return null;
  }
  return TranscriptMessage(text: fallback, timestamp: DateTime.now());
}

TranscriptMessage? _tryDecodeJson(String payload) {
  try {
    final decoded = jsonDecode(payload);
    if (decoded is Map<String, dynamic>) {
      return _mapToMessage(decoded);
    }
  } catch (_) {
    // swallow parse errors and fall back to plain text
  }
  return null;
}

TranscriptMessage? _mapToMessage(Map<String, dynamic> json) {
  final body = _extractBody(json);
  final type = (json['type'] ?? body['type'])?.toString().toLowerCase();
  final isFinal =
      _coerceBool(body['is_final']) ??
          _coerceBool(json['is_final']) ??
          _coerceBool(body['final']) ??
          _coerceBool(json['final']) ??
          (type == null || type != 'partial');

  final rawText = _firstNonEmpty(body, const ['text', 'message', 'caption', 'body']) ??
      _firstNonEmpty(json, const ['text', 'message']);
  final translation = _extractTranslation(body);
  final translationText = translation?.text ??
      _firstNonEmpty(body, const ['translated_text', 'translation_text']);
  final translationLang =
      translation?.language ?? _firstNonEmpty(body, const ['translated_lang', 'target_lang']);

  final primaryText = rawText?.trim() ?? '';
  final preferredText = (translationText != null && translationText.trim().isNotEmpty)
      ? translationText.trim()
      : primaryText;
  if (preferredText.isEmpty) {
    return null;
  }

  final timestamp = _parseTimestamp(
        body['timestamp'] ?? body['ts'] ?? json['timestamp'],
      ) ??
      (translation?.timestamp ?? _parseTimestamp(json['ts']));

  return TranscriptMessage(
    text: preferredText,
    speaker: _firstNonEmpty(body, const ['speaker', 'speaker_label', 'user']),
    sourceLanguage: _firstNonEmpty(body, const ['lang', 'language', 'source_lang']),
    targetLanguage: translationLang,
    timestamp: timestamp,
    isFinal: isFinal,
    isTranslation: translationText != null && translationText.trim().isNotEmpty,
  );
}

Map<String, dynamic> _extractBody(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is Map<String, dynamic>) {
    return data;
  }
  final payload = json['payload'];
  if (payload is Map<String, dynamic>) {
    return payload;
  }
  return json;
}

class TranscriptMessage {
  const TranscriptMessage({
    required this.text,
    this.speaker,
    this.sourceLanguage,
    this.targetLanguage,
    this.timestamp,
    this.isFinal = true,
    this.isTranslation = false,
  });

  final String text;
  final String? speaker;
  final String? sourceLanguage;
  final String? targetLanguage;
  final DateTime? timestamp;
  final bool isFinal;
  final bool isTranslation;

  String? get displayLanguage => targetLanguage ?? sourceLanguage;
}

class _TranslationFields {
  const _TranslationFields({
    required this.text,
    this.language,
    this.timestamp,
  });

  final String text;
  final String? language;
  final DateTime? timestamp;
}

_TranslationFields? _extractTranslation(Map<String, dynamic> json) {
  final translation = json['translation'];
  if (translation is Map<String, dynamic>) {
    final text = _firstNonEmpty(translation, const ['text', 'message', 'caption']);
    if (text == null || text.trim().isEmpty) {
      return null;
    }
    return _TranslationFields(
      text: text.trim(),
      language: _firstNonEmpty(translation, const ['lang', 'language', 'target_lang']),
      timestamp: _parseTimestamp(
        translation['timestamp'] ?? translation['ts'],
      ),
    );
  }
  final translated = json['translated'];
  if (translated is Map<String, dynamic>) {
    final text = _firstNonEmpty(translated, const ['text', 'message']);
    if (text == null || text.trim().isEmpty) {
      return null;
    }
    return _TranslationFields(
      text: text.trim(),
      language: _firstNonEmpty(translated, const ['lang', 'language', 'target_lang']),
      timestamp: _parseTimestamp(translated['timestamp']),
    );
  }
  return null;
}

String? _firstNonEmpty(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) {
      return text;
    }
  }
  return null;
}

bool? _coerceBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase();
    if (lower == 'true' || lower == 'yes' || lower == 'final') return true;
    if (lower == 'false' || lower == 'no' || lower == 'partial') return false;
  }
  return null;
}

DateTime? _parseTimestamp(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is num) {
    if (value.isNaN) return null;
    final millis = value > 1000000000000 ? value.toInt() : (value * 1000).round();
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final numeric = num.tryParse(trimmed);
    if (numeric != null) {
      return _parseTimestamp(numeric);
    }
    return DateTime.tryParse(trimmed);
  }
  return null;
}
