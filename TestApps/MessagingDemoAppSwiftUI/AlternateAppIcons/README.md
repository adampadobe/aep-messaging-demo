# Alternate App Icons

Drop PNG files in this folder to enable the brand icon picker in the
Settings tab. iOS resolves loose-PNG alternate icons from the **app bundle
root**, so all files in this folder are added to "Copy Bundle Resources"
on the `MessagingDemoAppSwiftUI` target via a folder reference in the
Xcode project — meaning **anything you drop here is automatically
bundled**, no Xcode editing required.

## Current brands

| Brand            | Category      | @2x (120×120)              | @3x (180×180)              |
|------------------|---------------|----------------------------|----------------------------|
| Adobe (default)  | —             | `AppIcon` in asset catalog | —                          |
| Etihad           | Aviation      | `AppIcon-Etihad@2x.png`    | `AppIcon-Etihad@3x.png`    |
| KSIA             | Aviation      | `AppIcon-KSIA@2x.png`      | `AppIcon-KSIA@3x.png`      |
| Claw & Order     | Sports        | `AppIcon-Claws@2x.png`     | `AppIcon-Claws@3x.png`     |
| NFL              | Sports        | `AppIcon-NFL@2x.png`       | `AppIcon-NFL@3x.png`       |
| Stormwings Eagles| Sports        | `AppIcon-Stormwings@2x.png`| `AppIcon-Stormwings@3x.png`|
| Hungry           | Food/Retail   | `AppIcon-Hungry@2x.png`    | `AppIcon-Hungry@3x.png`    |
| Premier Inn      | Hospitality   | `AppIcon-PremierInn@2x.png`| `AppIcon-PremierInn@3x.png`|

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
3. Add a `placeholderColor` case to `BrandIconThumbnail` in `SettingsView.swift`.
4. Drop the two `@2x` / `@3x` PNGs in this folder using the same
   `AppIcon-<Name>` base name.

### Quick icon generation (from any source PNG)

```bash
# Replace <Name> and <source.png> — output goes straight into this folder
DEST="TestApps/MessagingDemoAppSwiftUI/AlternateAppIcons"
SRC="path/to/source.png"
NAME="MyBrand"  # must match iconName in BrandIcon enum

for SIZE in 120 180; do
  SCALE=$([[ $SIZE == 120 ]] && echo "2x" || echo "3x")
  ffmpeg -y -i "$SRC" \
    -vf "scale=${SIZE}:${SIZE}:force_original_aspect_ratio=decrease,pad=${SIZE}:${SIZE}:(ow-iw)/2:(oh-ih)/2:color=white" \
    -frames:v 1 "${DEST}/AppIcon-${NAME}@${SCALE}.png"
done
```

## Default (Adobe) icon

The `Adobe (default)` choice in the picker uses the primary `AppIcon`
asset in `TestApps/MessagingDemoAppSwiftUI/Assets.xcassets/AppIcon.appiconset/`.
The current default is the Adobe Government Forum 2026 icon (vibrant-gradient A).

## How the picker resolves preview thumbnails

`SettingsView` loads `UIImage(named:)` against the alt-icon base name
(e.g. `"AppIcon-Etihad"`). iOS auto-resolves the right `@2x` / `@3x`
file in the bundle. If no PNG is found, the picker falls back to a
colored tile with the brand's first letter so the row stays usable
during demo prep.
