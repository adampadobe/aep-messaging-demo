# Upstream verification: AJO Messaging Inbox on iOS

## Summary

Adobe’s **Messaging Inbox UI** (`Messaging.getInboxUI`, `InboxUI`, SwiftUI `view`) is present on **`adobe/aepsdk-messaging-ios` `main`** (merged via releases such as **5.13.x**). It lives under `AEPMessaging/Sources/UI/Inbox/` and is exposed from `Messaging+UIPublicAPI.swift`.

## How this was verified (repeatable)

From a clone with `upstream` remote pointing at `https://github.com/adobe/aepsdk-messaging-ios.git`:

```bash
git fetch upstream
git grep -n 'getInboxUI\|InboxUI' upstream/main -- '*.swift' | head
```

You should see hits in:

- `AEPMessaging/Sources/UI/Messaging+UIPublicAPI.swift` (`getInboxUI`)
- `AEPMessaging/Sources/UI/Inbox/InboxUI.swift`
- `TestApps/MessagingDemoAppSwiftUI/AppPages/InboxView.swift` (demo)

## Tags / CocoaPods / SPM

- GitHub **tags** (e.g. `5.13.0`, `5.13.1`) track release lines; confirm Inbox symbols exist on the tag you pin in **CocoaPods** or **SPM** by running the same `git grep` against that tag: `git grep … 5.13.0`.
- After dependency resolution, confirm in Xcode that `Messaging.getInboxUI` autocompletes for your resolved `AEPMessaging` version.

## Public documentation

- [Inbox UI (iOS)](https://developer.adobe.com/client-sdks/edge/adobe-journey-optimizer/inbox-ui/iOS/)
- [Fetch and Display Inbox](https://developer.adobe.com/client-sdks/edge/adobe-journey-optimizer/inbox-ui/iOS/tutorial/displaying-inbox/)

## Note on this fork

This repository’s git history is not a direct continuation of Adobe’s (unrelated root); SDK updates are applied by checking out **`upstream/main`** paths (e.g. `AEPMessaging/Sources`) and preserving demo customizations under `TestApps/`. See [FORK_MERGE_ZONES.md](FORK_MERGE_ZONES.md).
