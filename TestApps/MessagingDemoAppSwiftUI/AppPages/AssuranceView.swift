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

import AEPAssurance
import SwiftUI

/// Assurance tab — paste a session URL from experience.adobe.com/assurance and tap Connect.
/// The last-used URL is persisted so you don't need to re-paste it each session.
struct AssuranceView: View {

    private static let storageKey = "assuranceSessionURL"

    @State private var sessionURL: String = UserDefaults.standard.string(forKey: storageKey) ?? ""
    @State private var status: ConnectionStatus = .idle
    @State private var showCopiedHint = false

    enum ConnectionStatus {
        case idle
        case connecting
        case connected
        case error(String)

        var label: String {
            switch self {
            case .idle:           return "Not connected"
            case .connecting:     return "Connecting…"
            case .connected:      return "Session started"
            case .error(let msg): return msg
            }
        }

        var color: Color {
            switch self {
            case .idle:       return .secondary
            case .connecting: return .orange
            case .connected:  return .green
            case .error:      return .red
            }
        }

        var icon: String {
            switch self {
            case .idle:       return "circle"
            case .connecting: return "circle.dotted"
            case .connected:  return "checkmark.circle.fill"
            case .error:      return "exclamationmark.circle.fill"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            Form {
                // ── Status ────────────────────────────────────────────
                Section {
                    HStack(spacing: 10) {
                        Image(systemName: status.icon)
                            .foregroundColor(status.color)
                        Text(status.label)
                            .foregroundColor(status.color)
                            .font(.subheadline)
                    }
                } header: {
                    Text("Status")
                }

                // ── Session URL ───────────────────────────────────────
                Section {
                    ZStack(alignment: .topTrailing) {
                        TextEditor(text: $sessionURL)
                            .font(.system(.footnote, design: .monospaced))
                            .frame(minHeight: 80, maxHeight: 140)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .onChange(of: sessionURL) { newValue in
                                // Reset status when URL is edited
                                if case .connected = status { } else { status = .idle }
                                UserDefaults.standard.set(newValue, forKey: Self.storageKey)
                            }

                        if !sessionURL.isEmpty {
                            Button {
                                sessionURL = ""
                                status = .idle
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .padding(6)
                        }
                    }

                    // Paste from clipboard button
                    Button {
                        if let clip = UIPasteboard.general.string, !clip.isEmpty {
                            sessionURL = clip.trimmingCharacters(in: .whitespacesAndNewlines)
                            status = .idle
                        }
                    } label: {
                        Label("Paste from Clipboard", systemImage: "doc.on.clipboard")
                            .font(.subheadline)
                    }
                } header: {
                    Text("Session URL")
                } footer: {
                    Text("Get this from experience.adobe.com/assurance → Create Session → Connect App. Format: messagingdemo://?adb_validation_sessionid=UUID")
                        .font(.caption)
                }

                // ── Connect button ────────────────────────────────────
                Section {
                    Button {
                        connect()
                    } label: {
                        HStack {
                            Spacer()
                            if case .connecting = status {
                                ProgressView()
                                    .padding(.trailing, 6)
                            }
                            Text(connectButtonLabel)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!isValidURL || isConnecting)
                    .listRowBackground(isValidURL && !isConnecting ? Color.accentColor : Color.secondary.opacity(0.3))
                    .foregroundColor(.white)
                }

                // ── Instructions ──────────────────────────────────────
                Section("How to get a session URL") {
                    instructionRow(step: "1", text: "Go to experience.adobe.com/assurance")
                    instructionRow(step: "2", text: "Create a new session for your org")
                    instructionRow(step: "3", text: "Choose \"Connect app via URL\" and copy the link")
                    instructionRow(step: "4", text: "Paste it above and tap Connect")
                }
            }
            .navigationTitle("Assurance")
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Helpers

    private var isValidURL: Bool {
        let trimmed = sessionURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed),
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
              let raw = items.first(where: { $0.name == "adb_validation_sessionid" })?.value,
              !raw.isEmpty else { return false }
        return UUID(uuidString: raw) != nil
    }

    private var isConnecting: Bool {
        if case .connecting = status { return true }
        return false
    }

    private var connectButtonLabel: String {
        switch status {
        case .connecting: return "Connecting…"
        case .connected:  return "Session Started ✓"
        default:          return "Connect to Assurance"
        }
    }

    private func connect() {
        let trimmed = sessionURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else {
            status = .error("Invalid URL")
            return
        }
        status = .connecting
        // Give the UI a moment to show "Connecting…" before the SDK call
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            (UIApplication.shared.delegate as? AppDelegate)?.enqueueAssuranceDeepLink(url)
            // Assurance.startSession is fire-and-forget; assume success if the URL was valid.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                status = .connected
            }
        }
    }

    private func instructionRow(step: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(step)
                .font(.system(.caption, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.accentColor)
                .clipShape(Circle())
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }
}

struct AssuranceView_Previews: PreviewProvider {
    static var previews: some View {
        AssuranceView()
    }
}
