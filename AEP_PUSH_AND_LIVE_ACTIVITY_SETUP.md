# Register App for AEP Push & Live Activity Testing

This guide gets **MessagingDemoAppSwiftUI** registered so you can upload credentials to AEP (Adobe Experience Platform / Journey Optimizer), get a push token, and test Live Activities.

---

## Do I need a paid Apple Developer account?

**Yes.** For push notifications and loading credentials into AEP you need:

- **Apple Developer Program** — **$99/year** at [developer.apple.com/programs](https://developer.apple.com/programs/)
- Used for:
  - Creating an **APNs key** (.p8) that you upload to AEP
  - **Push notifications** (APNs only works with a real app ID and signing)
  - Running on a **real device** to get a valid push token (simulator does not receive real push)
  - **Live Activities** on a real device for full testing

You can still run the app in the **simulator** without a paid account, but you will **not** get a real push token or receive push/Live Activity updates from AEP until you use a paid account and a physical device.

---

## Quick reference (for AEP / Journey Optimizer)

Use these when configuring the app in AEP/AJO:

| Item | Value |
|------|--------|
| **App Bundle ID** | `com.adobe.MessagingDemoAppSwiftUI` |
| **Widget Bundle ID** (Live Activity) | `com.adobe.MessagingDemoAppSwiftUI.WidgetMessagingDemoAppSwiftUI` |
| **Push entitlement** | Already in project (`aps-environment`: development) |
| **Your Team ID** | From [Apple Developer → Membership](https://developer.apple.com/account) |
| **APNs Key ID** | From Apple Developer → Keys (after creating APNs key) |
| **.p8 file** | Downloaded once when you create the key (keep a safe copy) |

---

## Step 1: Apple Developer Program

1. Enroll at [developer.apple.com/programs](https://developer.apple.com/programs/) ($99/year).
2. After approval, go to [developer.apple.com/account](https://developer.apple.com/account) and note your **Team ID** (e.g. `ABCD1234`).

---

## Step 2: Create an App ID with Push Notifications

1. Go to [developer.apple.com/account → Identifiers](https://developer.apple.com/account/resources/identifiers/list).
2. Click **+** → **App IDs** → **App**.
3. Description: e.g. `AEP Messaging Demo SwiftUI`.
4. **Bundle ID**: **Explicit** → `com.adobe.MessagingDemoAppSwiftUI` (must match the app).
5. Under **Capabilities**, enable:
   - **Push Notifications**
   - **Background Modes** (optional; enable “Remote notifications” if you use background push).
6. Click **Continue** → **Register**.

If you use a **different** bundle ID in Xcode, create an App ID for that bundle ID instead and use it everywhere below.

---

## Step 3: Create an APNs key (.p8) for AEP

1. Go to [developer.apple.com/account → Keys](https://developer.apple.com/account/resources/authkeys/list).
2. Click **+** to add a key.
3. **Key Name**: e.g. `AEP Push Key`.
4. Enable **Apple Push Notifications service (APNs)**.
5. **Continue** → **Register**.
6. **Download the .p8 file** (you can only download it once; store it securely).
7. Note the **Key ID** (e.g. `XYZ123ABC`).

You will use in AEP:
- The **.p8 file**
- **Key ID**
- **Team ID**
- **Bundle ID**: `com.adobe.MessagingDemoAppSwiftUI`

---

## Step 4: Xcode signing and capabilities

1. Open the project:
   ```bash
   cd /Users/apalmer/Apple_App/aepsdk-messaging-ios
   open AEPMessaging.xcworkspace
   ```
2. Select the **MessagingDemoAppSwiftUI** scheme.
3. Select the **AEPMessaging** project in the navigator → **Signing & Capabilities** for the **MessagingDemoAppSwiftUI** target.
4. Check **Automatically manage signing**.
5. **Team**: choose your Apple Developer team (paid account).
6. Confirm **Push Notifications** is in the capability list (it is already in the entitlements file).

The app’s entitlements already include `aps-environment` = `development`. For production push later, you would switch that to `production` (or use a separate build/config).

---

## Step 5: Run on a real device and get the push token

1. Connect an **iPhone** (physical device).
2. In Xcode, choose your **iPhone** as the run destination (not a simulator).
3. Build and run (**⌘R**).
4. On first run, allow **Notifications** when prompted.
5. In the app, open the **Push** tab.
6. Copy the **Push Token** (and **Experience Cloud ID** if needed for AEP).

This token is what AEP/Journey Optimizer will use to send push and update Live Activities to this device.

**Note:** Simulator can show a token in some setups, but **delivery of push and Live Activity updates from AEP requires a real device** with the credentials and App ID configured as above.

---

## Step 6: Add push credentials in AEP / Journey Optimizer

1. In **Adobe Journey Optimizer**: **Channels** → **Push settings** → **Push credentials** (or equivalent in your AEP setup).  
   In **Data Collection** (Launch): configure the mobile app and push credentials as per your product’s UI.
2. **Create** a new push credential for iOS.
3. Provide:
   - **.p8 file** (upload)
   - **Key ID**
   - **Team ID**
   - **Bundle ID**: `com.adobe.MessagingDemoAppSwiftUI`
4. Save.

References:
- [Configure push notification channel (Experience League)](https://experienceleague.adobe.com/docs/journey-optimizer/using/channels/push/push-config/push-configuration.html)
- [Push notification – API reference](https://developer.adobe.com/client-sdks/edge/adobe-journey-optimizer/push-notification/ios/api-reference)

---

## Step 7: Configure your app in AEP and test

1. In AEP/Journey Optimizer, ensure the **mobile app** is registered with the same **Bundle ID** and push credential you created.
2. Ensure the app’s **Launch App ID** (or equivalent) in `Constants.swift` matches the app configuration in AEP (e.g. your Launch property and environment).
3. Send a test push (or trigger a journey that sends push) to the **push token** you copied from the app.
4. For **Live Activities**: trigger the journey or experience that updates the Live Activity; test on the same physical device where you got the push token.

---

## What’s already done in this project (no extra code needed)

- **Push**: entitlements (`aps-environment`), registration in `AppDelegate`, `MobileCore.setPushIdentifier(deviceToken)`, and **Push** tab showing/copying the token.
- **Live Activities**: registered in `AppDelegate` (`Messaging.registerLiveActivities([...])`) and demo screens under the **Live Activity** tab.

Once the app is registered in Apple Developer, credentials are added in AEP, and you run on a real device, you can use the same app to get the push token and test Live Activities end-to-end.

---

## Summary checklist

- [ ] Apple Developer Program enrolled ($99/year)
- [ ] App ID created with Bundle ID `com.adobe.MessagingDemoAppSwiftUI` and Push Notifications enabled
- [ ] APNs key created; .p8 downloaded; Key ID and Team ID noted
- [ ] Xcode: Team set for MessagingDemoAppSwiftUI; run on real iPhone
- [ ] Push token (and ECID) copied from the app’s **Push** tab
- [ ] Push credential (.p8, Key ID, Team ID, Bundle ID) added in AEP/Journey Optimizer
- [ ] Test push and Live Activity from AEP to the device
