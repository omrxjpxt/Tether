# Privacy Policy for Tether

**Effective Date:** [EFFECTIVE DATE, e.g., October 4, 2026]  
**Last Updated:** [LAST UPDATED DATE, e.g., October 4, 2026]

Tether ("we", "our", or "the app") is a personal habit tracking and focus application built with an offline-first architecture. This Privacy Policy outlines our data handling practices and explains how your information is stored and managed when using Tether.

---

## 1. Core Principle: Local-First and Private

Tether is designed from the ground up to operate entirely on your device. We do not operate remote servers, user databases, authentication systems, cloud synchronizations, or remote analytics for Tether v1.

- **No User Accounts:** You do not create an account or provide an email, username, or password to use Tether.
- **No Cloud Synchronization:** Your habits, focus timers, reflections, and settings are never transmitted to our servers or third-party cloud hosts.
- **No Remote Telemetry or Tracking:** Tether contains zero third-party advertising SDKs, tracking libraries, or remote telemetry frameworks.
- **No Internet Access Required:** Tether does not request or require network permissions to function.

---

## 2. Information Stored Locally on Your Device

All data you enter into Tether is stored strictly within your device's private application sandbox (via local `SharedPreferences` storage):

1. **Habit Data:** Habit triggers (e.g., "After I pour morning coffee"), actions (e.g., "I will meditate for 2 minutes"), chosen frequencies (daily, weekdays, custom days, or target times per week), reminder times, and creation timestamps.
2. **Completion History:** Dates (in local `YYYY-MM-DD` format) on which habits were completed, used to calculate current and longest streaks.
3. **Daily Focus:** Your daily #1 priority text, completion state, and session counts.
4. **Focus Sessions:** Session logs including duration (minutes), completion timestamps, and whether a session was completed or canceled.
5. **Weekly Reviews & Reflections:** Journal reflections, expected habit counts, actual completion counts, and focus session totals for each calendar week.
6. **Application Preferences:** Visual theme preference (System, Light, or Dark) and onboarding status.

---

## 3. Device Permissions

Tether requests only the minimum device permissions necessary to provide its core features:

| Permission | Purpose |
| :--- | :--- |
| **Notifications (`POST_NOTIFICATIONS`)** | Used exclusively to deliver scheduled local habit reminders that you explicitly configure. Notifications are generated locally by your device operating system, not received via remote push servers. |
| **Receive Boot Completed (`RECEIVE_BOOT_COMPLETED`)** | Used on Android to reschedule your active local habit reminders after your device reboots. |
| **Vibration (`VIBRATE`)** | Used to provide haptic feedback when completing habits, starting timers, or pausing intervals. |

Tether does **NOT** request access to your contacts, camera, microphone, location, photo gallery, device identity, phone status, or external storage.

---

## 4. Backup, Export, and Portability

Tether includes an explicit user-controlled data export feature:

- **Local File Generation:** When you export a backup, Tether compiles your habits, focus sessions, daily focus, weekly reviews, and preferences into a standardized JSON file (`tether-backup-YYYY-MM-DD.json`) saved in your temporary device cache.
- **System Share Sheet:** The file is handed directly to your operating system's native share sheet (`share_plus`). You choose where to send it (e.g., save to device files, email to yourself, or store in your personal cloud drive).
- **No Automated Uploads:** Tether never uploads this backup file automatically.

---

## 5. Data Retention and Deletion

Because all data resides exclusively on your device:

- **Habit Deletion:** You can delete individual habits at any time from within the app.
- **Clear App Data:** You can delete all Tether data immediately by clearing the app data in your device's system settings (`Settings > Apps > Tether > Storage > Clear Data / Clear Storage`).
- **App Uninstall:** Uninstalling Tether immediately removes the application sandbox and deletes all stored habits, sessions, reviews, and preferences from your device.

---

## 6. Children's Privacy

Tether does not collect personal information from any user, including children under the age of 13. The application is completely functional offline and does not establish network connections.

---

## 7. Changes to This Privacy Policy

If we update our privacy practices in future versions (for example, if optional cloud backup is introduced in a future release), we will update this document, revise the "Last Updated" date, and provide clear in-app disclosures before any data transmission occurs.

---

## 8. Contact Information

If you have any questions or concerns regarding this Privacy Policy or Tether's data practices, please contact:

**Developer:** [YOUR NAME OR ORGANIZATION]  
**Contact Email:** [YOUR CONTACT EMAIL]  
**Website / Repository:** https://github.com/omrxjpxt/Tether  
