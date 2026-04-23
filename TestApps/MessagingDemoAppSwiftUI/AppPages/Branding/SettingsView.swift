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

/// Settings tab. Today: brand icon picker. Built so additional sections
/// (theme, sample data, etc.) can be appended later.
struct SettingsView: View {

    @StateObject private var iconManager = IconManager.shared

    var body: some View {
        NavigationView {
            Form {
                Section {
                    ForEach(BrandIcon.allCases) { brand in
                        BrandRow(
                            brand: brand,
                            isSelected: iconManager.current == brand,
                            isSwapping: iconManager.isSwapping
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            iconManager.select(brand)
                        }
                    }
                } header: {
                    Text("App Icon")
                } footer: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Picks the home-screen icon and the in-app brand splash so this build matches the customer you're presenting to.")
                        if !iconManager.supportsAlternateIcons {
                            Text("This device doesn't support alternate icons.")
                                .foregroundColor(.orange)
                        }
                        if let err = iconManager.lastError {
                            Text(err).foregroundColor(.red)
                        }
                        Text("iOS shows a one-time confirmation alert the first time the icon changes.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .navigationViewStyle(.stack)
    }
}

private struct BrandRow: View {
    let brand: BrandIcon
    let isSelected: Bool
    let isSwapping: Bool

    var body: some View {
        HStack(spacing: 12) {
            BrandIconThumbnail(brand: brand)
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(brand.displayName)
                    .font(.body)
                if isSelected {
                    Text("Active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if isSelected {
                if isSwapping {
                    ProgressView()
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            } else if isSwapping {
                Color.clear.frame(width: 1, height: 1)
            }
        }
        .padding(.vertical, 4)
        .opacity(isSwapping && !isSelected ? 0.6 : 1)
        .disabled(isSwapping)
    }
}

/// Loads a preview thumbnail for the icon. Tries the alternate icon's
/// bundle PNG first, then falls back to the primary AppIcon asset, then
/// to a colored placeholder using the brand's first letter so the picker
/// stays useful even before the presenter has supplied real artwork.
struct BrandIconThumbnail: View {
    let brand: BrandIcon

    var body: some View {
        if let image = loadedImage() {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else {
            placeholder
        }
    }

    private func loadedImage() -> UIImage? {
        // Default brand → use the primary app icon if Xcode generated one.
        if brand == .default, let primary = UIImage(named: "AppIcon") {
            return primary
        }
        guard let assetName = brand.previewAssetName else { return nil }
        // iOS resolves @2x/@3x suffixes automatically when given the base name.
        return UIImage(named: assetName)
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(placeholderColor)
            Text(initial)
                .font(.headline.bold())
                .foregroundColor(.white)
        }
    }

    private var initial: String {
        String(brand.displayName.prefix(1)).uppercased()
    }

    private var placeholderColor: Color {
        switch brand {
        case .default: return Color(red: 0.93, green: 0.0, blue: 0.0)
        case .etihad:  return Color(red: 0.78, green: 0.55, blue: 0.20)
        case .ksia:    return Color(red: 0.05, green: 0.32, blue: 0.20)
        case .flynas:  return Color(red: 0.96, green: 0.62, blue: 0.04)
        case .travel:  return Color(red: 0.06, green: 0.49, blue: 0.28)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
