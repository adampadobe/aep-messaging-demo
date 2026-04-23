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

/// Brand splash shown for ~1.2s every cold launch on top of `HomeView`.
///
/// Why this exists: iOS only shows the static `UILaunchScreen` *before* the
/// app process starts and that screen cannot be swapped at runtime per
/// presenter choice. This view bridges that gap by rendering an in-app
/// splash that mirrors the user-selected brand icon, so the moment after
/// launch matches the customer being demoed to.
struct BrandSplashView: View {

    let brand: BrandIcon
    let onComplete: () -> Void

    /// How long the splash stays visible before fading out.
    private let visibleDuration: TimeInterval = 1.0
    private let fadeDuration: TimeInterval = 0.35

    @State private var opacity: Double = 1.0

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 16) {
                BrandIconThumbnail(brand: brand)
                    .frame(width: 96, height: 96)
                    .shadow(radius: 6)
                Text(brand.displayName)
                    .font(.headline)
                    .foregroundColor(foregroundColor)
            }
        }
        .opacity(opacity)
        .onAppear { scheduleDismiss() }
    }

    private func scheduleDismiss() {
        DispatchQueue.main.asyncAfter(deadline: .now() + visibleDuration) {
            withAnimation(.easeOut(duration: fadeDuration)) {
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration) {
                onComplete()
            }
        }
    }

    /// Brand-aligned background. Mirrors the placeholder palette in
    /// `BrandIconThumbnail` so the splash still looks intentional even
    /// before real artwork is dropped in.
    private var backgroundColor: Color {
        switch brand {
        case .default: return Color.white
        case .etihad:  return Color(red: 0.78, green: 0.55, blue: 0.20)
        case .ksia:    return Color(red: 0.05, green: 0.32, blue: 0.20)
        case .flynas:  return Color(red: 0.96, green: 0.62, blue: 0.04)
        case .travel:  return Color(red: 0.06, green: 0.49, blue: 0.28)
        }
    }

    private var foregroundColor: Color {
        brand == .default ? .primary : .white
    }
}

struct BrandSplashView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BrandSplashView(brand: .default,  onComplete: {})
            BrandSplashView(brand: .etihad,   onComplete: {})
            BrandSplashView(brand: .ksia,     onComplete: {})
            BrandSplashView(brand: .flynas,   onComplete: {})
            BrandSplashView(brand: .travel,   onComplete: {})
        }
    }
}
