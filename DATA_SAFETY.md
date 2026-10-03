# Google Play Console — Data Safety Form Reference for Tether

This document provides exact responses and disclosures required when completing the **Data safety** questionnaire in the Google Play Console for **Tether v1**.

---

## 1. Overview & Core Declarations

| Question in Play Console | Response | Technical Justification |
| :--- | :--- | :--- |
| **Does your app collect or share any of the required user data types?** | **No** | Tether does not transmit any user data off the device. All records remain in local application storage (`SharedPreferences`). The app does not request or possess the `android.permission.INTERNET` permission. |
| **Is all of the user data collected by your app encrypted in transit?** | **Not applicable (N/A)** | No data is transmitted across networks or off-device. |
| **Do you provide a way for users to request that their data be deleted?** | **Yes** | Users can delete individual habits or wipe all data by uninstalling the application or using device system settings (`Settings > Apps > Tether > Clear Storage`). |

---

## 2. Data Collection vs. Local Storage Breakdown

Google Play defines **Data Collection** as transmitting data off the device. Data that remains strictly on the device is **not** considered collected for the Data Safety questionnaire.

### Data Types Handled Locally Only (Not Transmitted):

1. **User Personal Info / Identifiers:**
   - **Name, Email, User IDs, Phone Number, Address:** **NOT collected, NOT stored.**
2. **Health and Fitness:**
   - **Fitness / Habit Activity:** Stored locally on device only (`habits_v1`, `daily_focus_v1_*`). Never transmitted to servers.
3. **App Activity:**
   - **Page views, interactions, in-app search:** **NOT collected, NOT transmitted.**
4. **App Info and Performance:**
   - **Crash logs, diagnostics, performance metrics:** **NOT collected.** Tether does not include Crashlytics, Sentry, Datadog, or any telemetry SDK.
5. **Device or Other Identifiers:**
   - **Advertising ID, IMEI, MAC address, Android ID:** **NOT accessed or collected.**

---

## 3. Play Console Permissions Declaration

When completing the **App permissions** section in Play Console:

| Permission | Android Manifest Key | Play Console Justification |
| :--- | :--- | :--- |
| **Post Notifications** | `android.permission.POST_NOTIFICATIONS` | Required on Android 13+ (API 33+) to alert the user at their scheduled reminder times. |
| **Receive Boot Completed** | `android.permission.RECEIVE_BOOT_COMPLETED` | Required to reschedule active user-configured local alarms if the device reboots or restarts. |
| **Vibrate** | `android.permission.VIBRATE` | Required for tactile haptic feedback during timer state transitions and habit completion checks. |

---

## 4. Third-Party SDK Verification

Audit of all compiled dependencies from `pubspec.lock`:

- `flutter_riverpod` (v3.4.3): Pure state management; no networking.
- `shared_preferences` (v2.5.5): Android `SharedPreferences` wrapper; local storage only.
- `flutter_local_notifications` (v22.3.1): Android `AlarmManager` and `NotificationManager` wrapper; no network calls.
- `timezone` (v0.11.1): Offline IANA timezone database for date math.
- `intl` (v0.20.3): Local date formatting and localization utilities.
- `uuid` (v4.6.0): Offline UUID v4 generation for local record IDs.
- `share_plus` (v13.3.0): System Intent for opening Android share sheet for user-triggered backup exports.
- `file_picker` (v13.1.0): System Storage Access Framework (`GET_CONTENT`) for user-selected backup import.
- `path_provider` (v2.1.6): Local file directory resolution for backup files.

**Conclusion:** Zero third-party SDKs transmit data or connect to remote endpoints.

---

## 5. Play Console Step-by-Step Selection Guide

When filling out the form in **Play Console > Policy > App content > Data safety**:

1. **Data collection and security**:
   - "Does your app collect or share any of the required user data types?" -> Select **No**.
2. **Data types**:
   - Since "No" was selected, no individual data categories need to be checked.
3. **App Privacy Policy link**:
   - Provide the public URL where `PRIVACY_POLICY.md` is hosted (e.g. GitHub Pages or website).
