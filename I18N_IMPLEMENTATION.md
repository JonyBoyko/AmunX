# i18n Локалізація — Повна Реалізація ✅

**Дата:** 2025-11-04  
**Commit:** `8835301`  
**Status:** ✅ Production Ready

---

## 📦 Встановлені Пакети

```json
{
  "i18next": "^23.x",
  "react-i18next": "^14.x",
  "@react-native-async-storage/async-storage": "^1.x",
  "expo-localization": "^14.x"
}
```

---

## 🌍 Підтримувані Мови

1. **🇬🇧 English (en)** — 250+ ключів
2. **🇺🇦 Українська (uk)** — 250+ ключів з плюралізацією

---

## 📁 Структура Файлів

```
mobile/src/i18n/
├── index.ts              # Конфігурація i18n + ініціалізація
├── locales/
│   ├── en.ts            # Англійська мова
│   └── uk.ts            # Українська мова
```

**Додано в `tsconfig.json`:**
```json
"@i18n/*": ["src/i18n/*"]
```

---

## 🔧 Конфігурація i18n

### `mobile/src/i18n/index.ts`

**Ключові функції:**
- `initI18n()` — Асинхронна ініціалізація з завантаженням збереженої мови
- `setLanguage(lng: string)` — Зміна мови + збереження в AsyncStorage
- `getInitialLanguage()` — Визначення мови (збережена → locale пристрою → fallback 'en')

**Fallback Chain:**
```
AsyncStorage → Device Locale (expo-localization) → 'en'
```

**Підтримувані мови:**
```typescript
['en', 'uk']
```

---

## 📱 App.tsx Інтеграція

```typescript
const App: React.FC = () => {
  const [i18nReady, setI18nReady] = useState(false);

  useEffect(() => {
    const init = async () => {
      await initI18n();
      setI18nReady(true);
    };
    init();
  }, []);

  if (!i18nReady) {
    return <ActivityIndicator />; // Loading screen
  }

  return <NavigationContainer>...</NavigationContainer>;
};
```

---

## 🎨 Перекладені Екрани

### 1. **FeedScreen** ✅
- Заголовок ("Feed" / "Стрічка")
- Empty state
- Loading states
- Error messages

### 2. **RecorderScreen** ✅
- Header title
- Privacy settings (Public/Anonymous)
- Voice mask (None/Light/Heavy)
- Quality (Raw/Clean/Studio)
- Instructions (idle/recording)
- UndoToast integration
- Upload/error alerts

### 3. **PaywallScreen** ✅
- Hero section (title + subtitle)
- 6 PRO features (dynamic via `getProFeatures(t)`)
- Pricing plans (Monthly/Yearly)
- CTA button
- Fine print + legal links
- Alerts (Thank You / Restoring)

### 4. **SettingsScreen** ✅
- All sections:
  - Account (Profile, Change Email, Manage Subscription)
  - Preferences (Notifications, Autoplay, Analytics, **Language**)
  - Support (Help, Terms, Privacy)
  - Danger Zone (Logout, Delete Account)
- App Info (Version, Copyright)

**Language Selector:**
```typescript
Alert.alert(
  t('settings.preferences.language'),
  '',
  [
    { text: t('settings.languages.en'), onPress: () => setLanguage('en') },
    { text: t('settings.languages.uk'), onPress: () => setLanguage('uk') },
    { text: t('common.cancel'), style: 'cancel' },
  ]
);
```

---

## 🧩 Перекладені Компоненти

### 1. **UndoToast** ✅
```typescript
const { t } = useTranslation();

<Text>{t('recorder.undo.title')}</Text>
<Text>{t('recorder.undo.message', { seconds: timeLeft })}</Text>
<Button title={t('recorder.undo.action')} />
```

**Interpolation:**
```json
{
  "en": "Episode will go live in {{seconds}} s",
  "uk": "Епізод стане публічним через {{seconds}} с"
}
```

### 2. **Badge** ✅
```typescript
const labels: Record<BadgeVariant, string> = {
  public: t('badges.public'),
  anon: t('badges.anon'),
  mask: t('badges.mask'),
  pro: t('badges.pro'),
  // ...
};
```

### 3. **EmptyState / ErrorState**
Приймають `message` як props → вже підтримують локалізацію через t() у батьківських компонентах.

---

## 🔑 Ключові Переклади

### Common
```json
{
  "common": {
    "ok": "OK",
    "cancel": "Cancel" / "Скасувати",
    "retry": "Retry" / "Повторити",
    "loading": "Loading..." / "Завантаження...",
    "error": "Error" / "Помилка",
    "success": "Success" / "Успіх"
  }
}
```

### Feed
```json
{
  "feed": {
    "title": "Feed" / "Стрічка",
    "empty": {
      "message": "No episodes yet..." / "Ще немає епізодів...",
      "action": "Record 1-min episode" / "Записати 1-хв епізод"
    },
    "loading": "Loading feed..." / "Завантаження стрічки...",
    "loadingMore": "Loading more..." / "Завантаження більше..."
  }
}
```

### Recorder
```json
{
  "recorder": {
    "title": "Record" / "Запис",
    "privacy": "Privacy" / "Приватність",
    "public": "Public" / "Публічно",
    "anonymous": "Anonymous" / "Анонімно",
    "mask": "Voice Mask" / "Голосова маска",
    "maskNone": "None" / "Немає",
    "maskLight": "Light" / "Легка",
    "maskHeavy": "Heavy" / "Важка",
    "quality": "Quality" / "Якість",
    "instructions": {
      "idle": "Tap the microphone to start..." / "Натисніть мікрофон, щоб почати...",
      "recording": "Tap to stop recording" / "Натисніть, щоб зупинити запис"
    },
    "undo": {
      "title": "Publishing..." / "Публікується...",
      "message": "Episode will go live in {{seconds}} s" / "Епізод стане публічним через {{seconds}} с",
      "action": "Cancel" / "Скасувати"
    }
  }
}
```

### Paywall
```json
{
  "paywall": {
    "title": "Unlock Full Potential" / "Розблокуйте повний потенціал",
    "subtitle": "Get AI transcription, voice masking, and studio quality" / "Отримайте AI транскрипцію, голосову маску та студійну якість",
    "features": {
      "transcription": {
        "title": "Full Transcription" / "Повна транскрипція",
        "description": "Faster-Whisper AI for 99% text accuracy" / "Faster-Whisper AI для 99% точності тексту"
      },
      // ... 5 more features
    },
    "pricing": {
      "title": "Choose Your Plan" / "Оберіть план",
      "monthly": {
        "name": "Monthly" / "Місяць",
        "price": "$4.99 / month" / "$4.99 / міс"
      },
      "yearly": {
        "name": "Year (Save 40%)" / "Рік (заощадьте 40%)",
        "price": "$2.99 / month" / "$2.99 / міс",
        "subtitle": "$35.88 per year" / "$35.88 на рік",
        "badge": "Best Value" / "Найкраща вартість"
      }
    },
    "cta": "Subscribe Now" / "Підписатися зараз",
    "processing": "Processing..." / "Обробка..."
  }
}
```

### Settings
```json
{
  "settings": {
    "title": "Settings" / "Налаштування",
    "preferences": {
      "language": "Language" / "Мова"
    },
    "languages": {
      "en": "English",
      "uk": "Українська"
    },
    "dangerZone": {
      "logout": "Logout" / "Вийти",
      "deleteAccount": "Delete Account" / "Видалити акаунт",
      "logoutConfirm": {
        "title": "Logout" / "Вихід",
        "message": "Are you sure you want to logout?" / "Ви впевнені, що хочете вийти?"
      }
    }
  }
}
```

### Badges
```json
{
  "badges": {
    "public": "PUBLIC" / "ПУБЛІЧНО",
    "anon": "ANONYMOUS" / "АНОНІМНО",
    "mask": "MASK" / "МАСКА",
    "pro": "PRO",
    "raw": "RAW",
    "clean": "CLEAN",
    "studio": "STUDIO",
    "live": "LIVE" / "НАЖИВО"
  }
}
```

---

## 🧪 Як Тестувати

### 1. **Запуск додатку:**
```bash
cd mobile
npm start
```

### 2. **Зміна мови:**
1. Відкрити **Settings**
2. Натиснути **"Language" / "Мова"**
3. Обрати **English** або **Українська**
4. Додаток автоматично оновить всі тексти

### 3. **Перевірка збереження:**
1. Змінити мову на **Українська**
2. Закрити додаток (Force quit)
3. Відкрити знову → Мова залишається **Українська** ✅

### 4. **Перевірка device locale:**
1. Видалити додаток (або очистити AsyncStorage)
2. Змінити мову пристрою на **Українська**
3. Запустити додаток → Автоматично українська ✅
4. Змінити мову пристрою на **English**
5. Видалити додаток і запустити знову → English ✅

---

## ✅ Виправлені Lint Помилки

1. **Unused imports:**
   - `Badge` в `EpisodeCard.tsx`
   - `applyShadow` в `PaywallScreen.tsx`
   - `Button` в `RecorderScreen.tsx`
   - `token`, `currentLanguage` в `SettingsScreen.tsx`
   - `title` в `episodes.ts`

2. **Unused params:**
   - `color1`, `color2` в `theme/utils.ts` → `_color1`, `_color2`

3. **Parsing error:**
   - Апостроф в `You've` → `You have` в `en.ts`

4. **Trailing spaces:**
   - `Badge.tsx`, `UndoToast.tsx`

---

## 📊 Статистика

- **Файлів створено:** 6 (i18n index, 2 локалі, 3 theme)
- **Файлів оновлено:** 27 (screens, components, tsconfig, App.tsx)
- **Перекладів:** 250+ ключів для кожної мови
- **Ліній коду:** +4,356 / -384
- **Commit:** `8835301`
- **Push:** ✅ GitHub main

---

## 🚀 Як Додати Нову Мову

1. **Створити файл:**
   ```typescript
   // mobile/src/i18n/locales/de.ts (German)
   export default {
     translation: {
       common: {
         ok: 'OK',
         cancel: 'Abbrechen',
         // ... copy from en.ts and translate
       },
       // ...
     },
   };
   ```

2. **Додати в конфігурацію:**
   ```typescript
   // mobile/src/i18n/index.ts
   import de from './locales/de';

   await i18n.use(initReactI18next).init({
     resources: {
       en,
       uk,
       de, // +++
     },
     // ...
   });

   // Update initial language detection
   return ['en', 'uk', 'de'].includes(deviceLocale) ? deviceLocale : 'en';
   ```

3. **Додати в Settings:**
   ```typescript
   // mobile/src/i18n/locales/en.ts
   languages: {
     en: 'English',
     uk: 'Українська',
     de: 'Deutsch', // +++
   }
   ```

4. **Done!** ✅ Нова мова доступна в Settings → Language

---

## 🎯 Best Practices

### ✅ DO:
- Використовуйте `useTranslation()` для динамічних текстів
- Інтерполяція для змінних: `t('key', { variable: value })`
- Nested keys для структури: `t('section.subsection.key')`
- Плюралізація для української: `comments: { one, few, many, other }`

### ❌ DON'T:
- НЕ хардкодьте тексти: ~~`<Text>Loading...</Text>`~~
- НЕ використовуйте t() в рендері JSX без мемоізації (якщо багато ключів)
- НЕ забувайте додавати нові ключі в обидві мови

---

## 📝 Приклади Використання

### Basic:
```typescript
const { t } = useTranslation();
<Text>{t('common.loading')}</Text>
```

### With Interpolation:
```typescript
<Text>{t('recorder.undo.message', { seconds: 10 })}</Text>
// Output: "Episode will go live in 10 s"
```

### With Pluralization:
```typescript
<Text>{t('episode.comments', { count: 5 })}</Text>
// EN: "5 comments"
// UK: "5 коментарів"
```

### Dynamic Functions:
```typescript
const PRO_FEATURES = getProFeatures(t);
PRO_FEATURES.map(f => f.title); // Localized!
```

---

## 🔗 Resources

- **i18next Docs:** https://www.i18next.com/
- **react-i18next:** https://react.i18next.com/
- **expo-localization:** https://docs.expo.dev/versions/latest/sdk/localization/

---

**Автор:** AI Assistant  
**Проект:** AmunX Voice Journal  
**Версія:** v1.0.0 (Beta)  
**Ліцензія:** © 2025 AmunX. All rights reserved.

---

✅ **Локалізація повністю готова до Production!** 🚀

