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

/// Convenience wrappers for resolving the dynamic `Theme` payload coming from
/// AEP into actual `SwiftUI.Color` values. Lives in a separate file so it
/// can be shared between the app target and the widget extension target.
@available(iOS 16.1, *)
extension TravelLiveActivityAttributes.Theme {

    /// Background color for the Live Activity surface.
    var backgroundColor: Color {
        Color(hex: background) ?? Color.black
    }

    /// Accent color used for highlights, status pills, and progress indicators.
    var accentColor: Color {
        Color(hex: accent) ?? Color.orange
    }

    /// Foreground color for text drawn on top of `backgroundColor`.
    var foregroundColor: Color {
        if let hex = onBackground, let color = Color(hex: hex) {
            return color
        }
        return Color.white
    }
}

extension Color {

    /// Initializes a `Color` from a hex string. Supports `#RRGGBB`, `#AARRGGBB`,
    /// `RRGGBB`, and shorthand `#RGB` forms. Returns `nil` for invalid input.
    init?(hex raw: String) {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") { value.removeFirst() }

        // Expand shorthand "RGB" / "ARGB" to full form.
        if value.count == 3 {
            value = value.map { "\($0)\($0)" }.joined()
        }
        if value.count == 4 {
            value = value.map { "\($0)\($0)" }.joined()
        }

        guard value.count == 6 || value.count == 8 else { return nil }

        var hexValue: UInt64 = 0
        guard Scanner(string: value).scanHexInt64(&hexValue) else { return nil }

        let r, g, b, a: Double
        if value.count == 6 {
            r = Double((hexValue & 0xFF0000) >> 16) / 255.0
            g = Double((hexValue & 0x00FF00) >> 8) / 255.0
            b = Double(hexValue & 0x0000FF) / 255.0
            a = 1.0
        } else {
            a = Double((hexValue & 0xFF000000) >> 24) / 255.0
            r = Double((hexValue & 0x00FF0000) >> 16) / 255.0
            g = Double((hexValue & 0x0000FF00) >> 8) / 255.0
            b = Double(hexValue & 0x000000FF) / 255.0
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
