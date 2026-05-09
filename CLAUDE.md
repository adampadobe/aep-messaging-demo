# CLAUDE.md — aepsdk-messaging-ios demo app

This file governs how Claude Code assists with the `MessagingDemoAppSwiftUI` demo app and
the AEP Messaging iOS SDK in this repo.

---

## Repo overview

- **SDK:** `AEPMessaging/Sources/` — the publishable AEP Messaging iOS SDK
- **Demo app:** `TestApps/MessagingDemoAppSwiftUI/` — SwiftUI demo app for testing SDK features
- **Workspace:** `AEPMessaging.xcworkspace` (always use workspace, never the bare `.xcodeproj`)
- **Scheme for demo app:** `MessagingDemoAppSwiftUI`

---

## Commit standard (always follow this)

After any code change — no matter how small — commit before moving on to the next task.

### Commit flow

1. `git status` to review what changed
2. Stage only the relevant files (`git add <file>...`) — never `git add -A` blindly
3. Write a commit message following [Conventional Commits](https://www.conventionalcommits.org/):
   - `feat(demo): ...` — new feature or capability in the demo app
   - `fix(demo): ...` — bug fix in the demo app
   - `feat(sdk): ...` — SDK change
   - `fix(sdk): ...` — SDK bug fix
   - `chore: ...` — build, config, dependency updates
   - `docs: ...` — documentation only
4. Include a `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>` trailer
5. After committing, push: `git push origin main`

### Commit message format

```
<type>(<scope>): <short summary under 72 chars>

- Bullet explaining why, not what (the diff shows what)
- Another bullet if needed

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

### What to always commit together

| Change | Also commit |
|---|---|
| New SDK feature | Unit test for the feature |
| Podfile change | Podfile.lock |
| `.xcodeproj` change | Only if it's intentional (e.g. adding a file) |
| `Constants.swift` change | Document why in commit body |
| New Live Activity type | Register it in `AppDelegate.swift` `Messaging.registerLiveActivities` |

---

## Device deployment

### Known devices

| Device | Role | UDID |
|---|---|---|
| Adam Dev iPhone (iPhone 15) | Primary test device | `227B97BD-AC99-592B-BEA0-68EF9DA0EA53` |
| Adam's Work iPhone (iPhone 17e) | Secondary test device | `6ABB0313-93E9-54D5-BD98-9C5FABCE48D5` |

### Build + install from CLI

```bash
xcodebuild \
  -workspace AEPMessaging.xcworkspace \
  -scheme MessagingDemoAppSwiftUI \
  -destination 'platform=iOS,id=<UDID>' \
  -configuration Debug \
  build install
```

If a new device gives "No profiles found" errors, open Xcode once with that device connected —
Xcode will register the device and regenerate provisioning profiles. Subsequent CLI builds will work.

---

## Key architecture decisions

### AEPEdgeBridge is required for lifecycle events

`EdgeBridge.self` must be in the extensions array so `MobileCore.lifecycleStart()` and
`MobileCore.track()` calls are forwarded to Edge as XDM events (`application.launch`, etc.).
Without it, lifecycle only populates SDK shared state and never reaches the AEP dataset.

### AEPCore/AEPServices pinned to adobe/main

Standard CocoaPods trunk may lag the latest Live Activity APIs. The Podfile pins:
```ruby
pod 'AEPCore', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'main'
pod 'AEPServices', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'main'
```

### Live Activity push-to-start token workaround

See `LIVE_ACTIVITY_PUSH_TO_START_DEBUG.md` for the full root cause analysis.
The `#if DEBUG` cache-clear block in `AppDelegate.swift` must stay until the DCVS descriptor
is fixed on the `apalmer` sandbox. Do not remove it prematurely.

### Surface name constants

All AJO surface paths are defined in `Constants.SurfaceName`. Always use these constants —
never hardcode surface strings inline.

| Constant | Value | Used for |
|---|---|---|
| `INBOX` | `"inbox"` | AJO Inbox / `getInboxUI()` |
| `CONTENT_CARD` | `"cardstab"` | Content Cards tab |
| `CBE_HTML` | `"cbehtml"` | Code-based HTML experience |
| `CBE_JSON` | `"cbejson"` | Code-based JSON experience |

---

## Surfaces and AJO channel configs

| Channel type | Channel config ID | Surface | Used for |
|---|---|---|---|
| `inbox` | `8208fa12-2fa4-4eb8-84e0-f78aa4d0f367` | Messaging-Inbox-Mobile | AJO Inbox messages |
| `messagefeed` | `4aa04f24-daa0-4dc9-aa97-851e1a48c95d` | cardstab | Classic Content Cards tab |

Content card campaigns targeting the AJO Inbox must use channel type `inbox` + the
Messaging-Inbox-Mobile config — **not** `messagefeed`.

---

## Sandbox: `apalmer`

- App bundle ID: `com.adampadobe.aep-messaging-demo`
- Dev iPhone ECID: `47288941103661241645408602224153721911`
- Work iPhone ECID: `72741576365611900757159622710055496241`
