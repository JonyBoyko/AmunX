import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moweton_flutter/presentation/services/transcript_parser.dart';

void main() {
  test('parseTranscriptPayload decodes UTF-8', () {
    final payload = utf8.encode('hello');
    expect(parseTranscriptPayload(payload), 'hello');
  });

  test('normalizeTranscriptText handles JSON payload', () {
    final payload = '{"type":"transcript","text":"Hello there"}';
    expect(normalizeTranscriptText(payload), 'Hello there');
  });

  test('normalizeTranscriptText falls back to plain text', () {
    expect(normalizeTranscriptText('plain text'), 'plain text');
  });

  test('decodeTranscriptMessage prefers translated text and metadata', () {
    final payload = utf8.encode(
      jsonEncode({
        'type': 'transcript',
        'speaker': 'host',
        'lang': 'en',
        'timestamp': 1700000000,
        'translation': {'text': 'Привіт усім', 'lang': 'uk'},
      }),
    );

    final message = decodeTranscriptMessage(payload);
    expect(message, isNotNull);
    expect(message!.text, 'Привіт усім');
    expect(message.speaker, 'host');
    expect(message.sourceLanguage, 'en');
    expect(message.targetLanguage, 'uk');
    expect(message.isTranslation, isTrue);
  });

  test('decodeTranscriptMessage filters partial payloads', () {
    final payload = utf8.encode(
      jsonEncode({'type': 'partial', 'text': 'typing...', 'is_final': false}),
    );
    expect(decodeTranscriptMessage(payload), isNull);
  });

  test('decodeTranscriptMessage falls back to raw string', () {
    final payload = utf8.encode('plain words');
    final message = decodeTranscriptMessage(payload);
    expect(message, isNotNull);
    expect(message!.text, 'plain words');
  });
}
