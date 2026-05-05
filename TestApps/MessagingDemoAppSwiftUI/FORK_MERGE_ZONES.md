# Fork merge zones (do not bulk-overwrite)

When bringing in **`adobe/aepsdk-messaging-ios`** (`upstream/main` or a release tag), treat these areas as **fork-owned** unless you intend to replace them with Adobe’s demo:

| Area | Purpose |
|------|--------|
| [AppDelegate.swift](AppDelegate.swift) | Deferred `registerExtensions`, Assurance after `experienceCloud.org`, sandbox, `TokenCollector`, push delegate |
| [Constants.swift](Constants.swift) | Org `APPID`, Assurance URL, surface names (`INBOX`, cards, CBE) |
| [AppPages/Branding/](AppPages/Branding/) | Alternate app icons, splash, settings |
| [AppPages/LiveActivity/](AppPages/LiveActivity/) (extended) | Travel / airline demo attributes, pages, themes |
| [WidgetMessagingDemoAppSwiftUI/](WidgetMessagingDemoAppSwiftUI/) | Extra Live Activity extension targets |

## Safe merge surface (Adobe-owned)

Prefer taking upstream wholesale for:

- `AEPMessaging/Sources/` (SDK)
- `AEPMessagingLiveActivity/Sources/`
- `AEPMessagingNotification/` (if used)
- Upstream `Package.swift` / release-aligned **Podfile** constraints

## Xcode project overlay

Upstream `project.pbxproj` was merged first; fork-only file references were re-applied with [scripts/pbx_overlay_fork.py](../../scripts/pbx_overlay_fork.py) plus manual fixes for **PBXSourcesBuildPhase** / **PBXResourcesBuildPhase** IDs so every `… in Sources` entry matches a **PBXBuildFile** line.

After future SDK syncs, re-run verification: each new `.swift` under `AEPMessaging/Sources` must appear in the **AEPMessaging** target’s Sources build phase (or rely on SPM if the app consumes the package instead of the embedded framework target).
