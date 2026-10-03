# Tether  

> **Build habits that stick.**

Tether is a calm, offline-first personal habit, consistency, and focus application built around the foundational principle of habit stacking:

> *"After I [trigger], I will [action]."*

Tether helps you build sustainable daily routines by anchoring new micro-actions to existing habitual behaviors. It deliberately eschews gamification, social feeds, artificial intelligence, remote databases, and notification spam, delivering an Apple-quality experience focused purely on personal consistency, intentionality, and focus.

---

## Philosophy & Core Principles

1. **Habit Stacking**: Connect small, concrete actions to established physical or situational triggers rather than abstract calendar times.
2. **Never Miss Twice**: Missing once is an accident; missing twice is the start of a new habit. Tether emphasizes recovery and restarting without punishment or streak shaming.
3. **Offline-First & Private**: 100% of user data resides on your device in local storage. No accounts, no cloud servers, no tracking, and no telemetry.
4. **Calm & High-Contrast Aesthetic**: Warm paper-like surfaces, restrained typography, subtle borders, high-contrast text hierarchy, and Tether teal accents.
5. **Zero Noise**: No AI assistants, chat bubbles, streak flames, confetti popups, XP levels, or leaderboards.

---

## Features

### 📅 Today Dashboard
- **Local Calendar Day Rollover**: All completions and streaks are keyed to local calendar dates (`YYYY-MM-DD`), preventing timezone and UTC shift anomalies.
- **Dynamic Greeting**: Time-aware greeting reflecting your morning, afternoon, or evening.
- **Today's #1 Focus**: Prominent daily priority card with inline editing, completion toggle, and direct focus timer integration.
- **Habit Stack Cards**: Habits displayed with clear "After I [trigger], I will [action]" typography, 7-day completion history dots, and current streak count.
- **Non-Punitive Recovery UX**: Supportive recovery states ("Missed yesterday. Back today?", "Ready to restart?") instead of destructive streak breaks.

### 🔗 Habit Stacking & Creation
- **Stacking Flow**: Modal creation sheet prompting for an established trigger and clear micro-action.
- **Flexible Frequency Types**:
  - **Daily**: Every day. 
  - **Weekdays**: Monday through Friday.
  - **Times per week**: Flexible target from 1× to 6× per week.
  - **Custom**: Specific days of the week.
- **Platform-Aware Reminders**: Set daily reminder times on supported mobile platforms, with automatic scheduling and rescheduling.
- **Safe Habit Deletion**: Delete habits with an instantaneous Undo snackbar to prevent accidental losses.

### ⏱️ Deep Focus Timer
- **Standard Focus Presets**: Quick access to 25m, 50m, and 90m deep work sessions.
- **Timestamp-Accurate Elapsed Math**: Resilient against screen locking, app backgrounding, and clock adjustments.
- **Process-Death Recovery**: Timer state transitions are persisted; completed sessions while suspended or killed are automatically logged upon app relaunch.
- **Haptic Feedback**: Tactile responses for starting, pausing, resuming, and completing focus intervals.

### 📊 Weekly Review
- **Monday–Sunday Consistency Matrix**: Visual breakdown of habit completion across the current week.
- **Quantitative Metrics**: Total completions vs. expected targets and overall completion percentage.
- **Focus Session Analytics**: Aggregated total focused minutes and session count.
- **Weekly Reflection Notes**: Persistent scratchpad for journaling weekly observations and adjustments.

### 🎨 Settings & High-Contrast Theme System
- **Theme Modes**: **System**, **Light**, and **Dark** appearance options with immediate UI reactivity.
  - **Light Mode**: Warm ivory canvas (`#FBF9F5`), elevated card surfaces (`#FFFFFF`), high-contrast charcoal text (`#1C1B1F`), and defined borders.
  - **Dark Mode**: Deep obsidian canvas (`#121314`), elevated surface tiles (`#1C1D1F`), and muted borders.
- **Notifications Hub**: Platform-aware notification status and permission management.

### 💾 Backup & Portability
- **Versioned JSON Schema (`schemaVersion: 1`)**: Complete export containing habits, daily focus, focus sessions, weekly reviews, and app settings.
- **Export Backup**: Generates `tether-backup-YYYY-MM-DD.json` and opens the native system share sheet.
- **Atomic Import & Validation**: Strict schema validation, type checking, and duplicate prevention before replacing local storage; invalidates Riverpod providers and reschedules reminders automatically.

### 🚀 Minimal Onboarding
- First-launch introduction to habit stacking principles.
- Curated starter templates for one-tap adoption.
- Quick skip option to start with a blank slate immediately.

---

## Platform Support

| Platform | Status | Reminders / Notifications |
| :--- | :--- | :--- |
| **iOS** | Supported | Full scheduled & repeating local notifications via UserNotifications |
| **Android** | Supported | Full scheduled & repeating notifications with exact alarm permissions |
| **macOS** | Supported | Local notifications via Darwin notification service |
| **Web (Chrome)** | Supported | Platform-guarded: Informational badge indicating mobile reminder availability |

---

## Technology Stack

- **Framework**: Flutter 3.24+ (Dart 3.5+)
- **State Management**: Flutter Riverpod (`NotifierProvider`, `AsyncNotifierProvider`)
- **Persistence**: `shared_preferences`
- **Notifications**: `flutter_local_notifications` + `timezone`
- **Platform Sharing & Files**: `share_plus`, `file_picker`
- **Design Tokens**: Custom design system (`AppColors`, `AppTypography`, `AppSpacing`, `AppTheme`)

---

## Architecture Pattern

Tether follows a feature-first architecture with strict domain, data, and presentation layer separation:

```
lib/
├── app/
│   ├── app.dart                          # MaterialApp shell & theme reactivity
│   ├── router.dart                       # Bottom navigation destination shell
│   └── theme/                            # Color tokens, typography & spacing
├── core/
│   ├── services/
│   │   ├── backup_service.dart           # JSON export, schema validation & atomic restore
│   │   ├── backup_provider.dart          # Riverpod provider for BackupService
│   │   ├── notification_service.dart     # Local notification scheduling & permissions
│   │   └── notification_providers.dart   # Riverpod provider for NotificationService
│   └── utils/
│       └── date_utils.dart               # Local calendar key conversions & week calculations
├── features/
│   ├── focus/
│   │   ├── data/repositories/            # SharedPrefsFocusRepository
│   │   ├── domain/models/                # FocusSession, DailyFocus
│   │   ├── domain/repositories/          # FocusRepository interface
│   │   ├── domain/services/              # FocusService calculation logic
│   │   └── presentation/                 # TimerNotifier, FocusTimerScreen, TodayFocusSection
│   ├── habits/
│   │   ├── data/repositories/            # SharedPrefsHabitRepository
│   │   ├── domain/models/                # Habit, HabitFrequency
│   │   ├── domain/repositories/          # HabitRepository interface
│   │   ├── domain/services/              # HabitService streak & frequency logic
│   │   └── presentation/                 # HabitsNotifier, TodayScreen, AddHabitSheet, HabitListItem
│   ├── onboarding/
│   │   └── presentation/                 # OnboardingScreen with starter templates
│   ├── review/
│   │   ├── data/repositories/            # SharedPrefsReviewRepository
│   │   ├── domain/models/                # WeeklyReview
│   │   ├── domain/repositories/          # ReviewRepository interface
│   │   └── presentation/                 # CurrentWeeklyReviewNotifier, ReviewScreen
│   └── settings/
│       ├── data/repositories/            # SharedPrefsSettingsRepository
│       ├── domain/models/                # AppSettings
│       ├── domain/repositories/          # SettingsRepository interface
│       └── presentation/                 # AppSettingsNotifier, SettingsScreen
├── shared/
│   └── widgets/                          # AppButton, AppScaffold, HabitRowShell
└── main.dart                             # App entrypoint & ProviderScope initialization
```

---

## Local Storage & SharedPreferences Keys

All records are serialized locally via JSON in `SharedPreferences`:

| Key Prefix | Type | Description |
| :--- | :--- | :--- |
| `habits_v1` | `String` (JSON Array) | All user habit stacks, frequencies, and completion date strings |
| `daily_focus_v1_<dateKey>` | `String` (JSON Object) | Daily priority text, completion flag, and session count |
| `focus_sessions_v1` | `String` (JSON Array) | History of completed focus sessions |
| `weekly_review_v1_<dateKey>` | `String` (JSON Object) | Weekly reflection notes and aggregated completion stats |
| `app_settings_v1` | `String` (JSON Object) | Selected theme mode, onboarding completion flag |
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
      "trigger": "sit down at my desk",
      "action": "write my top priority for the next hour",
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
      "priorityText": "Write project specification",
      "completed": true,
      "focusSessionCount": 2
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
      "notes": "Focused heavily on deep work blocks this week.",
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

## Development Setup & Verification

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.24+
- [Dart SDK](https://dart.dev/get-dart) 3.5+
- Xcode (for iOS/macOS) / Android Studio (for Android) / Google Chrome (for Web)

### Getting Started

```bash
# 1. Clone the repository
git clone https://github.com/omrxjpxt/Tether.git
cd Tether

# 2. Install dependencies
flutter pub get

# 3. Run static analysis
flutter analyze

# 4. Run test suite (54 tests passing)
flutter test
```

### Running Locally 

```bash
# Run in Google Chrome
flutter run -d chrome

# Run on macOS desktop
flutter run -d macos

# Run on connected iOS Simulator or Android Emulator
flutter run
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

#### Android Signing
1. Generate an upload keystore:
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

### iOS Build
1. Open the iOS project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. In the **Signing & Capabilities** tab:
   - Select your Apple Developer Team.
   - Configure your unique Bundle Identifier.
3. Build the release archive:
   ```bash
   flutter build ipa --release
   ```

### Web Build
```bash
flutter build web --release
```
Static production artifacts are generated in `build/web/`.

---

## Test Suite Coverage

Tether maintains comprehensive automated test coverage across unit, domain, service, provider, and widget layers (54 tests across 14 suites):

| Test Suite | Scope |
| :--- | :--- |
| `date_utils_test.dart` | Local calendar date keys, ISO parsing, week boundaries, and day differences |
| `backup_service_test.dart` | Schema validation, corruption rejection, version checks, and atomic restore |
| `notification_service_test.dart` | Deterministic notification IDs, active frequency days, and schedule calculations |
| `habit_service_test.dart` | Streak calculations, recovery rules, frequency evaluations, and completions |
| `focus_service_test.dart` | Session duration math, daily focus aggregations, and process-death state transitions |
| `shared_prefs_habit_repository_test.dart` | Habit serialization, corrupt JSON handling, and CRUD operations |
| `timer_provider_test.dart` | Timer countdown, pause/resume, completion events, and state persistence |
| `review_providers_test.dart` | Weekly summary computations and reflection notes updates |
| `review_screen_test.dart` | Weekly Review screen rendering, navigation, and empty state messaging |
| `settings_provider_test.dart` | Theme mode switching, onboarding flag updates, and persistence |
| `settings_screen_test.dart` | Appearance selection, notifications panel, and backup controls |
| `today_screen_test.dart` | Empty states, habit lists, and focus card interactions |
| `add_habit_sheet_test.dart` | Form inputs, frequency selectors, and platform-aware reminder controls |
| `onboarding_screen_test.dart` | Starter template selection, skip actions, and onboarding completion |

---

## Production & Release Documentation

- [Privacy Policy](file:///Users/omgangwar/Documents/Projects/Tether-%20Habit%20Tracker/PRIVACY_POLICY.md): Official local-first privacy policy and disclosures.
- [Google Play Data Safety](file:///Users/omgangwar/Documents/Projects/Tether-%20Habit%20Tracker/DATA_SAFETY.md): Play Console Data Safety reference and field mappings.
- [Play Store Listing](file:///Users/omgangwar/Documents/Projects/Tether-%20Habit%20Tracker/PLAY_STORE.md): App title, short/full descriptions, feature highlights, and screenshot specifications.
- [Play Testing & Release Guide](file:///Users/omgangwar/Documents/Projects/Tether-%20Habit%20Tracker/PLAY_TESTING.md): Closed testing (14-day / 20-tester requirement), internal testing track, and production application steps.

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
