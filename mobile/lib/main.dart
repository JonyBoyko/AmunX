import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/logging/app_logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error(
      'Flutter error: ${details.exception}',
      tag: 'FlutterError',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  runApp(
    const ProviderScope(
      child: MowetonApp(),
    ),
  );
}

