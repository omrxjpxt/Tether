# Google Play Testing & Release Strategy — Tether

Google Play enforces specific release and testing rules depending on whether your developer account was created before or after November 13, 2023, and whether it is a **Personal** or **Organization** account.

---

## 1. Google Play Developer Account Requirements

### Personal Developer Accounts (Created on or after Nov 13, 2023):
- **Mandatory Closed Testing Requirement:** Must run a closed test with at least **20 testers opted in continuously for at least 14 consecutive days**.
- **Production Access Application:** After completing the 14-day closed test, you must submit an application form in Play Console describing your testing process, feedback received, and app readiness before Google grants production release privileges.
- **Organization Accounts:** Organization accounts are typically exempt from the 20-tester/14-day closed test mandate, though closed or internal testing remains strongly recommended.

---

## 2. Release Track Hierarchy

To bring Tether safely from local development to production, follow this sequence in Google Play Console:

```
[1. Internal Testing] ──> [2. Closed Testing (20 Testers / 14 Days)] ──> [3. Production Release]
```

---

## 3. Track 1: Internal Testing Track

Internal testing allows immediate distribution to up to 100 internal testers (team members, personal test devices) without waiting for Google review.

### Steps:
1. In Google Play Console, navigate to **Testing > Internal testing**.
2. Click **Create new release**.
3. Upload the generated release App Bundle (`build/app/outputs/bundle/release/app-release.aab`).
4. Enter release notes (e.g., "Initial internal release of Tether v1.0.0").
5. Under **Testers**, create an email list (e.g., "Internal QA") and add your testing email addresses.
6. Copy the **Join on the web** or **Join on Android** link and open it on your test devices to download Tether.

---

## 4. Track 2: Closed Testing Track (20 Testers / 14 Days)

This is the required prerequisite for personal developer accounts before Google unlocks production publishing.

### Step-by-Step Setup:
1. Navigate to **Testing > Closed testing**.
2. Under the default closed track (Alpha), click **Manage track > Create release**.
3. Upload the signed `app-release.aab`.
4. Define your Testers list:
   - Create an email list with **at least 20 unique Google Play accounts**.
   - Ensure all 20 testers accept the opt-in invite link and keep the app installed on their devices.
5. Submit the release for review. Once approved by Google, the 14-day clock begins when 20 testers are actively opted in.
6. Keep the closed test active for **14 full days**.

### Tester Guidance & Feedback Instructions:
Provide your testers with the following checklist to evaluate:
- **First Launch & Onboarding:** Verify starter templates work and "Skip" works smoothly.
- **Habit Stacking:** Create daily, weekday, and custom habits. Verify completion checkmarks.
- **Deep Focus Timer:** Run a 25m focus session; test pausing, resuming, locking the screen, and backgrounding.
- **Local Reminders:** Schedule a reminder and verify notification fires at the designated local time.
- **Weekly Review:** Check Monday–Sunday dots, statistics, and write a reflection note.
- **Offline Integrity:** Turn on Airplane mode and verify all features continue working seamlessly.
- **Backup & Restore:** Export a backup JSON file, save to device, and restore it to verify atomicity.

---

## 5. Track 3: Applying for Production Access

Once the 14-day closed test requirement is met:

1. In Play Console, go to **Dashboard > Apply for production**.
2. Complete Google's mandatory questionnaire:
   - **How did you recruit testers?** (e.g., friends, colleagues, community members interested in minimalist habit stacking).
   - **How easy was it to recruit testers?**
   - **What feedback did you receive during testing?** (e.g., UI feedback on contrast, timer transitions, reminder timing).
   - **What changes did you make based on feedback?**
   - **How did you decide Tether is ready for production?** (Automated test suite of 54 tests passing, 0 crashes reported, 100% offline verification).
3. Google reviews the application (typically within 7 business days).
4. Once approved, you can promote the release to the **Production track** and publish Tether to the Google Play Store!
