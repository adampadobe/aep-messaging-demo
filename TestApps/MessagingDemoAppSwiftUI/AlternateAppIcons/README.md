# Alternate App Icons

Drop PNG files in this folder to enable the brand icon picker in the
Settings tab. iOS resolves loose-PNG alternate icons from the **app bundle
root**, so all files in this folder are added to "Copy Bundle Resources"
on the `MessagingDemoAppSwiftUI` target via a folder reference in the
Xcode project — meaning **anything you drop here is automatically
bundled**, no Xcode editing required.

## Required file names

For each brand the picker needs **two** PNGs (60pt iPhone @2x and @3x).
iPad is optional but recommended (76pt @2x = 152, plus 83.5pt @2x = 167).

| Brand   | Required (iPhone)                                  | Optional (iPad)                                               |
|---------|----------------------------------------------------|---------------------------------------------------------------|
| Etihad  | `AppIcon-Etihad@2x.png` (120×120)<br>`AppIcon-Etihad@3x.png` (180×180) | `AppIcon-Etihad@2x~ipad.png` (152×152)<br>`AppIcon-Etihad~ipadpro.png` (167×167) |
| KSIA    | `AppIcon-KSIA@2x.png` (120×120)<br>`AppIcon-KSIA@3x.png` (180×180)     | `AppIcon-KSIA@2x~ipad.png` (152×152)<br>`AppIcon-KSIA~ipadpro.png` (167×167)     |
| Flynas  | `AppIcon-Flynas@2x.png` (120×120)<br>`AppIcon-Flynas@3x.png` (180×180) | `AppIcon-Flynas@2x~ipad.png` (152×152)<br>`AppIcon-Flynas~ipadpro.png` (167×167) |
| Travel  | `AppIcon-Travel@2x.png` (120×120)<br>`AppIcon-Travel@3x.png` (180×180) | `AppIcon-Travel@2x~ipad.png` (152×152)<br>`AppIcon-Travel~ipadpro.png` (167×167) |

## Image rules

- Square, no transparency, no rounded corners (iOS rounds them for you)
- sRGB color space, 8-bit
- Flat PNG (not interlaced)
- Keep important content inside a centered ~80% square — iOS may mask the corners

## Adding a new brand

1. Add a case to `BrandIcon` in
   `TestApps/MessagingDemoAppSwiftUI/AppPages/Branding/IconManager.swift`
   (set `iconName`, `previewAssetName`, `displayName`).
2. Add a `<key>AppIcon-<Name></key>...` block under
   `CFBundleAlternateIcons` (and `CFBundleIcons~ipad → CFBundleAlternateIcons`)
   in `MessagingDemoAppSwiftUI-Info.plist`.
3. Drop the two `@2x` / `@3x` PNGs in this folder using the same
   `AppIcon-<Name>` base name.

## Default (Adobe) icon

The `Adobe (default)` choice in the picker uses the primary `AppIcon`
asset already in `TestApps/MessagingDemoAppSwiftUI/Assets.xcassets/AppIcon.appiconset/`.
No changes needed there — just make sure the asset has the standard set
of PNGs filled in (`Edit > Provide All Sizes` in Xcode).

## How the picker resolves preview thumbnails

`SettingsView` loads `UIImage(named:)` against the alt-icon base name
(e.g. `"AppIcon-Etihad"`). iOS auto-resolves the right `@2x` / `@3x`
file in the bundle. If no PNG is found, the picker falls back to a
colored tile with the brand's first letter so the row stays usable
during demo prep.
