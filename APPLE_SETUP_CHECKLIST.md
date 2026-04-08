# Apple Setup Checklist – MessagingDemoAppSwiftUI

This matches what your app does to what you need in the Apple Developer portal and Xcode.

---

## What Your App Does

| Feature | Where it's used |
|--------|------------------|
| **Push Notifications** | Register for push, receive token, send to AEP, handle taps and silent push |
| **Background processing** | `didReceiveRemoteNotification` with `fetchCompletionHandler` (remote-notification, fetch, processing) |
| **In-App Messaging** | Surfaces and propositions from AEP |
| **Content Cards** | Card surface "cardstab" |
| **Code-Based Experiences** | CBE HTML + JSON surfaces |
| **Live Activities** | 3 types: Airplane, Food Delivery, Game Score (Dynamic Island / Lock Screen) |
| **Widget extension** | Renders Live Activity UI (WidgetMessagingDemoAppSwiftUI) |
| **Adobe Assurance** | URL scheme `messagingdemo://` for debugging |

Your **Info.plist** already has:
- `UIBackgroundModes`: `fetch`, `remote-notification`, `processing`
- URL scheme: `messagingdemo`
- (Project has `NSSupportsLiveActivities` and `NSSupportsLiveActivitiesFrequentUpdates`)

Your **entitlements** already have:
- `aps-environment`: `development`

---

## Required in Apple Developer Portal

### 1. App ID: Main app

- **Identifier:** `com.adampadobe.aep-messaging-demo`
- **Description:** e.g. `AEP Messaging Demo SwiftUI`

**Capabilities to enable:**

| Capability | Required | Notes |
|------------|----------|--------|
| **Push Notifications** | ✅ Yes | Needed for APNs and AEP push. |
| **Background Modes** | ✅ Yes | Your app uses `remote-notification`, `fetch`, and `processing`. After enabling Background Modes, **Configure** it and turn on **Remote notifications** (and optionally **Background fetch** / **Background processing** if you use them). |

No other capabilities are required for push, in-app, content cards, or Live Activities.

---

### 2. App ID: Widget extension

- **Identifier:** `com.adampadobe.aep-messaging-demo.WidgetMessagingDemoAppSwiftUI`
- **Description:** e.g. `AEP Messaging Demo SwiftUI Widget`

**Capabilities:** None required. Create the App ID with no extra capabilities so the extension can be signed and the Live Activity UI can run.

---

## APNs key (for AEP)

- Create one **APNs key** (.p8) under **Keys** and use it for both the main app and (if needed later) the widget.
- Use the same **Team ID** and this **Key ID** + **.p8** in AEP/Journey Optimizer with **Bundle ID** `com.adampadobe.aep-messaging-demo`.

---

## Xcode

1. **Team:** For both **MessagingDemoAppSwiftUI** and **WidgetMessagingDemoAppSwiftUI** targets, set **Signing & Capabilities** → **Team** to your Apple Developer team.
2. **Run:** Use a physical iPhone for real push and Live Activity; simulator is fine for UI and in-app/cards.

---

## Summary

- **Main App ID:** Push Notifications + Background Modes (with **Remote notifications** enabled in Background Modes).
- **Widget App ID:** Create with no capabilities.
- **Entitlements/Info.plist:** Already correct for push and background; no changes needed for this checklist.
- **APNs key:** One .p8 for AEP; main app Bundle ID `com.adampadobe.aep-messaging-demo`.

After this, you have everything required for the app to run with Apple and for push + Live Activity with AEP.
