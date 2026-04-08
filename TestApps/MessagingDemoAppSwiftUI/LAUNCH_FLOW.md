# MessagingDemoAppSwiftUI – Launch flow and why it starts (simulator / device)

This doc describes the app’s startup sequence and the changes that allow it to start reliably in the iPhone 17 simulator (and aim to fix hangs on physical device).

---

## 1. Launch sequence (high level)

1. **`didFinishLaunchingWithOptions`** runs (AppDelegate).
   - Sets log level.
   - **Does not** call `MobileCore.registerExtensions` directly.
   - Schedules **one** `DispatchQueue.main.async { ... }` that will call `registerExtensions` and its completion.
   - Returns `true` immediately → UIKit/SwiftUI can show the window and first frame.

2. **First run loop**
   - Window appears, SwiftUI renders **HomeView** (tab bar: InApp, Push, Code Experiences, Cards, Live Activity).
   - No AEP SDK work has run yet on the main thread, so nothing can block this first paint.

3. **Next run loop (main thread)**
   - The deferred block runs: `MobileCore.registerExtensions(extensions) { ... }`.
   - Extensions register (Identity, Lifecycle, Signal, Edge, Messaging, Assurance, TokenCollector).
   - When the **completion** runs, it’s again dispatched to main: `DispatchQueue.main.async { configureWith(...); updatePropositionsForSurfaces(...); registerForPushNotifications(...) }`.
   - **No** `Messaging.registerLiveActivities` at launch; that was moved off the launch path.

4. **Scene phase `.active`**
   - `MessagingDemoAppSwiftUIApp`’s `onChange(of: scenePhase)` runs.
   - For `.active`, we do **not** call `MobileCore.lifecycleStart` directly.
   - We schedule it: `DispatchQueue.main.async { MobileCore.lifecycleStart(additionalContextData: nil) }`.
   - So the transition to active doesn’t block the main thread.

5. **Live Activities**
   - `Messaging.registerLiveActivities([...])` is **not** called in AppDelegate.
   - It runs only when the user opens the **Live Activity** tab, in `LiveActivityView.onAppear`, via `registerLiveActivitiesIfNeeded()` (once per app launch).
   - So ActivityKit and Live Activity registration never run at launch → avoids the device hang/SIGABRT that occurred when this ran during startup.

---

## 2. Why it starts in the iPhone 17 simulator

- **Deferred SDK registration**  
  The first frame is drawn before any AEP work runs. The simulator doesn’t block on that first frame, so the UI appears and then the SDK initializes on the next run loop.

- **Deferred `lifecycleStart`**  
  When the scene becomes active, we don’t block the main thread; we defer `lifecycleStart` to the next run loop. The simulator shows the UI and then lifecycle runs.

- **No Live Activity at launch**  
  We don’t call `registerLiveActivities` in AppDelegate. So at launch there’s no ActivityKit usage, no risk of the “missing weak symbol” / SIGABRT that showed on device, and no heavy work that could hang. In the simulator, the app simply shows the tab bar and other tabs; when you open the Live Activity tab, registration runs once and that tab works.

- **Same binary, same flow**  
  The same build and the same launch flow are used for both simulator and device. The simulator tends to be more forgiving of timing and doesn’t hit the same device-only issues (e.g. debug dylib / ActivityKit on device), so it starts reliably. The same design (defer everything heavy, no Live Activity at launch) is what we rely on for device as well.

---

## 3. Files involved

| File | Role |
|------|------|
| `AppDelegate.swift` | Defers `registerExtensions` to `main.async`; completion runs config and surfaces on main; no `registerLiveActivities` here. |
| `MessagingDemoAppSwiftUIApp.swift` | Defers `lifecycleStart` in `onChange(of: scenePhase)` when phase is `.active`. |
| `LiveActivityView.swift` | Calls `registerLiveActivitiesIfNeeded()` in `onAppear` so Live Activities register only when the user opens that tab (once per launch). |

---

## 4. Scheme / build

- **Thread Sanitizer** is off for the Run action (`enableThreadSanitizer = "NO"` in the scheme). That avoids the simulator/device pause that TSan can cause.
- **App icon** is a valid 1024×1024 PNG in `AppIcon.appiconset` so the asset catalog build succeeds.

Together, this launch flow and build setup are why the app starts in the iPhone 17 simulator and are intended to give the best chance of a clean start on device as well.
