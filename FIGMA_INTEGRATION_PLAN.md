# 🎨 Figma UI Integration Plan

**Дата:** 2025-11-04  
**Джерело:** `C:\Main\cursor_bundle\`

---

## 📦 Що є в bundle

### Design System
- ✅ **Theme tokens** (`app/theme/tokens.ts`)
  - Colors (dark theme)
  - Radius, Space, Typography
  - Effects (shadows)
- ✅ **Theme utils** (`app/theme/theme.ts`, `utils.ts`)

### Atomic Components (`app/components/atoms/`)
- ✅ `Button.tsx` — primary/secondary/tonal variants
- ✅ `Badge.tsx` — status badges (public/anon/mask/pro/etc)
- ✅ `Chip.tsx` — keyword chips

### Molecular Components (`app/components/molecules/`)
- ✅ `EpisodeCard.tsx` — improved card з badges
- ✅ `MiniPlayer.tsx` — sticky player
- ✅ `UndoToast.tsx` — 10s undo banner з progress bar

### Screens (`app/screens/`)
- ✅ `Onboarding.tsx` — auth/welcome
- ✅ `Recorder.tsx` — з Undo Toast
- ✅ `Feed.tsx` — з MiniPlayer
- ✅ `EpisodeDetail.tsx` — Free vs Pro stub
- ✅ `LiveHost.tsx` — host controls
- ✅ `LiveListener.tsx` — listener UI
- ✅ `TranslateControl.tsx` — Pro translate UI
- ✅ `Paywall.tsx` — monetization
- ✅ `Settings.tsx` — user settings

### State Management (`app/store/`)
- ✅ `usePlayerStore.ts` — Zustand player store
- ✅ `useRecorderStore.ts` — Zustand recorder store

### Navigation
- ✅ `app/navigation/index.tsx` — Stack navigator

---

## 🎯 План інтеграції (Phase 1.4)

### Priority 1.4: Figma Design Integration (3-4 дні)

#### Step 1: Theme Migration (1-2 години)
**Мета:** Замінити поточні стилі на design tokens

**Tasks:**
```typescript
// 1. Copy theme files
mobile/src/theme/
  ├── tokens.ts      // From cursor_bundle
  ├── theme.ts
  └── utils.ts

// 2. Update existing components to use theme
// Наприклад, FeedScreen.tsx:
- backgroundColor: '#0f172a'
+ backgroundColor: theme.colors.bg.base

- backgroundColor: '#1e293b'
+ backgroundColor: theme.colors.surface.card
```

**Impact:** Консистентний дизайн, легше підтримувати

---

#### Step 2: Atomic Components (2-3 години)
**Мета:** Додати дизайн-системні компоненти

**Tasks:**
```typescript
// Copy & adapt:
mobile/src/components/atoms/
  ├── Button.tsx       // 3 variants (primary/secondary/tonal)
  ├── Badge.tsx        // Status badges
  ├── Chip.tsx         // Keywords

// Update existing usage:
// Old:
<Button title="Record" />

// New:
<Button title="Record" kind="primary" />
<Badge variant="public" />
<Chip label="voice" />
```

---

#### Step 3: Update EpisodeCard (1 година)
**Мета:** Використати професійний дизайн картки

**Compare:**
```typescript
// Current: mobile/src/components/EpisodeCard.tsx
// - Custom badges inline
// - Manual styling

// Figma: cursor_bundle/app/components/molecules/EpisodeCard.tsx
// - Uses Badge atoms
// - Consistent spacing
// - Progress bar
```

**Action:** Merge найкращі частини обох версій

---

#### Step 4: Integrate UndoToast (2 години)
**Мета:** Додати справжній 10s Undo з progress bar

**Tasks:**
```typescript
// 1. Copy UndoToast component
mobile/src/components/molecules/UndoToast.tsx

// 2. Update RecorderScreen (коли створимо):
import { UndoToast } from '@components/molecules/UndoToast';

const [showUndo, setShowUndo] = useState(false);
const [episodeId, setEpisodeId] = useState<string | null>(null);

// After stop recording:
setShowUndo(true);
setEpisodeId(newEpisodeId);

// In render:
{showUndo && (
  <UndoToast 
    seconds={10}
    onUndo={async () => {
      await undoEpisode(token, episodeId);
      setShowUndo(false);
    }}
  />
)}
```

---

#### Step 5: Update MiniPlayer (1 година)
**Мета:** Використати покращений дизайн з Figma

**Compare:**
```typescript
// Current: mobile/src/components/MiniPlayer.tsx
// - Basic expo-av integration
// - Custom styles

// Figma: cursor_bundle/app/components/molecules/MiniPlayer.tsx
// - Cleaner UI
// - Better animations
// - Zustand store integration
```

**Action:** Merge audio logic з Figma styling

---

#### Step 6: Apply to All Screens (3-4 години)
**Мета:** Консистентний UI всюди

**Screens to update:**
1. ✅ FeedScreen — apply theme
2. 🔄 RecorderScreen (нова реалізація)
3. 🔄 EpisodeScreen — використати Figma layout
4. 🔄 LiveHostScreen — підтягнути стилі
5. 🔄 LiveListenerScreen — підтягнути стилі
6. 🔄 Paywall (новий екран)
7. 🔄 Settings (новий екран)

---

## 📋 Detailed Task Breakdown

### Task 1.4.1: Theme Setup (30 хв)
```bash
# 1. Copy files
cp -r C:/Main/cursor_bundle/app/theme mobile/src/

# 2. Update tsconfig paths
"@theme/*": ["src/theme/*"]

# 3. Create ThemeProvider (optional)
```

---

### Task 1.4.2: Atomic Components (1-2 години)
```typescript
// File: mobile/src/components/atoms/Button.tsx
// Промпт: "Copy Button.tsx from cursor_bundle, adapt for our project:
// - Add accessibility props
// - Add loading state
// - Add icon support
// - Keep 3 variants (primary/secondary/tonal)"

// File: mobile/src/components/atoms/Badge.tsx
// Промпт: "Copy Badge.tsx from cursor_bundle, add variants:
// public, anon, raw, clean, studio, mask, pro, live"

// File: mobile/src/components/atoms/Chip.tsx
// Промпт: "Copy Chip.tsx from cursor_bundle, add onPress support"
```

---

### Task 1.4.3: UndoToast Integration (2 години)
```typescript
// Промпт: "Integrate UndoToast.tsx from Figma bundle:
// 1. Copy component with countdown timer
// 2. Add to RecorderScreen (створити новий екран)
// 3. Connect to undoEpisode API
// 4. Show after POST /v1/episodes/{id}/finalize
// 5. Hide after 10s or on 'Скасувати' tap
// 6. Navigate to Feed on publish or stay on Recorder on undo"
```

---

### Task 1.4.4: EpisodeCard Redesign (1 година)
```typescript
// Промпт: "Update EpisodeCard.tsx using Figma design:
// - Use Badge atoms instead of inline styles
// - Add author name/avatar (or 'Анонім')
// - Better badge layout (top-right row)
// - Cleaner typography (theme.type)
// - Keep our features: reactions, comments pill, onPress"
```

---

### Task 1.4.5: RecorderScreen (2-3 години)
```typescript
// Промпт: "Create RecorderScreen.tsx based on Figma:
// - Big round FAB (84x84) for REC/STOP
// - Badges at top (Public/Anon toggle)
// - Toggles: Raw/Clean, Mask (Basic/Studio)
// - Timer display (1:00 max)
// - After STOP → show UndoToast 10s
// - Upload logic (existing API)
// - Navigate to Feed after publish"
```

---

### Task 1.4.6: Paywall Screen (1-2 години)
```typescript
// Промпт: "Copy Paywall.tsx from Figma bundle:
// - Hero section: 'Unlock Pro Features'
// - Feature list:
//   ✨ Real-time captions & dubbing
//   📝 Full transcripts & search
//   🎧 Studio voice mask
//   ⏱️ Longer lives (up to 60min)
// - Pricing cards (Monthly/Yearly)
// - CTA buttons: 'Start Free Trial', 'Subscribe'
// - 'Restore Purchases' link
// - Connect to RevenueCat (later phase)"
```

---

### Task 1.4.7: Settings Screen (1 година)
```typescript
// Промпт: "Copy Settings.tsx from Figma bundle:
// - Profile section (avatar, name, 'Anonymous' toggle)
// - Toggles:
//   - Public by default
//   - Default Mask (None/Basic/Studio)
//   - Default Quality (Raw/Clean)
// - Notifications settings (navigate to separate screen)
// - About, Sign out
// - Connect to PATCH /v1/me API"
```

---

## 🎨 Color Comparison

### Current vs Figma

| Element | Current | Figma | Action |
|---------|---------|-------|--------|
| **Background** | `#0f172a` | `#0B0D10` | ✅ Use Figma (slightly darker) |
| **Card** | `#1e293b` | `#111318` | ✅ Use Figma |
| **Text Primary** | `#f8fafc` | `#E9EDF2` | ✅ Use Figma |
| **Text Secondary** | `#94a3b8` | `#9AA4AF` | ✅ Use Figma |
| **Brand Primary** | `#38bdf8` | `#6AA6FF` | ✅ Use Figma (better contrast) |
| **Success** | `#22c55e` | `#21D19F` | ✅ Use Figma |

**Conclusion:** Figma theme має кращий контраст і професійніший вигляд

---

## 📊 Integration Timeline

| Task | Time | Priority |
|------|------|----------|
| **1.4.1** Theme Setup | 30 хв | 🔥 High |
| **1.4.2** Atomic Components | 2 год | 🔥 High |
| **1.4.3** UndoToast | 2 год | 🔥 High |
| **1.4.4** EpisodeCard Redesign | 1 год | 🔥 High |
| **1.4.5** RecorderScreen | 3 год | 🔥 High |
| **1.4.6** Paywall Screen | 2 год | 🟡 Medium |
| **1.4.7** Settings Screen | 1 год | 🟡 Medium |
| **1.4.8** Apply theme to all screens | 3 год | 🟡 Medium |

**Total:** ~14-16 годин (2 дні активної роботи)

---

## ✅ Benefits

1. **Professional UI** — дизайн з Figma, а не "на око"
2. **Consistency** — всі екрани використовують одні токени
3. **Maintainability** — легко змінити theme глобально
4. **Accessibility** — кращий контраст, розміри кнопок
5. **Speed** — готові компоненти, не треба винаходити

---

## 🚀 Next Steps

**Варіант A:** Почати зараз з Theme Setup (Task 1.4.1)  
**Варіант B:** Спочатку завершити базові екрани (Recorder, Episode, Comments), потім інтегрувати Figma  
**Варіант C:** Поступово — міксувати Figma компоненти під час створення нових екранів

**Рекомендація:** Варіант A → швидко отримаємо професійний вигляд

Що обираємо? 🎨

