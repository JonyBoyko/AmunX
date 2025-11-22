// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get commonRetry => 'Повторити';

  @override
  String get smartInboxTitle => 'Smart Inbox';

  @override
  String get smartInboxOpenInbox => 'Відкрити інбокс';

  @override
  String get smartInboxOpenLatestEpisode => 'Відкрити останній епізод';

  @override
  String get smartInboxOpenEpisode => 'Відкрити епізод';

  @override
  String get smartInboxTrendingTitle => 'Тренди сьогодні';

  @override
  String get smartInboxTrendingEmpty =>
      'Поки немає яскравих тем. Поверніться після появи нових епізодів.';

  @override
  String smartInboxUpdated(String date) {
    return 'Оновлено $date';
  }

  @override
  String get smartInboxNewLabel => 'НОВЕ';

  @override
  String get smartInboxErrorTitle => 'Smart Inbox тимчасово недоступний';

  @override
  String get smartInboxErrorDescription =>
      'Не вдалося завантажити інсайти Smart Inbox. Потягніть, щоб оновити, або повторіть спробу.';

  @override
  String get smartInboxRetryCta => 'Повторити Smart Inbox';

  @override
  String smartInboxLoadFailed(String error) {
    return 'Smart Inbox не завантажився: $error';
  }
}
