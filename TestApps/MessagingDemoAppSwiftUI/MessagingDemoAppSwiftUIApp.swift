/*
Copyright 2023 Adobe. All rights reserved.
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
import AEPCore

@main
struct MessagingDemoAppSwiftUIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var iconManager      = IconManager.shared
    @StateObject private var identityManager  = IdentityManager.shared
    @State private var showBrandSplash: Bool  = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Root navigation gate: show WelcomeView until the user logs in
                // or taps "Continue as guest", then switch to the main tab bar.
                if identityManager.isWelcomeComplete {
                    HomeView()
                        .environmentObject(identityManager)
                        .onOpenURL { url in
                            (UIApplication.shared.delegate as? AppDelegate)?.enqueueAssuranceDeepLink(url)
                        }
                } else {
                    WelcomeView()
                        .environmentObject(identityManager)
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }

                // Brand splash overlay — always on top for the first ~1.2s.
                if showBrandSplash {
                    BrandSplashView(brand: iconManager.current) {
                        showBrandSplash = false
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: identityManager.isWelcomeComplete)
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
                case .background:
                    print("Scene phase changed to background.")
                    MobileCore.lifecyclePause()
                case .active:
                    print("Scene phase changed to active.")
                    // Record that the scene is active. If extensions are already registered,
                    // call lifecycleStart immediately (background→foreground resume).
                    // If registration is still in progress (cold launch race), the
                    // registerExtensions callback will fire lifecycleStart once EdgeBridge
                    // is listening. This prevents EdgeBridge from missing the launch event.
                    delegate.sceneIsActive = true
                    if delegate.extensionsRegistered {
                        DispatchQueue.main.async {
                            MobileCore.lifecycleStart(additionalContextData: nil)
                        }
                    }
                case .inactive:
                    print("Scene phase changed to inactive.")
                @unknown default:
                    print("Unknown scene phase.")
            }
        }
    }
}
