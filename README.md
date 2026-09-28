# Tether

> **Build habits that stick.**

Tether is a calm, offline-first personal habit, consistency, and focus application built around the principle of habit stacking:
*"After I [trigger], I will [action]."*

Tether helps you build sustainable daily routines by anchoring new micro-actions to existing habitual behaviors. It deliberately eschews gamification, social comparison, artificial intelligence, remote backends, and notifications spam, delivering an Apple-quality experience focused purely on personal consistency and focus.

---

## Philosophy & Core Principles

1. **Habit Stacking**: Connect small actions to established triggers rather than abstract time slots.
2. **Never Miss Twice**: Missing once is an accident; missing twice is the start of a new habit. Tether emphasizes recovery and restarting without punishment.
3. **Offline-First & Private**: 100% of user data resides on the device. No accounts, no remote database, no tracking, and no external telemetry.
4. **Calm Aesthetic**: Restrained typography, subtle borders, warm paper-like surfaces, and Tether teal accents.
5. **No Artificial Productivity Inflation**: No AI bots, streaks flames, confetti animations, XP levels, or leaderboards.

---

## Features

- **Today Dashboard**:
  - Local calendar-based day handling (midnight rollover).
  - Dynamic greeting based on current local hour.
  - Today's #1 Focus with quick inline edit, toggle, and session tracking.
  - Habits list grouped with 7-day completion history and current streak status.
  - Non-punitive recovery messaging ("Missed yesterday. Back today?", "Ready to restart?").
- **Habit Stacking & Management**:
  - Habit creation and editing modal sheets with "After I..." and "I will..." fields.
  - Flexible frequency types: **Daily**, **Weekdays (Mon–Fri)**, **Times per week (1–6 targets)**, and **Custom**.
  - Local habit reminders with system permission integration.
  - Habit deletion with instantaneous Undo restoration snackbar.
- **Deep Focus Timer**:
  - Standard focus presets (25m, 50m, 90m).
  - Millisecond-accurate timestamp elapsed math across screen locks and backgrounding.
  - **Process-Death Recovery**: State transitions (start, pause, resume) are persisted without frame-by-frame storage overhead; completed sessions while suspended or killed are automatically logged upon app relaunch.
  - Haptic feedback on start, pause, resume, and completion.
- **Weekly Review**:
  - Monday-to-Sunday weekly consistency visualization.
  - Quantitative metrics: total completions vs. expected targets, completion percentage.
  - Focus session aggregated statistics and focused time.
  - Reflection notes editor persisted per calendar week.
- **Settings & Theme Persistence**:
  - System, Light, and Dark appearance selector with immediate UI reactivity.
  - Persistent theme mode across app cold boots.
  - Notification permissions check and direct system settings enablement link.
- **Backup & Portability**:
  - Versioned JSON backup schema (`schemaVersion: 1`).
  - **Export Backup**: Generates `tether-backup-YYYY-MM-DD.json` and opens native platform share sheet.
  - **Atomic Import**: Comprehensive schema validation, type checking, frequency validation, and confirmation dialog before replacing local storage; automatic Riverpod cache invalidation and notification rescheduling.
- **Minimal Onboarding**:
  - First-run introduction to habit stacking philosophy.
  - Practical starter templates for one-tap adoption.
  - Quick skip option to dive straight in.

---

## Technology Stack & Architecture

- **Framework**: Flutter 3.24+ (Dart 3.5+)
- **State Management**: Flutter Riverpod (`NotifierProvider`, `AsyncNotifierProvider`)
- **Persistence**: `shared_preferences`
- **Notifications**: `flutter_local_notifications` + `timezone`
- **Sharing & File Picking**: `share_plus`, `file_picker`
- **Design Tokens**: Custom vanilla design system (`AppColors`, `AppTypography`, `AppSpacing`, `AppTheme`)

### Architecture Pattern

Feature-first architecture with clear domain, data, and presentation boundaries:

```
lib/
├── app/
│   ├── app.dart                   # MaterialApp shell & theme reactivity
│   ├── router.dart                # Bottom navigation destination shell
│   └── theme/                     # Color palettes, typography & spacing
├── core/
│   ├── services/
│   │   ├── backup_service.dart     # JSON export, schema validation & atomic restore
│   │   ├── backup_provider.dart    # Riverpod provider for BackupService
│   │   ├── notification_service.dart # Local notification scheduling & permissions
│   │   └── notification_providers.dart # Riverpod provider for NotificationService
│   └── utils/
│       └── date_utils.dart        # Local calendar key conversions & week calculations
├── features/
│   ├── focus/
│   │   ├── data/repositories/     # SharedPrefsFocusRepository
│   │   ├── domain/models/         # FocusSession, DailyFocus
│   │   ├── domain/services/       # FocusService calculations
│   │   └── presentation/          # TimerNotifier, FocusTimerScreen, TodayFocusSection
│   ├── habits/
│   │   ├── data/repositories/     # SharedPrefsHabitRepository
│   │   ├── domain/models/         # Habit, HabitFrequency
│   │   ├── domain/services/       # HabitService streak & frequency domain logic
│   │   └── presentation/          # HabitsNotifier, TodayScreen, AddHabitSheet, HabitListItem
│   ├── onboarding/
│   │   └── presentation/          # OnboardingScreen with starter templates
│   ├── review/
│   │   ├── data/repositories/     # SharedPrefsReviewRepository
│   │   ├── domain/models/         # WeeklyReview
│   │   └── presentation/          # CurrentWeeklyReviewNotifier, ReviewScreen
│   └── settings/
│       ├── data/repositories/     # SharedPrefsSettingsRepository
│       ├── domain/models/         # AppSettings
│       └── presentation/          # AppSettingsNotifier, SettingsScreen
└── shared/
    └── widgets/                   # AppButton, AppScaffold, HabitRowShell
```

---

## Local Storage & SharedPreferences Keys

All records are serialized locally via JSON in `SharedPreferences`:

| Key Prefix | Type | Description |
| :--- | :--- | :--- |
| `habits_v1` | `String` (JSON Array) | List of all user habit stacks and completion date strings |
| `daily_focus_v1_<dateKey>` | `String` (JSON Object) | Daily focus text, completion status, and session counts |
| `focus_sessions_v1` | `String` (JSON Array) | Log of completed and recorded focus sessions |
| `weekly_review_v1_<dateKey>` | `String` (JSON Object) | Weekly notes, aggregated completion stats |
| `app_settings_v1` | `String` (JSON Object) | Theme mode, onboarding flag, notification preferences |
| `active_timer_v1` | `String` (JSON Object) | Process-death transition checkpoint for active focus timer |

---

## Backup Schema Format (Version 1)

```json
{
  "schemaVersion": 1,
  "exportedAt": "2026-09-28T20:00:00.000Z",
  "habits": [
    {
      "id": "uuid-v4",
      "trigger": "sit at my desk",
      "action": "write my top priority",
      "frequency": {
        "type": "daily"
      },
      "createdAt": "2026-09-28T09:00:00.000Z",
      "completedDates": ["2026-09-28"],
      "reminderTime": "8:30",
      "archived": false
    }
  ],
  "dailyFocus": [
    {
      "dateKey": "2026-09-28",
      "priorityText": "Ship Phase 4",
      "completed": true,
      "focusSessionCount": 1
    }
  ],
  "focusSessions": [
    {
      "id": "uuid-v4",
      "date": "2026-09-28T10:00:00.000Z",
      "durationMinutes": 25,
      "completed": true,
      "createdAt": "2026-09-28T10:25:00.000Z"
    }
  ],
  "weeklyReviews": [
    {
      "weekStartDate": "2026-09-28T00:00:00.000Z",
      "weekEndDate": "2026-10-04T23:59:59.000Z",
      "habitsCompleted": 5,
      "habitsExpected": 7,
      "focusSessions": 3,
      "notes": "Great progress this week.",
      "createdAt": "2026-09-28T20:00:00.000Z"
    }
  ],
  "settings": {
    "themeMode": "system",
    "isFirstLaunch": false,
    "notificationsEnabled": true
  }
}
```

---

## Development Setup & Testing

### Prerequisites
- Flutter SDK 3.24+
- Dart SDK 3.5+
- Android Studio / Xcode

### Setup
```bash
# Clone the repository
git clone https://github.com/omrxjpxt/Tether--Habit-Tracker.git
cd "Tether- Habit Tracker"

# Install dependencies
flutter pub get

# Static code analysis
flutter analyze

# Run the full test suite
flutter test
```

---

## Platform Build Instructions

### Android Build
```bash
# Build Release APK
flutter build apk --release

# Build Google Play App Bundle (AAB)
flutter build appbundle --release
```
Artifacts are generated in:
- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`

#### Android Signing & Release Notes
1. Create an upload keystore:
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Reference the keystore in `android/key.properties`:
   ```properties
   storePassword=<password>
   keyPassword=<password>
   keyAlias=upload
   storeFile=<path_to_store_file>
   ```
3. Update `android/app/build.gradle.kts` release signing configuration to read from `key.properties`.

### iOS Build & Release Preparation
1. Open the iOS project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. In the **Signing & Capabilities** tab of the `Runner` target:
   - Select your registered Apple Developer Team.
   - Set your custom Bundle Identifier (e.g. `com.yourcompany.tether`).
   - Add the **Push Notifications** or **Background Modes** capability if background badge updates are desired.
3. Build the release archive:
   ```bash
   flutter build ipa --release
   ```
4. Distribute using Xcode Organizer or `xcrun altool` / TestFlight.

---

## Known Limitations

- **Local Notification Limits**: Operating systems enforce limits on scheduled local notifications (64 on iOS, system alarm limits on Android). Tether deterministically schedules notifications for active habits.
- **Battery Optimization**: On certain aggressive Android OEM skins (e.g. MIUI, ColorOS), exact alarms and background execution may require users to disable battery optimization in system settings.
