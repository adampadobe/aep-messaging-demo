/*
Copyright 2025 Adobe. All rights reserved.
This file is licensed to you under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy
of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under
the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
OF ANY KIND, either express or implied. See the License for the specific language
governing permissions and limitations under the License.
*/

import SwiftUI
import UIKit


/// One brand the presenter can swap to at runtime. To add a new brand:
///   1. Add a case here.
///   2. Provide `iconName` (must match the key under
///      `CFBundleAlternateIcons` in `MessagingDemoAppSwiftUI-Info.plist`),
///      `previewAssetName` (the bundle file name iOS resolves at runtime —
///      same string), and a `displayName`.
///   3. Drop the matching PNGs into `AlternateAppIcons/` (see the README in
///      that folder for the required file names + sizes).
enum BrandIcon: String, CaseIterable, Identifiable, Hashable {
    // Default (Adobe)
    case `default`
    // Aviation / airports
    case etihad
    case ksia
    // Sports
    case claws
    case nfl
    case stormwings
    // Food & retail
    case hungry
    // Hospitality
    case premierInn

    var id: String { rawValue }

    /// The string passed to `UIApplication.setAlternateIconName(_:)`.
    /// `nil` for `.default` (which restores the primary icon).
    /// Must match a key under `CFBundleAlternateIcons` in Info.plist.
    var iconName: String? {
        switch self {
        case .default:    return nil
        case .etihad:     return "AppIcon-Etihad"
        case .ksia:       return "AppIcon-KSIA"
        case .claws:      return "AppIcon-Claws"
        case .nfl:        return "AppIcon-NFL"
        case .stormwings: return "AppIcon-Stormwings"
        case .hungry:     return "AppIcon-Hungry"
        case .premierInn: return "AppIcon-PremierInn"
        }
    }

    /// File name (without extension) iOS resolves to a 60pt @2x/@3x PNG in
    /// the bundle root. Used for both the home-screen icon swap AND the
    /// in-app preview / brand splash. Same value as `iconName`, broken out
    /// so future brands can use a separate preview asset if needed.
    var previewAssetName: String? { iconName }

    var displayName: String {
        switch self {
        case .default:    return "Adobe (default)"
        case .etihad:     return "Etihad"
        case .ksia:       return "KSIA"
        case .claws:      return "Claw & Order"
        case .nfl:        return "NFL"
        case .stormwings: return "Stormwings Eagles"
        case .hungry:     return "Hungry"
        case .premierInn: return "Premier Inn"
        }
    }

    /// Edge XDM `eventType` sent on login — standard `application.login` for all brands
    /// so AJO journeys can listen for a single event type. Channel (`mobile`) and
    /// brand are carried as separate XDM fields rather than encoded in the event type.
    var stitchEventType: String { "application.login" }

    /// Brand accent colour used in WelcomeView backgrounds and tints.
    var brandColor: Color {
        switch self {
        case .default:    return Color(red: 0.93, green: 0.0,  blue: 0.0)
        case .etihad:     return Color(red: 0.78, green: 0.55, blue: 0.20)
        case .ksia:       return Color(red: 0.05, green: 0.32, blue: 0.20)
        case .claws:      return Color(red: 0.18, green: 0.16, blue: 0.42)
        case .nfl:        return Color(red: 0.65, green: 0.12, blue: 0.10)
        case .stormwings: return Color(red: 0.10, green: 0.10, blue: 0.10)
        case .hungry:     return Color(red: 0.96, green: 0.75, blue: 0.04)  // Hungry yellow
        case .premierInn: return Color(red: 0.29, green: 0.12, blue: 0.51)  // Premier Inn purple #4B1F83
        }
    }
}

/// Single source of truth for the active brand icon. Swaps the iOS home-
/// screen icon via `UIApplication.setAlternateIconName(_:)` and persists
/// the selection so the in-app brand splash can read it.
@MainActor
final class IconManager: ObservableObject {

    static let shared = IconManager()

    private static let storageKey = "selectedBrandIconV1"

    /// Currently selected brand (drives both the home-screen icon and the
    /// in-app splash). UI binds to this via `@StateObject` / `@ObservedObject`.
    @Published private(set) var current: BrandIcon

    /// `true` while a swap is in flight (Apple's API is async; the system
    /// confirmation alert appears while this is true on iOS < 18).
    @Published private(set) var isSwapping = false

    /// Last error from `setAlternateIconName`, surfaced to the picker UI.
    @Published var lastError: String?

    private init() {
        let stored = UserDefaults.standard.string(forKey: Self.storageKey)
        let restored = stored.flatMap(BrandIcon.init(rawValue:)) ?? .default
        self.current = restored

        // If the persisted choice and the actual iOS-tracked alt icon name
        // disagree (e.g. user reset the app), fall back to whatever iOS
        // currently uses so the UI doesn't lie.
        let actual = UIApplication.shared.alternateIconName
        let actualBrand = BrandIcon.allCases.first(where: { $0.iconName == actual }) ?? .default
        if restored != actualBrand {
            self.current = actualBrand
            UserDefaults.standard.set(actualBrand.rawValue, forKey: Self.storageKey)
        }
    }

    /// Whether the device supports alternate icons (some configurations
    /// disable it; iPad multitasking previews etc.).
    var supportsAlternateIcons: Bool {
        UIApplication.shared.supportsAlternateIcons
    }

    /// Swap to `brand`. The system shows a one-time per-app confirmation
    /// alert ("App icon changed to..."). On success we persist the choice
    /// and update `current`.
    func select(_ brand: BrandIcon) {
        guard supportsAlternateIcons else {
            lastError = "Alternate icons are not supported on this device."
            return
        }
        guard brand != current else { return }

        isSwapping = true
        let target = brand.iconName
        let scale = UIScreen.main.scale
        NSLog("[IconManager] Switching to \(brand.rawValue) iconName=\(target ?? "nil") scale=\(scale)x supports=\(supportsAlternateIcons)")
        UIApplication.shared.setAlternateIconName(target) { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isSwapping = false
                if let error = error {
                    let msg = "Couldn't swap icon: \(error.localizedDescription) (code \((error as NSError).code))"
                    NSLog("[IconManager] ERROR: \(msg)")
                    self.lastError = msg
                    return
                }
                NSLog("[IconManager] Success — icon changed to \(brand.rawValue)")
                self.lastError = nil
                self.current = brand
                UserDefaults.standard.set(brand.rawValue, forKey: Self.storageKey)
            }
        }
    }
}
