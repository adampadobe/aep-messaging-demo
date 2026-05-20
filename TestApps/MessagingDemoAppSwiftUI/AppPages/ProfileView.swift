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

import AEPEdgeIdentity
import SwiftUI

// MARK: - Data Models

/// Identity node returned in the `identities` array from /api/profile/consent
struct IdentityNode: Identifiable, Decodable {
    let namespace: String
    let value: String
    var id: String { "\(namespace):\(value)" }
}

/// Audience segment item returned from /api/profile/audiences
struct AudienceItem: Identifiable, Decodable {
    let segmentId: String
    let name: String
    let lastQualificationTime: String?
    var id: String { segmentId }
}

struct AudiencesResponse: Decodable {
    let realized: [AudienceItem]
    let exited: [AudienceItem]
}

/// Single experience event from /api/profile/events
struct ExperienceEventItem: Identifiable, Decodable {
    let entityId: String?
    let eventName: String?
    let timestamp: Double?
    var id: String { entityId ?? UUID().uuidString }

    var displayName: String { eventName ?? "Event" }

    var formattedDate: String {
        guard let ts = timestamp, ts > 0 else { return "—" }
        let date = Date(timeIntervalSince1970: ts / 1000)
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f.string(from: date)
    }
}

struct EventsResponse: Decodable {
    let events: [ExperienceEventItem]
}

/// Decoded consent/profile response from /api/profile/consent.
/// Most numeric/string fields arrive as String | null from the server.
struct ConsentProfile: Decodable {
    let found: Bool
    let email: String?
    let firstName: String?
    let lastName: String?
    let gender: FlexString?
    let age: FlexString?
    let city: String?
    let propensityScore: FlexString?
    let churnPrediction: FlexString?
    let loyaltyStatus: String?
    let customerLifetimeValue: FlexString?
    let lastModifiedAt: String?
    let ecid: FlexString?
    let identities: [IdentityNode]?
    let channels: ConsentChannels?
    let marketingConsent: String?
    let dataCollection: String?
    let preferredMarketingChannel: String?
    let preferredLanguage: String?
    let error: String?

    var fullName: String? {
        let parts = [firstName, lastName].compactMap { $0?.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }
}

struct ConsentChannels: Decodable {
    let email: String?
    let sms: String?
    let push: String?
    let phone: String?
    let directMail: String?
    let whatsapp: String?
    let facebookFeed: String?
    let web: String?
    let mobileApp: String?
    let twitterFeed: String?

    /// All channels in display order, skipping any that are absent in the profile.
    var allChannels: [(label: String, value: String?)] {
        [
            ("Email",        email),
            ("SMS",          sms),
            ("Push",         push),
            ("Phone",        phone),
            ("Direct Mail",  directMail),
            ("WhatsApp",     whatsapp),
            ("Facebook",     facebookFeed),
            ("Web",          web),
            ("Mobile App",   mobileApp),
            ("Twitter/X",    twitterFeed),
        ].filter { $0.value != nil }
    }
}

/// Flexible string that decodes from JSON String, Int, or Double.
struct FlexString: Decodable, ExpressibleByStringLiteral {
    let value: String
    init(stringLiteral value: String) { self.value = value }
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let s = try? c.decode(String.self) { value = s; return }
        if let i = try? c.decode(Int.self) { value = String(i); return }
        if let d = try? c.decode(Double.self) { value = String(d); return }
        value = ""
    }
}

// MARK: - View Model

@MainActor
final class ProfileViewModel: ObservableObject {
    private static let baseURL = "https://aep-orchestration-lab.web.app"

    @Published var profile: ConsentProfile?
    @Published var audiences: AudiencesResponse?
    @Published var events: [ExperienceEventItem] = []
    @Published var ecid: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastIdentifier: String = ""
    @Published var lastNamespace: String = ""

    // MARK: Fetch

    func fetchAll(identifier: String, namespace: String) {
        let id = identifier.trimmingCharacters(in: .whitespaces)
        guard !id.isEmpty else { return }
        lastIdentifier = id
        lastNamespace = namespace
        isLoading = true
        errorMessage = nil

        Task {
            async let profileTask = fetchConsent(identifier: id, namespace: namespace)
            async let audiencesTask = fetchAudiences(identifier: id, namespace: namespace)
            async let eventsTask = fetchEvents(identifier: id, namespace: namespace)

            let (p, a, e) = await (profileTask, audiencesTask, eventsTask)
            self.profile = p
            self.audiences = a
            self.events = e
            self.isLoading = false
            if p == nil && a == nil && e.isEmpty {
                self.errorMessage = "No data returned. Check the identifier or try again."
            }
        }
    }

    func loadCurrentIdentity() async {
        await withCheckedContinuation { continuation in
            AEPEdgeIdentity.Identity.getIdentities { map, _ in
                let id = map?.getItems(withNamespace: "ECID")?.first?.id ?? ""
                Task { @MainActor in
                    self.ecid = id
                    continuation.resume()
                }
            }
        }
    }

    // MARK: Private API calls

    private func fetchConsent(identifier: String, namespace: String) async -> ConsentProfile? {
        guard let url = buildURL("/api/profile/consent", identifier: identifier, namespace: namespace) else { return nil }
        return await decode(ConsentProfile.self, from: url)
    }

    private func fetchAudiences(identifier: String, namespace: String) async -> AudiencesResponse? {
        guard let url = buildURL("/api/profile/audiences", identifier: identifier, namespace: namespace) else { return nil }
        return await decode(AudiencesResponse.self, from: url)
    }

    private func fetchEvents(identifier: String, namespace: String) async -> [ExperienceEventItem] {
        guard let url = buildURL("/api/profile/events", identifier: identifier, namespace: namespace) else { return [] }
        let response = await decode(EventsResponse.self, from: url)
        return response?.events ?? []
    }

    private func buildURL(_ path: String, identifier: String, namespace: String) -> URL? {
        var comps = URLComponents(string: Self.baseURL + path)
        // Swift's URLComponents does NOT percent-encode `+` in query values — it's a
        // legal RFC 3986 query character. But Express.js (and most server-side query
        // parsers) follow application/x-www-form-urlencoded and decode bare `+` as a
        // space. Emails like "user+tag@example.com" therefore arrive as
        // "user tag@example.com" and never match. Pre-encode `+` → `%2B` ourselves.
        let safeId = identifier.replacingOccurrences(of: "+", with: "%2B")
        comps?.percentEncodedQueryItems = [
            URLQueryItem(name: "identifier", value: safeId),
            URLQueryItem(name: "namespace",  value: namespace)
        ]
        return comps?.url
    }

    private func decode<T: Decodable>(_ type: T.Type, from url: URL) async -> T? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            return nil
        }
    }
}

// MARK: - Main View

struct ProfileView: View {
    @EnvironmentObject private var identityManager: IdentityManager
    @StateObject private var vm = ProfileViewModel()

    @State private var lookupIdentifier: String = ""
    @State private var lookupNamespace: String = "email"
    @State private var showLookupSheet = false

    private var namespaceOptions = ["email", "ecid", "crmId", "loyaltyId"]

    var body: some View {
        NavigationView {
            Group {
                if vm.isLoading && vm.profile == nil {
                    loadingView
                } else if let error = vm.errorMessage, vm.profile == nil {
                    errorView(error)
                } else {
                    profileContent
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showLookupSheet = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if vm.isLoading {
                        ProgressView()
                    }
                }
            }
            .sheet(isPresented: $showLookupSheet) {
                lookupSheet
            }
            .task {
                await vm.loadCurrentIdentity()
                // Auto-load using email if logged in, else ECID
                let identifier = identityManager.loggedInEmail ?? vm.ecid
                let namespace = identityManager.loggedInEmail != nil ? "email" : "ecid"
                if !identifier.isEmpty {
                    lookupIdentifier = identifier
                    lookupNamespace = namespace
                    vm.fetchAll(identifier: identifier, namespace: namespace)
                }
            }
            .refreshable {
                let id = vm.lastIdentifier.isEmpty ? (identityManager.loggedInEmail ?? vm.ecid) : vm.lastIdentifier
                let ns = vm.lastNamespace.isEmpty ? (identityManager.loggedInEmail != nil ? "email" : "ecid") : vm.lastNamespace
                vm.fetchAll(identifier: id, namespace: ns)
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: Profile Content

    private var profileContent: some View {
        List {
            // ── Identity header ───────────────────────────────────────
            Section {
                identityHeader
            }

            // ── Profile Attributes ────────────────────────────────────
            if let p = vm.profile, p.found == true {
                Section("Profile Attributes") {
                    profileAttributeRows(p)
                }

                // ── Consent ───────────────────────────────────────────
                if let channels = p.channels, !channels.allChannels.isEmpty {
                    Section("Marketing Consent") {
                        ForEach(channels.allChannels, id: \.label) { ch in
                            consentRow(label: ch.label, value: ch.value)
                        }
                    }
                }
            } else if let p = vm.profile, p.found == false {
                Section {
                    Label("No profile found for this identity yet.", systemImage: "person.slash")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
            }

            // ── Identity Graph ────────────────────────────────────────
            let identities = vm.profile?.identities ?? []
            if !identities.isEmpty {
                Section("Identity Graph (\(identities.count))") {
                    ForEach(identities) { node in
                        identityNodeRow(node)
                    }
                }
            }

            // ── Audiences ─────────────────────────────────────────────
            if let aud = vm.audiences {
                if !aud.realized.isEmpty {
                    Section("Audiences — Realized (\(aud.realized.count))") {
                        ForEach(aud.realized) { item in
                            audienceRow(item, status: "realized")
                        }
                    }
                }
                if !aud.exited.isEmpty {
                    Section("Audiences — Exited (\(aud.exited.count))") {
                        ForEach(aud.exited) { item in
                            audienceRow(item, status: "exited")
                        }
                    }
                }
                if aud.realized.isEmpty && aud.exited.isEmpty {
                    Section("Audiences") {
                        Text("No audience memberships found.")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                }
            }

            // ── Recent Events ─────────────────────────────────────────
            if !vm.events.isEmpty {
                Section("Recent Events (\(min(vm.events.count, 10)))") {
                    ForEach(vm.events.prefix(10)) { event in
                        eventRow(event)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: Identity Header

    private var identityHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            // ECID row
            if !vm.ecid.isEmpty {
                HStack(spacing: 6) {
                    namespaceBadge("ECID", color: .blue)
                    Text(vm.ecid)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .textSelection(.enabled)
                }
            }
            // Email row (if logged in)
            if let email = identityManager.loggedInEmail {
                HStack(spacing: 6) {
                    namespaceBadge("Email", color: .purple)
                    Text(email)
                        .font(.subheadline)
                        .textSelection(.enabled)
                }
            }
            // Last lookup identifier (if different from above)
            if !vm.lastIdentifier.isEmpty,
               vm.lastIdentifier != identityManager.loggedInEmail,
               vm.lastIdentifier != vm.ecid {
                HStack(spacing: 6) {
                    namespaceBadge(vm.lastNamespace, color: .gray)
                    Text(vm.lastIdentifier)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: Profile Attribute Rows

    @ViewBuilder
    private func profileAttributeRows(_ p: ConsentProfile) -> some View {
        if let name = p.fullName { profileRow("Name", value: name) }
        if let age = p.age?.value, !age.isEmpty { profileRow("Age", value: age) }
        if let city = p.city, !city.isEmpty { profileRow("City", value: city) }
        if let loyalty = p.loyaltyStatus, !loyalty.isEmpty { profileRow("Loyalty", value: loyalty.capitalized) }
        if let ltv = p.customerLifetimeValue?.value, !ltv.isEmpty { profileRow("Lifetime Value", value: ltv) }
        if let ps = p.propensityScore?.value, !ps.isEmpty { profileRow("Propensity Score", value: ps) }
        if let churn = p.churnPrediction?.value, !churn.isEmpty { profileRow("Churn Prediction", value: churn) }
        if let channel = p.preferredMarketingChannel, !channel.isEmpty { profileRow("Preferred Channel", value: channel.capitalized) }
        if let lang = p.preferredLanguage, !lang.isEmpty { profileRow("Language", value: lang) }
        if let dc = p.dataCollection, dc != "na" { profileRow("Data Collection", value: dc == "in" ? "Opted In" : "Opted Out") }
        if let mod = p.lastModifiedAt {
            profileRow("Last Modified", value: formatISODate(mod))
        }
    }

    // MARK: Row Helpers

    private func profileRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
    }

    private func consentRow(label: String, value: String?) -> some View {
        let status = value?.lowercased() ?? "na"
        let (icon, color): (String, Color) = {
            switch status {
            case "in": return ("checkmark.circle.fill", .green)
            case "out": return ("xmark.circle.fill", .red)
            default: return ("minus.circle", .secondary)
            }
        }()
        return HStack {
            Image(systemName: icon).foregroundColor(color)
            Text(label).font(.subheadline)
            Spacer()
            Text(status == "in" ? "Opted In" : status == "out" ? "Opted Out" : "Not Set")
                .font(.caption)
                .foregroundColor(color)
        }
    }

    private func identityNodeRow(_ node: IdentityNode) -> some View {
        HStack(spacing: 8) {
            namespaceBadge(node.namespace, color: namespaceColor(node.namespace))
            Text(node.value)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
        }
        .padding(.vertical, 2)
    }

    private func audienceRow(_ item: AudienceItem, status: String) -> some View {
        HStack {
            Circle()
                .fill(status == "realized" ? Color.green : Color.secondary.opacity(0.4))
                .frame(width: 8, height: 8)
            Text(item.name)
                .font(.subheadline)
            Spacer()
            if let t = item.lastQualificationTime {
                Text(relativeDate(t))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func eventRow(_ event: ExperienceEventItem) -> some View {
        HStack(spacing: 8) {
            Image(systemName: eventIcon(event.displayName))
                .foregroundColor(.accentColor)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.displayName)
                    .font(.subheadline)
                    .lineLimit(1)
                Text(event.formattedDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: Namespace Badge

    private func namespaceBadge(_ ns: String, color: Color) -> some View {
        Text(ns.uppercased())
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color)
            .clipShape(Capsule())
    }

    // MARK: Lookup Sheet

    private var lookupSheet: some View {
        NavigationView {
            Form {
                Section("Look Up Profile") {
                    TextField("Identifier (email, ECID, etc.)", text: $lookupIdentifier)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Picker("Namespace", selection: $lookupNamespace) {
                        ForEach(namespaceOptions, id: \.self) { ns in
                            Text(ns).tag(ns)
                        }
                    }
                }
                Section {
                    Button("Look Up") {
                        showLookupSheet = false
                        vm.fetchAll(identifier: lookupIdentifier, namespace: lookupNamespace)
                    }
                    .disabled(lookupIdentifier.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                if let email = identityManager.loggedInEmail {
                    Section("Quick Fill") {
                        Button("Use logged-in email: \(email)") {
                            lookupIdentifier = email
                            lookupNamespace = "email"
                        }
                        .font(.subheadline)
                    }
                }
                if !vm.ecid.isEmpty {
                    Section {
                        Button("Use device ECID") {
                            lookupIdentifier = vm.ecid
                            lookupNamespace = "ecid"
                        }
                        .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Profile Lookup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showLookupSheet = false }
                }
            }
        }
    }

    // MARK: Loading / Error

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading profile…")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            Button("Retry") {
                let id = identityManager.loggedInEmail ?? vm.ecid
                let ns = identityManager.loggedInEmail != nil ? "email" : "ecid"
                vm.fetchAll(identifier: id, namespace: ns)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Helpers

    private func namespaceColor(_ ns: String) -> Color {
        switch ns.lowercased() {
        case "ecid":        return .blue
        case "email":       return .purple
        case "crmid":       return .orange
        case "loyaltyid":   return .yellow
        case "phone":       return .green
        default:            return .gray
        }
    }

    private func eventIcon(_ type: String) -> String {
        let t = type.lowercased()
        if t.contains("login") || t.contains("stitch") { return "person.fill.checkmark" }
        if t.contains("push") || t.contains("notification") { return "bell.fill" }
        if t.contains("email") { return "envelope.fill" }
        if t.contains("purchase") || t.contains("order") { return "cart.fill" }
        if t.contains("view") || t.contains("page") { return "eye.fill" }
        if t.contains("click") { return "cursorarrow.click.fill" }
        return "bolt.fill"
    }

    private func formatISODate(_ iso: String) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: iso) {
            let out = DateFormatter()
            out.dateStyle = .medium
            out.timeStyle = .short
            return out.string(from: d)
        }
        return String(iso.prefix(10))
    }

    private func relativeDate(_ iso: String) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let d = f.date(from: iso) else { return String(iso.prefix(10)) }
        let diff = Date().timeIntervalSince(d)
        if diff < 3600 { return "\(Int(diff / 60))m ago" }
        if diff < 86400 { return "\(Int(diff / 3600))h ago" }
        return "\(Int(diff / 86400))d ago"
    }
}

// MARK: - Preview

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(IdentityManager.shared)
    }
}
