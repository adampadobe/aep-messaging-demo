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

import AEPCore
import AEPEdge
import AEPEdgeIdentity
import Foundation

/// Single source of truth for authenticated identity state.
///
/// Both `WelcomeView` (first-launch gate) and `SettingsView` (in-session
/// login/logout) delegate here so there is no duplicated logic.
///
/// ## Identity stitching approach
/// On login we mirror the web AEP Orchestration Lab demo pattern:
/// 1. Call `AEPEdgeIdentity.Identity.getIdentities` to read the live ECID.
/// 2. Send one Edge event that contains **both** ECID (primary) and Email
///    (secondary) in the `identityMap`, so AEP links them atomically.
/// 3. Use a brand-specific `eventType` (`BrandIcon.stitchEventType`) so AJO
///    journeys triggered by the web lab also fire for mobile logins.
@MainActor
final class IdentityManager: ObservableObject {

    static let shared = IdentityManager()

    private static let emailKey = "loggedInEmail"
    private static let guestKey = "welcomeSkipped"

    /// The authenticated email, or `nil` when no user is logged in.
    @Published private(set) var loggedInEmail: String?

    /// `true` once the user has completed the welcome screen — either by
    /// logging in or tapping "Continue as guest". Drives the root navigation
    /// gate in `MessagingDemoAppSwiftUIApp`.
    @Published private(set) var isWelcomeComplete: Bool

    /// `true` while a login request is in-flight (waiting for ECID callback).
    @Published private(set) var isLoggingIn = false

    private init() {
        let stored = UserDefaults.standard.string(forKey: Self.emailKey) ?? ""
        let email  = stored.isEmpty ? nil : stored
        self.loggedInEmail    = email
        self.isWelcomeComplete = email != nil
                              || UserDefaults.standard.bool(forKey: Self.guestKey)
    }

    // MARK: - Public API

    /// Link `email` to the device ECID and fire a brand-specific stitch event.
    func logIn(email: String, brand: BrandIcon) {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isLoggingIn = true

        // 1. Persist the Email identity in the SDK's local identity store so
        //    every subsequent Edge event carries it automatically.
        let emailItem = IdentityItem(id: trimmed, authenticatedState: .authenticated, primary: false)
        let map = IdentityMap()
        map.add(item: emailItem, withNamespace: "Email")
        AEPEdgeIdentity.Identity.updateIdentities(with: map)

        // 2. Read the live ECID, then send an explicit stitch event that
        //    includes both ECID (primary) and Email (secondary) in one payload.
        //    This mirrors the web demo's `alloy('sendEvent', { xdm: { identityMap: … } })`.
        AEPEdgeIdentity.Identity.getIdentities { [weak self] identityMap, _ in
            let ecid = identityMap?.getItems(withNamespace: "ECID")?.first?.id

            var xdm: [String: Any] = [
                "eventType": brand.stitchEventType,
                // Explicit mobile channel so the web events table shows "mobile" source.
                "channel": [
                    "_id": "https://ns.adobe.com/xdm/channels/mobile",
                    "typeAtSource": "mobile"
                ],
                // Brand carried as application context rather than encoded in the event type.
                "application": [
                    "name": "AEP Messaging Demo",
                    "id":   brand.rawValue
                ]
            ]
            if let ecid = ecid {
                xdm["identityMap"] = [
                    "ECID":  [["id": ecid,    "authenticatedState": "authenticated", "primary": true]],
                    "Email": [["id": trimmed, "authenticatedState": "authenticated", "primary": false]]
                ]
            }

            Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: xdm))

            // 3. EdgeBridge track so the event also lands in Analytics.
            MobileCore.track(action: "login", data: ["email": trimmed, "brand": brand.rawValue])

            // 4. Persist and update UI state on the main thread.
            UserDefaults.standard.set(trimmed, forKey: Self.emailKey)
            DispatchQueue.main.async { [weak self] in
                self?.loggedInEmail    = trimmed
                self?.isWelcomeComplete = true
                self?.isLoggingIn      = false
            }
        }
    }

    /// Remove the authenticated Email identity and fire a logout event.
    /// Also clears the guest flag so the welcome screen reappears on next cold launch.
    func logOut() {
        guard let email = loggedInEmail else { return }

        let emailItem = IdentityItem(id: email, authenticatedState: .authenticated, primary: false)
        AEPEdgeIdentity.Identity.removeIdentity(item: emailItem, withNamespace: "Email")

        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["eventType": "user.logout"]))
        MobileCore.track(action: "logout", data: nil)

        UserDefaults.standard.removeObject(forKey: Self.emailKey)
        UserDefaults.standard.removeObject(forKey: Self.guestKey)
        loggedInEmail     = nil
        isWelcomeComplete = false
    }

    /// Skip authentication — proceed to the app as a guest.
    /// The welcome screen won't reappear until `logOut()` is called.
    func continueAsGuest() {
        UserDefaults.standard.set(true, forKey: Self.guestKey)
        isWelcomeComplete = true
    }
}
