# Live Activity Push-to-Start Token — Debug Log

**Date:** 2026-05-09  
**Device under test:** iPhone 15 (Adam Dev iPhone) — ECID `47288941103661241645408602224153721911`  
**Reference device (working):** iPhone 17e (Adam Work iPhone) — ECID `72741576365611900757159622710055496241`  
**Sandbox:** `apalmer`  
**App:** `com.adampadobe.aep-messaging-demo`

---

## Symptom

`liveActivityPushNotificationDetails` was absent from the RTCP profile for the iPhone 15.  
Standard `pushNotificationDetails` was present and healthy. Assurance confirmed push-to-start tokens were being delivered by Apple to the device, but they never reached the profile.

---

## Root Cause 1 — DCVS rejecting the entire edge event

### What happened

The AEP Messaging SDK's `sendLiveActivityPushToStartTokens` method (in `Messaging+EdgeEvents.swift`) built its edge event with **both** an `xdm` key and a `data` key:

```swift
// BEFORE (broken)
let eventData: [String: Any] = [
    MessagingConstants.XDM.Key.XDM: [
        MessagingConstants.XDM.Key.EVENT_TYPE: MessagingConstants.XDM.LiveActivity.EventType.PUSH_TO_START
    ],
    MessagingConstants.XDM.Key.DATA: [
        MessagingConstants.XDM.LiveActivity.PUSH_NOTIFICATION_DETAILS: detailsArray
    ]
]
```

The `demoemea` sandbox has an identity descriptor on the event experience dataset (`69fe4a56395ace540691d293`) that marks `_demoemea.identification.core.ecid` as the primary identity with `xdm:isPrimary: true`. The Schema Registry enforces the parent path as a **required** field on every Experience Event that carries an `xdm` block. Any event whose `xdm` block lacks `_demoemea.identification.core.ecid` is rejected (HTTP 400, `DCVS-1106-400`).

Because the push-to-start event's `xdm` block contained only `eventType` and not the required identity path, DCVS dropped the **entire** event — including the `data.liveActivityPushNotificationDetails` portion that would have written to the profile.

The standard push token path (`sendPushToken`) was never affected because it sends **only** a `data` key with no `xdm` block, so DCVS never evaluates it.

### Fix applied

Removed the `xdm` key from the push-to-start event, leaving only the `data` key — matching the pattern of `sendPushToken`:

```swift
// AFTER (fixed) — AEPMessaging/Sources/Messaging+EdgeEvents.swift
// Creating Edge event data with data payload only (no xdm key).
// Matches the pattern of sendPushToken — pure data events bypass DCVS validation
// so liveActivityPushNotificationDetails reaches the profile flow regardless of
// any DCVS descriptor issues on the EE dataset.
let eventData: [String: Any] = [
    MessagingConstants.XDM.Key.DATA: [
        MessagingConstants.XDM.LiveActivity.PUSH_NOTIFICATION_DETAILS: detailsArray
    ]
]
```

**File:** `AEPMessaging/Sources/Messaging+EdgeEvents.swift`

### Permanent fix for DCVS (separate track — manual UI steps)

The underlying descriptor issue must also be resolved so all Experience Events land correctly:

1. Remove event dataset `69fe4a56395ace540691d293` from the datastream
2. Delete the dataset
3. Delete identity descriptor `e21421f93949cf191d20e9cfcb4c42a2482bed05622bd102` in Schema Registry
4. Recreate the event dataset against the same schema
5. Re-add the dataset to the datastream

Once done, restore the `xdm` key in `Messaging+EdgeEvents.swift` (revert the change above).

---

## Root Cause 2 — Token de-duplication silencing re-sends

### What happened

Even after the DCVS workaround (Root Cause 1) was applied, the SDK was not re-sending tokens on subsequent launches. The AEP Messaging SDK de-duplicates push-to-start tokens: `handleBatchedPushToStartTokenEvent` checks the token against `MessagingStateManager.pushToStartTokenStore`; if the token is unchanged, `didChange = false` and no edge event is dispatched.

The token store is backed by `FileSystemNamedCollection` on iOS (confirmed in `Pods/AEPServices/AEPServices/Sources/ServiceProvider.swift`):

```swift
#if os(iOS)
    private var defaultKeyValueService = FileSystemNamedCollection()
```

Data is stored at:
```
Library/com.adobe.aep.datastore/com.adobe.messaging.json
```

Key: `liveActivity.pushToStartTokens`  
Collection: `com.adobe.messaging`

**Critical timing detail:** `MessagingStateManager` loads `pushToStartTokenStore` from disk **during extension initialisation**, which runs on background threads inside `MobileCore.registerExtensions()` — **before** the completion callback fires. Any cache-clear inside the completion callback arrives too late; the in-memory state has already been populated from disk.

Three failed attempts that all missed due to timing or wrong storage backend:

| Attempt | Code | Why it failed |
|---|---|---|
| 1 | `UserDefaults.standard.removeObject(forKey: "com.adobe.messaging.liveActivity.pushToStartTokens")` | iOS uses `FileSystemNamedCollection`, not `UserDefaults` |
| 2 | `UserDefaults.standard.removeObject(forKey: "Adobe.com.adobe.messaging.liveActivity.pushToStartTokens")` | Still wrong backing store |
| 3 | `NamedCollectionDataStore(...).remove(...)` inside `registerExtensions` completion | Correct API, wrong timing — SDK already loaded store into memory |

### Fix applied

Moved the cache-clear to **before** `MobileCore.registerExtensions()` in `AppDelegate.swift`:

```swift
// AFTER (fixed) — TestApps/MessagingDemoAppSwiftUI/AppDelegate.swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions ...) -> Bool {
    MobileCore.setLogLevel(.trace)

    // Clear the live activity push-to-start token cache BEFORE the SDK initializes.
    // MessagingStateManager loads pushToStartTokenStore from disk during extension
    // initialization (which runs on background threads inside registerExtensions,
    // BEFORE the completion callback fires). Clearing here guarantees the Messaging
    // extension sees a clean store and treats every token as new on this launch,
    // bypassing the SDK's de-duplication guard. FileSystemNamedCollection uses a
    // serial queue: the async remove() completes before any subsequent sync get()
    // during extension init. Remove this block once the DCVS descriptor is fixed.
    #if DEBUG
    if #available(iOS 16.1, *) {
        NamedCollectionDataStore(name: "com.adobe.messaging").remove(key: "liveActivity.pushToStartTokens")
    }
    #endif

    let extensions = [ ... ]
    MobileCore.registerExtensions(extensions) { ... }
}
```

`FileSystemNamedCollection` uses a serial `DispatchQueue`: `remove()` is `queue.async` and `get()` is `queue.sync`. Because they share the same serial queue, the async remove is guaranteed to complete before any subsequent sync read during extension init.

**File:** `TestApps/MessagingDemoAppSwiftUI/AppDelegate.swift`

---

## Outcome

After both fixes, the iPhone 15 profile (`47288941103661241645408602224153721911`) was fully populated on the next app launch:

```json
"liveActivityPushNotificationDetails": [
  { "attributeType": "AirplaneTrackingAttributes",          "platform": "apnsSandbox", "denylisted": false, ... },
  { "attributeType": "FoodDeliveryLiveActivityAttributes",  "platform": "apnsSandbox", "denylisted": false, ... },
  { "attributeType": "GameScoreLiveActivityAttributes",     "platform": "apnsSandbox", "denylisted": false, ... },
  { "attributeType": "EtihadPremiumFlightAttributes",       "platform": "apnsSandbox", "denylisted": false, ... },
  { "attributeType": "EtihadBoardingAttributes",            "platform": "apnsSandbox", "denylisted": false, ... },
  { "attributeType": "FlynasFlightAttributes",              "platform": "apnsSandbox", "denylisted": false, ... },
  { "attributeType": "KSIAAirportAttributes",               "platform": "apnsSandbox", "denylisted": false, ... },
  { "attributeType": "TravelLiveActivityAttributes",        "platform": "apnsSandbox", "denylisted": false, ... }
]
```

Assurance Live Activities panel also confirmed all fields populated (ECID, Sandbox, App ID, Platform, Denylisted, PushToStart Token).

---

## Cleanup checklist (once DCVS descriptor is fixed)

- [ ] Revert `xdm` key removal in `AEPMessaging/Sources/Messaging+EdgeEvents.swift`
- [ ] Remove `#if DEBUG` token-store cache-clear block from `AppDelegate.swift`
- [ ] Verify `liveActivityPushNotificationDetails` still lands in profile after revert
- [ ] Verify Assurance Live Activities panel still shows all fields
- [ ] Complete DCVS manual fix (delete descriptor, recreate dataset — see Root Cause 1 above)

---

## How to avoid this in future

1. **Test push-to-start token flow on a fresh ECID** — token de-duplication means a device that has already registered will silently skip re-sends. Use `resetIdentities()` or a fresh simulator/device to validate end-to-end.

2. **Check DCVS before blaming the SDK** — if `liveActivityPushNotificationDetails` is missing but `pushNotificationDetails` is present, suspect DCVS. The two paths differ only in that live activity uses `xdm`+`data` while standard push uses `data` only. A DCVS-1106-400 error in the edge event dataset is the tell.

3. **Confirm the correct storage backend before clearing SDK state** — on iOS the AEP SDK uses `FileSystemNamedCollection` (not `UserDefaults`). Always use `NamedCollectionDataStore` to manipulate SDK-managed state.

4. **Timing: clear SDK disk state before `registerExtensions`** — any state that `MessagingStateManager` or other extensions load from disk during initialisation must be cleared before `registerExtensions` is called, not inside the completion callback.

5. **Use the AEP Profile API to confirm writes, not just Assurance** — Assurance reads SDK-reported events; the Profile API reads the actual merged profile. Both should agree but diverge when the event shape changes (e.g. removing `xdm` affects Assurance display but not the profile write).
