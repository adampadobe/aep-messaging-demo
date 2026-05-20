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

import AEPEdge
import AEPEdgeIdentity
import SwiftUI

/// Mock hotel WiFi captive-portal login screen.
///
/// ## Use Case 1 — Whitbread / Premier Inn
/// Guest arrives at property, connects to hotel WiFi. This screen simulates
/// the captive portal registration. On "Connect" it fires a `hotel.wifi.logon`
/// Edge event routed to the dedicated WiFi datastream
/// (`e2715e6c-3d55-4a4b-b6b0-344a14b5c7a4`) with the email address, ECID,
/// and channel=mobile.
///
/// AJO can then:
/// 1. Identify the guest via identity stitching (email → profile)
/// 2. Evaluate segment membership (frequent stayer, no imminent restaurant booking)
/// 3. Deliver a personalised in-app or push message with a promo code
struct HotelWifiView: View {

    // MARK: - Constants

    private static let wifiDatastream = "e2715e6c-3d55-4a4b-b6b0-344a14b5c7a4"

    // MARK: - State

    @EnvironmentObject private var identityManager: IdentityManager
    @StateObject          private var iconManager   = IconManager.shared

    @State private var emailInput: String   = ""
    @State private var isConnecting         = false
    @State private var isConnected          = false
    @State private var promoCode: String    = ""
    @State private var showUseCaseInfo      = false
    @State private var termsAccepted        = false

    // Pre-fill from IdentityManager if already logged in
    private var effectiveEmail: String {
        emailInput.isEmpty ? (identityManager.loggedInEmail ?? "") : emailInput
    }

    private var canConnect: Bool {
        !effectiveEmail.trimmingCharacters(in: .whitespaces).isEmpty
            && effectiveEmail.contains("@")
            && termsAccepted
            && !isConnecting
            && !isConnected
    }

    private var brand: BrandIcon { iconManager.current }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    portalHeader
                    if isConnected {
                        connectedState
                    } else {
                        loginForm
                    }
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Guest WiFi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showUseCaseInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
            .sheet(isPresented: $showUseCaseInfo) {
                UseCaseInfoSheet()
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            // Pre-fill email from IdentityManager
            if let loggedIn = identityManager.loggedInEmail, emailInput.isEmpty {
                emailInput = loggedIn
            }
        }
    }

    // MARK: - Portal header

    private var portalHeader: some View {
        ZStack {
            brand.brandColor
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 12) {
                Image(systemName: "wifi")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(.white)

                Text("\(brand.displayName) Guest WiFi")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text("Sign in to access complimentary WiFi")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.vertical, 32)
        }
    }

    // MARK: - Login form

    private var loginForm: some View {
        VStack(spacing: 0) {
            // Network info card
            HStack(spacing: 12) {
                Image(systemName: "wifi.circle.fill")
                    .font(.title2)
                    .foregroundColor(brand.brandColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(brand.displayName.replacingOccurrences(of: " ", with: ""))-GuestWiFi")
                        .font(.headline)
                    Text("Complimentary high-speed internet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "lock.open.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 16)
            .padding(.top, 20)

            // Email field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email Address")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)

                TextField("your@email.com", text: $emailInput)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
            }
            .padding(.top, 24)

            // Terms toggle
            Toggle(isOn: $termsAccepted) {
                Text("I agree to the [Guest WiFi Terms & Conditions](https://example.com) and consent to my session data being used to personalise my stay experience.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .toggleStyle(.checkmark)
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // Connect button
            Button {
                connect()
            } label: {
                ZStack {
                    if isConnecting {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Label("Connect to WiFi", systemImage: "wifi")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(canConnect ? brand.brandColor : Color(.systemGray4))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(!canConnect)
            .padding(.horizontal, 16)
            .padding(.top, 20)

            // AEP attribution
            Text("Identity powered by Adobe Experience Platform")
                .font(.caption2)
                .foregroundColor(Color(.systemGray3))
                .padding(.top, 12)
        }
    }

    // MARK: - Connected state

    private var connectedState: some View {
        VStack(spacing: 20) {
            // Success banner
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundColor(.green)

                Text("You're Connected!")
                    .font(.title2.bold())

                Text("Welcome to \(brand.displayName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 32)

            // Personalised offer card
            VStack(alignment: .leading, spacing: 14) {
                Label("Your Exclusive Offer", systemImage: "gift.fill")
                    .font(.headline)
                    .foregroundColor(brand.brandColor)

                Divider()

                Text("As a valued frequent stayer, enjoy a **free starter** at our restaurant this evening.")
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Promo Code")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(promoCode)
                            .font(.system(.title3, design: .monospaced).bold())
                            .foregroundColor(brand.brandColor)
                    }
                    Spacer()
                    Button {
                        UIPasteboard.general.string = promoCode
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.caption.weight(.medium))
                    }
                    .buttonStyle(.bordered)
                    .tint(brand.brandColor)
                }
                .padding(.top, 4)

                Divider()

                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("This offer was triggered by your WiFi logon event in Adobe Journey Optimizer.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 2)
            .padding(.horizontal, 16)

            // Sent event summary
            VStack(alignment: .leading, spacing: 8) {
                Label("Edge Event Sent", systemImage: "arrow.up.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)

                Group {
                    eventRow(key: "eventType",  value: "hotel.wifi.logon")
                    eventRow(key: "channel",    value: "mobile")
                    eventRow(key: "datastream", value: "e2715e6c…4c7a4")
                    eventRow(key: "identity",   value: effectiveEmail)
                }
            }
            .padding(14)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal, 16)

            // Disconnect
            Button("Disconnect", role: .destructive) {
                withAnimation { isConnected = false }
            }
            .font(.subheadline)
            .padding(.top, 4)
        }
    }

    private func eventRow(key: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(key)
                .font(.caption.monospaced())
                .foregroundColor(.secondary)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(.caption.monospaced())
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Connect action

    private func connect() {
        let email = effectiveEmail.trimmingCharacters(in: .whitespaces)
        guard !email.isEmpty else { return }

        isConnecting = true

        // Retrieve live ECID then fire the WiFi logon event
        AEPEdgeIdentity.Identity.getIdentities { identityMap, _ in
            let ecid = identityMap?.getItems(withNamespace: "ECID")?.first?.id

            var xdm: [String: Any] = [
                "eventType": "hotel.wifi.logon",
                "channel":   "mobile"
            ]

            // Build identityMap with Email + ECID
            let imEmail: [String: Any] = [
                "id": email,
                "authenticatedState": "authenticated",
                "primary": false
            ]
            var identityMapXdm: [String: Any] = ["Email": [imEmail]]
            if let ecid = ecid {
                identityMapXdm["ECID"] = [["id": ecid, "authenticatedState": "ambiguous", "primary": true]]
            }
            xdm["identityMap"] = identityMapXdm

            // Send to the dedicated WiFi datastream
            let event = ExperienceEvent(
                xdm: xdm,
                datastreamIdOverride: HotelWifiView.wifiDatastream
            )
            Edge.sendEvent(experienceEvent: event)

            // Generate a mock promo code for the demo
            let code = "WB-" + String((0..<6).map { _ in "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".randomElement()! })

            DispatchQueue.main.async {
                promoCode    = code
                isConnecting = false
                withAnimation { isConnected = true }
            }
        }
    }
}

// MARK: - Checkmark toggle style

private struct CheckmarkToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? .accentColor : .secondary)
                    .font(.body)
                configuration.label
            }
        }
        .buttonStyle(.plain)
    }
}

extension ToggleStyle where Self == CheckmarkToggleStyle {
    static var checkmark: CheckmarkToggleStyle { CheckmarkToggleStyle() }
}

// MARK: - Use Case info sheet

private struct UseCaseInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("**Use Case 1 — Hotel WiFi Identity Stitching**")
                        .font(.headline)

                    Text("A guest books directly for a property. When they connect to hotel WiFi on arrival, they are prompted to enter their email. The platform recognises them as a frequent booker & stayer, based on booking data + historic Wi-Fi registrations.")

                    Text("**What this page demonstrates:**")
                        .font(.subheadline.weight(.semibold))

                    VStack(alignment: .leading, spacing: 8) {
                        bulletPoint("Real-time capture of Wi-Fi registration via `hotel.wifi.logon` Edge event")
                        bulletPoint("Identity stitching — email supplied during Wi-Fi login is linked to the ECID already on device, merging mobile + web profiles")
                        bulletPoint("Event routed to a dedicated WiFi datastream (`e2715e6c…`) separate from the main app datastream")
                        bulletPoint("Channel set to `mobile` so AJO journey conditions can differentiate from web WiFi logins")
                        bulletPoint("AJO evaluates segment membership (frequent stayer, no imminent restaurant booking) and issues a single-use promo code via in-app message")
                    }

                    Text("**Requirements from RFP delivered here:**")
                        .font(.subheadline.weight(.semibold))

                    VStack(alignment: .leading, spacing: 8) {
                        bulletPoint("✅ Real-time capture of Wi-Fi registration")
                        bulletPoint("✅ Dynamic recognition of customer from email supplied during Wi-Fi registration")
                        bulletPoint("✅ Identity stitching to determine customer has booked directly")
                        bulletPoint("✅ Delivery of personalised content via in-app message (triggered by AJO journey)")
                        bulletPoint("✅ Appropriate measure of campaign performance across all channels")
                    }

                    Divider()

                    Text("The promo code shown above is a mock — in production it would be delivered by AJO as an in-app or push message after the journey evaluates the profile.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(20)
            }
            .navigationTitle("About This Demo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•").foregroundColor(.secondary)
            Text(LocalizedStringKey(text)).font(.subheadline)
        }
    }
}

// MARK: - Preview

struct HotelWifiView_Previews: PreviewProvider {
    static var previews: some View {
        HotelWifiView()
            .environmentObject(IdentityManager.shared)
    }
}
