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

/// First screen shown when the user has not yet authenticated (or has logged out).
///
/// Provides "Create Account", "Sign In", and "Continue as guest" paths.
/// All auth paths delegate to `IdentityManager` which stitches the email to
/// the device ECID via a brand-specific Edge XDM event, mirroring the web
/// AEP Orchestration Lab demo login flow.
struct WelcomeView: View {

    @EnvironmentObject private var identityManager: IdentityManager
    @StateObject          private var iconManager   = IconManager.shared

    @State private var showEmailSheet = false
    @State private var isCreateMode   = true

    private var brand: BrandIcon { iconManager.current }

    // MARK: - Body

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                Spacer()
                hero
                Spacer()
                Spacer()
                ctaStack
                Spacer().frame(height: 52)
            }
        }
        .sheet(isPresented: $showEmailSheet) {
            EmailLoginSheet(isCreateMode: isCreateMode, brand: brand) { email in
                identityManager.logIn(email: email, brand: brand)
            }
            .environmentObject(identityManager)
        }
    }

    // MARK: - Subviews

    private var background: some View {
        LinearGradient(
            colors: [brand.brandColor, brand.brandColor.opacity(0.55)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var hero: some View {
        VStack(spacing: 20) {
            BrandIconThumbnail(brand: brand)
                .frame(width: 100, height: 100)
                .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 8)

            Text(brand.displayName)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Powered by Adobe Experience Platform")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var ctaStack: some View {
        VStack(spacing: 12) {
            // Primary — Create Account
            Button {
                isCreateMode = true
                showEmailSheet = true
            } label: {
                Label("Create Account", systemImage: "person.badge.plus")
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(.white)
                    .foregroundColor(brand.brandColor)
                    .fontWeight(.semibold)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            // Secondary — Sign In
            Button {
                isCreateMode = false
                showEmailSheet = true
            } label: {
                Label("Sign In", systemImage: "envelope")
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(.white.opacity(0.15))
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(.white.opacity(0.4), lineWidth: 1)
                    )
            }

            // Tertiary — Guest
            Button("Continue as guest") {
                identityManager.continueAsGuest()
            }
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.65))
            .padding(.top, 6)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Email login sheet

/// Slide-up form for entering an email address. Reused by both "Create Account"
/// and "Sign In" flows — only the copy changes.
private struct EmailLoginSheet: View {

    let isCreateMode: Bool
    let brand: BrandIcon
    let onSubmit: (String) -> Void

    @EnvironmentObject private var identityManager: IdentityManager
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @FocusState private var emailFocused: Bool

    private var title:       String { isCreateMode ? "Create Account" : "Sign In" }
    private var buttonLabel: String { isCreateMode ? "Create Account" : "Sign In" }

    private var isValid: Bool {
        let t = email.trimmingCharacters(in: .whitespaces)
        return t.contains("@") && t.count > 4
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Email address", text: $email)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($emailFocused)
                } header: {
                    Text("Your email")
                } footer: {
                    Text("Your email links this device to your \(brand.displayName) profile in Adobe Experience Platform, enabling personalised experiences.")
                }

                Section {
                    Button {
                        onSubmit(email.trimmingCharacters(in: .whitespaces))
                        dismiss()
                    } label: {
                        if identityManager.isLoggingIn {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Text(buttonLabel)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isValid || identityManager.isLoggingIn)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear { emailFocused = true }
    }
}

// MARK: - Preview

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
            .environmentObject(IdentityManager.shared)
    }
}
