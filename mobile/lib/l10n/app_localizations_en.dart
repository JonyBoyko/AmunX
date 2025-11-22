// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonRetry => 'Retry';

  @override
  String get smartInboxTitle => 'Smart Inbox';

  @override
  String get smartInboxOpenInbox => 'Open inbox';

  @override
  String get smartInboxOpenLatestEpisode => 'Open latest episode';

  @override
  String get smartInboxOpenEpisode => 'Open episode';

  @override
  String get smartInboxTrendingTitle => 'Trending today';

  @override
  String get smartInboxTrendingEmpty =>
      'No standout topics yet. Check back after a few new episodes.';

  @override
  String smartInboxUpdated(String date) {
    return 'Updated $date';
  }

  @override
  String get smartInboxNewLabel => 'NEW';

  @override
  String get smartInboxErrorTitle => 'Smart Inbox unavailable';

  @override
  String get smartInboxErrorDescription =>
      'We couldn\'t load Smart Inbox insights. Pull to refresh or retry.';

  @override
  String get smartInboxRetryCta => 'Retry Smart Inbox';

  @override
  String smartInboxLoadFailed(String error) {
    return 'Smart Inbox failed to load: $error';
  }
}
