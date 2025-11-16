import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Common
  String get ok => _getString('common.ok');
  String get cancel => _getString('common.cancel');
  String get retry => _getString('common.retry');
  String get close => _getString('common.close');
  String get save => _getString('common.save');
  String get delete => _getString('common.delete');
  String get loading => _getString('common.loading');
  String get error => _getString('common.error');
  String get success => _getString('common.success');

  // Feed
  String get feedTitle => _getString('feed.title');
  String get feedEmptyMessage => _getString('feed.empty.message');
  String get feedEmptyAction => _getString('feed.empty.action');
  String get feedErrorMessage => _getString('feed.error.message');
  String get feedLoading => _getString('feed.loading');

  // Recorder
  String get recorderTitle => _getString('recorder.title');
  String get recorderRecording => _getString('recorder.recording');
  String recorderMaxDuration(int current, int max) =>
      _getString('recorder.maxDuration')
          .replaceAll('{{current}}', current.toString())
          .replaceAll('{{max}}', max.toString());
  String get recorderPublic => _getString('recorder.public');
  String get recorderAnonymous => _getString('recorder.anonymous');
  String get recorderUploading => _getString('recorder.uploading');
  String get recorderUploadSuccess => _getString('recorder.uploadSuccess');
  String get recorderUploadError => _getString('recorder.uploadError');

  String _getString(String key) {
    final translations = _getTranslations();
    final keys = key.split('.');
    dynamic value = translations;

    for (final k in keys) {
      if (value is Map && value.containsKey(k)) {
        value = value[k];
      } else {
        return key; // Return key if translation not found
      }
    }

    return value.toString();
  }

  Map<String, dynamic> _getTranslations() {
    if (locale.languageCode == 'uk') {
      return _ukTranslations;
    }
    return _enTranslations;
  }

  static const Map<String, dynamic> _enTranslations = {
    'common': {
      'ok': 'OK',
      'cancel': 'Cancel',
      'retry': 'Retry',
      'close': 'Close',
      'save': 'Save',
      'delete': 'Delete',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
    },
    'feed': {
      'title': 'Feed',
      'empty': {
        'message': 'No episodes yet. Be the first to record a 1-minute voice note!',
        'action': 'Record 1-min episode',
      },
      'error': {
        'message': 'Something went wrong. Please try again.',
      },
      'loading': 'Loading feed...',
    },
    'recorder': {
      'title': 'Record',
      'recording': 'Recording',
      'maxDuration': '{{current}}s / {{max}}s',
      'public': 'Public',
      'anonymous': 'Anonymous',
      'uploading': 'Uploading...',
      'uploadSuccess': 'Episode uploaded successfully!',
      'uploadError': 'Failed to upload episode',
    },
  };

  static const Map<String, dynamic> _ukTranslations = {
    'common': {
      'ok': 'OK',
      'cancel': 'Скасувати',
      'retry': 'Повторити',
      'close': 'Закрити',
      'save': 'Зберегти',
      'delete': 'Видалити',
      'loading': 'Завантаження...',
      'error': 'Помилка',
      'success': 'Успіх',
    },
    'feed': {
      'title': 'Стрічка',
      'empty': {
        'message': 'Ще немає епізодів. Будьте першим, хто запише 1-хвилинну голосову нотатку!',
        'action': 'Записати 1-хв епізод',
      },
      'error': {
        'message': 'Щось пішло не так. Будь ласка, спробуйте ще раз.',
      },
      'loading': 'Завантаження стрічки...',
    },
    'recorder': {
      'title': 'Запис',
      'recording': 'Запис',
      'maxDuration': '{{current}}с / {{max}}с',
      'public': 'Публічно',
      'anonymous': 'Анонімно',
      'uploading': 'Завантаження...',
      'uploadSuccess': 'Епізод успішно завантажено!',
      'uploadError': 'Не вдалося завантажити епізод',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'uk'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

