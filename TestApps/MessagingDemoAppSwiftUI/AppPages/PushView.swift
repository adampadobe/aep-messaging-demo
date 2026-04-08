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
import AEPEdgeIdentity
import AEPCore

struct PushView: View {
    @State private var ECID: String?
    @State private var devicePushToken: String?
    @State private var showResetAlert = false
    @State private var isResetting = false

    var body: some View {
        VStack {
            TabHeader(title: "Push Notification")
            
            Spacer()
            
            InfoSection(title: "Experience Cloud ID", value: ECID ?? "Not Available") {
                UIPasteboard.general.string = ECID
            }
            
            Divider().frame(height: 30)
            
            InfoSection(title: "Push Token", value: devicePushToken ?? "Not Available") {
                UIPasteboard.general.string = devicePushToken
            }
            if let token = devicePushToken, token.hasPrefix("SIM_") {
                Text("Simulator placeholder – use a real device to receive push from AEP.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            Divider().frame(height: 30)
            
            // Reset Identity Button
            Button(action: {
                showResetAlert = true
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                    Text("Reset Identity & Get New ECID")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(isResetting)
            .alert("Reset Identity?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetIdentity()
                }
            } message: {
                Text("This will generate a new ECID and reset all identities. Push token will be re-registered automatically.")
            }
            
            if isResetting {
                ProgressView("Resetting identity...")
                    .padding()
            }
            
            Spacer()
        }
        .padding()
        .onAppear(perform: fetchInfo)
    }

    // Function to fetch ECID and Push Token
    private func fetchInfo() {
        Identity.getExperienceCloudId { (ecid, error) in
            if let error = error {
                ECID = "Error Reading ECID: \(error.localizedDescription)"
            } else {
                ECID = ecid
            }
        }
        
        // Retrieve the device push token from UserDefaults
        devicePushToken = UserDefaults.standard.string(forKey: "devicePushToken")
    }
    
    // Function to reset identity and generate new ECID
    private func resetIdentity() {
        isResetting = true
        
        // Reset all identities (this will generate a new ECID)
        MobileCore.resetIdentities()
        
        // Wait a moment for the reset to complete, then fetch new values
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            fetchInfo()
            isResetting = false
            
            // Re-register for push notifications
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                appDelegate.registerForPushNotifications(UIApplication.shared)
            }
        }
    }
}

// Reusable view for displaying information with a copy button
struct InfoSection: View {
    var title: String
    var value: String
    var copyAction: () -> Void

    var body: some View {
        HStack() {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                Text(value)
                    .font(.footnote)
            }
            Spacer()
            Button(action: copyAction) {
                Image(systemName: "doc.on.doc")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

#Preview {
    PushView()
}
