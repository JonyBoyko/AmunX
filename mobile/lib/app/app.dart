import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'router.dart';
import 'theme.dart';
import '../core/i18n/app_localizations.dart';
import '../core/logging/app_logger.dart';

class MowetonApp extends ConsumerWidget {
  const MowetonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppLogger.info('Building MowetonApp', tag: 'App');
    
    final router = ref.watch(routerProvider);
    AppLogger.info('Router initialized', tag: 'App');

    return MaterialApp.router(
      title: 'Moweton',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('uk', ''),
      ],
    );
  }
}

