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
import ActivityKit
import AEPMessagingLiveActivity

/// Themeable, repeatable Travel Live Activity demo. Lets the presenter
/// tweak colors, the logo URL, the route and the phase in real time so
/// the same activity can be re-skinned per customer without a rebuild.
@available(iOS 16.1, *)
struct TravelLiveActivityView: View {

    // MARK: - State – activity bookkeeping
    @State private var runningActivities: [Activity<TravelLiveActivityAttributes>] = []
    @State private var expandedActivities: [String: Bool] = [:]
    @State private var endImmediateToggles: [String: Bool] = [:]
    @State private var liveActivityID: String = ""
    @State private var channelID: String = ""
    @State private var showAlert: Bool = false
    @State private var statusMessage: String?

    // MARK: - State – brand / theme (lives in attributes/contentState respectively)
    @State private var brandName: String = "Acme Air"
    @State private var logoURL: String = "https://aep-orchestration-lab.web.app/cdn/apalmer/logo/logo.png"
    @State private var backgroundHex: String = "#0F7D47"
    @State private var accentHex: String = "#69D444"
    @State private var foregroundHex: String = "#FFFFFF"

    // MARK: - State – route (lives in ContentState)
    @State private var flightNumber: String = "AA 101"
    @State private var departureAirport: String = "RUH"
    @State private var arrivalAirport: String = "DXB"
    @State private var departureTime: String = "18:45"
    @State private var arrivalTime: String = "21:10"
    @State private var timeStatus: String = "On time"

    // MARK: - State – phase & per-phase content
    @State private var selectedPhase: TravelLiveActivityAttributes.Phase = .flight
    @State private var status: String = "Departed"
    @State private var journeyProgress: Double = 25
    @State private var wifiAvailable: Bool = true
    @State private var currentLocation: String = "Wi-Fi available onboard"
    @State private var boardingStatus: String = ""              // free-text override; empty = use stage label
    @State private var terminal: String = "Terminal A"
    @State private var gate: String = "D4B"
    @State private var seatNumber: String = "12A"
    @State private var statusMessageField: String = "Terminal A - Gate D4B"
    @State private var dwellTimeMessage: String = "Visit Al Dahlah Lounge - Level 2"

    // MARK: - State – journey stage + status pill colour
    @State private var selectedJourneyStage: TravelLiveActivityAttributes.JourneyStage = .boardingNow
    @State private var statusColorMode: StatusColorMode = .auto
    @State private var customStatusHex: String = ""

    /// Quick presets for the status pill colour. `.auto` lets the
    /// `JourneyStage` default colour drive the pill (red / amber / green / blue).
    enum StatusColorMode: String, CaseIterable, Identifiable, Hashable {
        case auto, red, amber, green, blue, custom
        var id: String { rawValue }
        var label: String {
            switch self {
            case .auto:   return "Auto"
            case .red:    return "Red"
            case .amber:  return "Amber"
            case .green:  return "Green"
            case .blue:   return "Blue"
            case .custom: return "Custom"
            }
        }
        /// Returns the hex string that should be sent in the payload, or
        /// `nil` for `.auto` (no override – stage default takes over).
        func resolvedHex(custom: String) -> String? {
            switch self {
            case .auto:   return nil
            case .red:    return "#E53935"
            case .amber:  return "#F39C12"
            case .green:  return "#27AE60"
            case .blue:   return "#2D7AB8"
            case .custom: return custom.isEmpty ? nil : custom
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                BigHeader(title: "Start Live Activity")

                if #available(iOS 17.2, *) {
                    PushToStartSection<TravelLiveActivityAttributes>(
                        pushToStartToken: TokenCollector.travelPushToStartToken
                    )
                } else {
                    Text("Push-to-start not available on < iOS 17.2")
                }

                themeSection
                routeSection
                phaseSection
                journeyStageSection
                startActivitySection
                channelActivitySection
                phaseUpdateButtonsSection
                quickScenariosSection

                if let statusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                }

                HStack {
                    BigHeader(title: "Live Activity in Progress")
                    Spacer()
                    Button {
                        refreshActivities()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                    .padding(.trailing, 10)
                }

                if runningActivities.isEmpty {
                    Text("No live activities in progress")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(runningActivities.indices, id: \.self) { index in
                            let activity = runningActivities[index]
                            activityRow(activity: activity, index: index)
                            Divider()
                        }
                    }
                    .padding(.horizontal, 10)
                }
            }
            .navigationTitle("🌍 Travel Demo")
            .padding(.horizontal, 10)
            .alert("Live Activity ID Required", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enter a Live Activity ID to start the activity.")
            }
        }
        .onAppear { refreshActivities() }
    }
}

// MARK: - Sections

@available(iOS 16.1, *)
private extension TravelLiveActivityView {

    var themeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Brand & Theme")
            SectionDescription(text: "Set the customer brand and color schema. Colors are applied live to every running Travel activity.")

            TextField("Brand name (e.g. Acme Air)", text: $brandName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Logo URL (https://…)", text: $logoURL)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.URL)

            HStack {
                hexInput(label: "Background", value: $backgroundHex)
                hexInput(label: "Accent", value: $accentHex)
                hexInput(label: "Text", value: $foregroundHex)
            }
        }
        .padding(.horizontal, 10)
    }

    var routeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Route")
            SectionDescription(text: "Route metadata is mutable – any push update can change it.")

            HStack {
                TextField("Flight #", text: $flightNumber).textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("From", text: $departureAirport).textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("To", text: $arrivalAirport).textFieldStyle(RoundedBorderTextFieldStyle())
            }
            HStack {
                TextField("Depart", text: $departureTime).textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Arrive", text: $arrivalTime).textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Time status", text: $timeStatus).textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
        .padding(.horizontal, 10)
    }

    var phaseSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Phase")
            SectionDescription(text: "Pick which phase the activity should render. Updates can flip the phase mid-activity.")

            Picker("Phase", selection: $selectedPhase) {
                Text("Flight").tag(TravelLiveActivityAttributes.Phase.flight)
                Text("Boarding").tag(TravelLiveActivityAttributes.Phase.boarding)
                Text("Airport").tag(TravelLiveActivityAttributes.Phase.airport)
            }
            .pickerStyle(.segmented)

            switch selectedPhase {
            case .flight:
                VStack(alignment: .leading, spacing: 6) {
                    TextField("Legacy status text (optional, falls back to Journey Stage)", text: $status)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Text("Journey Progress: \(Int(journeyProgress))%")
                        .font(.caption)
                    Slider(value: $journeyProgress, in: 0...100, step: 1)
                    Toggle("WiFi Available", isOn: $wifiAvailable)
                    TextField("Current location", text: $currentLocation)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            case .boarding:
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        TextField("Terminal", text: $terminal).textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("Gate", text: $gate).textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("Seat", text: $seatNumber).textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    TextField("Status message (e.g. Terminal A - Gate D4B)", text: $statusMessageField)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            case .airport:
                VStack(alignment: .leading, spacing: 6) {
                    TextField("Status message (e.g. Gate opens in 90 minutes)", text: $statusMessageField)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Dwell-time tip", text: $dwellTimeMessage)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
        }
        .padding(.horizontal, 10)
    }

    /// New: dedicated journey-stage section. Picks the canonical stage,
    /// optionally overrides its label / colour, previews the resolved pill.
    var journeyStageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Journey Stage")
            SectionDescription(text: "The stage drives the status-pill label and colour. Override either via the free-text label or the colour picker.")

            HStack {
                Text("Stage")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Menu {
                    ForEach(TravelLiveActivityAttributes.JourneyStage.allCases, id: \.self) { stage in
                        Button(stage.defaultLabel) {
                            selectedJourneyStage = stage
                            // Auto-pivot the phase to the stage's natural layout
                            selectedPhase = stage.suggestedPhase
                            // Clear free-text override so the stage's label wins
                            boardingStatus = ""
                            // Reset colour to auto so the stage's default colour wins
                            statusColorMode = .auto
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedJourneyStage.defaultLabel)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(6)
                }
            }

            TextField("Override label (optional, blank = use stage default)", text: $boardingStatus)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Pill colour")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("Pill colour", selection: $statusColorMode) {
                    ForEach(StatusColorMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if statusColorMode == .custom {
                    TextField("#RRGGBB", text: $customStatusHex)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                }
            }

            statusPillPreview
        }
        .padding(.horizontal, 10)
    }

    /// Live preview of what the resolved pill (label + colour) will look like.
    var statusPillPreview: some View {
        let label = boardingStatus.isEmpty ? selectedJourneyStage.defaultLabel : boardingStatus
        let hex = statusColorMode.resolvedHex(custom: customStatusHex)
            ?? selectedJourneyStage.defaultColorHex
        let color = Color(hex: hex) ?? Color.gray
        return HStack(spacing: 8) {
            Text("Preview")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(color)
                .cornerRadius(6)
                .foregroundColor(.white)
            Spacer()
        }
    }

    var startActivitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionHeader(title: "Local")
                Spacer()
                SectionSubHeader(title: "iOS 16.1+")
            }
            SectionDescription(text: "Start a Travel Live Activity. The logo URL is downloaded into the shared App Group container before the activity starts.")

            TextField("Enter Live Activity ID", text: $liveActivityID)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button(action: startLiveActivity) {
                Text("Start Live Activity")
                    .fontWeight(.medium)
                    .padding(.all, 10)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(8)
            }
            .foregroundColor(.blue)
            .padding(.top, 6)
        }
        .padding(.horizontal, 10)
    }

    var channelActivitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Using Channel")
            SectionDescription(text: "Use channel to provide updates to the live activity.")

            TextField("Enter Channel ID", text: $channelID)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button(action: startChannelActivity) {
                Text("Subscribe and Start Activity")
                    .fontWeight(.medium)
                    .padding(.all, 10)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(8)
            }
            .foregroundColor(.green)
            .padding(.top, 6)
        }
        .padding(.horizontal, 10)
    }

    /// One-tap travel-companion scenarios. Each preset configures the form
    /// to a sensible state for that journey stage and immediately pushes
    /// the update to all running Travel activities. Presents the journey
    /// in roughly the order a passenger would experience it so a demo run
    /// can walk top-to-bottom-left-to-right.
    var quickScenariosSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Quick scenarios")
            SectionDescription(text: "Walk through a full travel journey. Each tap configures the form and pushes to every running activity.")

            // Three rows of stages so the buttons stay tappable.
            ForEach(scenarioRows.indices, id: \.self) { rowIndex in
                HStack(spacing: 6) {
                    ForEach(scenarioRows[rowIndex], id: \.self) { stage in
                        scenarioButton(stage: stage)
                    }
                }
            }
        }
        .padding(.horizontal, 10)
    }

    /// Stages grouped by area of journey.
    var scenarioRows: [[TravelLiveActivityAttributes.JourneyStage]] {
        [
            // Pre-airport / airside
            [.checkInOpen, .checkedIn, .goToSecurity, .throughSecurity, .exploreAirport],
            // Gate / boarding
            [.goToGate, .boardingSoon, .boardingNow, .finalCall, .gateChange, .gateClosing, .gateClosed, .boarded],
            // Flight + arrival + disruption
            [.departed, .inFlight, .landed, .arrivedAtGate, .baggageReady, .delayed, .cancelled]
        ]
    }

    func scenarioButton(stage: TravelLiveActivityAttributes.JourneyStage) -> some View {
        let color = Color(hex: stage.defaultColorHex) ?? .gray
        return Button {
            applyScenario(stage)
        } label: {
            Text(stage.defaultLabel)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(color.opacity(0.18))
                .cornerRadius(6)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundColor(color)
    }

    /// Per-phase update buttons that immediately push the current form state
    /// (with the chosen phase) onto every running activity – the easiest way
    /// to demo phase swaps end-to-end.
    var phaseUpdateButtonsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Update running activities")
            SectionDescription(text: "Pushes the current form state to all running Travel activities, locked to the chosen phase.")

            HStack(spacing: 8) {
                phaseUpdateButton(title: "Flight", phase: .flight, color: .blue)
                phaseUpdateButton(title: "Boarding", phase: .boarding, color: .orange)
                phaseUpdateButton(title: "Airport", phase: .airport, color: .purple)
            }
        }
        .padding(.horizontal, 10)
    }

    func phaseUpdateButton(title: String, phase: TravelLiveActivityAttributes.Phase, color: Color) -> some View {
        Button {
            updateAllRunningActivities(forcing: phase)
        } label: {
            Text(title)
                .fontWeight(.medium)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(color.opacity(0.15))
                .cornerRadius(8)
        }
        .foregroundColor(color)
    }

    func hexInput(label: String, value: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundColor(.secondary)
            TextField("#RRGGBB", text: value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)
        }
    }

    func activityRow(activity: Activity<TravelLiveActivityAttributes>, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Activity \(index + 1)")
                        .font(.headline)
                    Text(activity.id)
                        .font(.system(size: 7))
                        .foregroundColor(.secondary)
                }
                Spacer()
                let pushToken = activity.pushToken
                    .map { $0.map { String(format: "%02x", $0) }.joined() } ?? ""
                let displayToken = pushToken.isEmpty ? "No token" : truncateToken(pushToken)
                HStack(spacing: 4) {
                    Text(displayToken)
                        .font(.subheadline)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundColor(.secondary)
                    Button {
                        UIPasteboard.general.string = pushToken
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .foregroundColor(pushToken.isEmpty ? .gray : .blue)
                }
            }

            let state = activity.contentState
            Text("Phase: \(state.phase.rawValue)\nBrand: \(activity.attributes.brandName ?? "—")\nFlight: \(state.flightNumber ?? "—") (\(state.departureAirport ?? "—") → \(state.arrivalAirport ?? "—"))")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Spacer()
                Button {
                    expandedActivities[activity.id]?.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Text("Edit")
                        Image(systemName: expandedActivities[activity.id, default: false] ? "chevron.up" : "chevron.down")
                    }
                }
                .foregroundColor(.gray)
            }

            if expandedActivities[activity.id, default: false] {
                VStack(alignment: .leading, spacing: 12) {
                    Button("Apply current form to this activity") {
                        applyCurrentFormState(to: activity)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(6)
                    .foregroundColor(.blue)

                    Toggle("Dismiss Immediately", isOn: Binding(
                        get: { endImmediateToggles[activity.id, default: false] },
                        set: { endImmediateToggles[activity.id] = $0 }
                    ))
                    .font(.system(size: 13))
                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))

                    HStack {
                        Spacer()
                        Button("End Activity") {
                            endSelectedActivity(activity: activity, immediate: endImmediateToggles[activity.id, default: false])
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(6)
                        Spacer()
                    }
                }
                .padding(10)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding(6)
        .background(Color.clear)
        .cornerRadius(8)
        .onAppear {
            if expandedActivities[activity.id] == nil {
                expandedActivities[activity.id] = false
            }
            if endImmediateToggles[activity.id] == nil {
                endImmediateToggles[activity.id] = false
            }
        }
    }
}

// MARK: - Activity actions

@available(iOS 16.1, *)
private extension TravelLiveActivityView {

    func refreshActivities() {
        runningActivities = Activity<TravelLiveActivityAttributes>.activities
    }

    func currentTheme() -> TravelLiveActivityAttributes.Theme {
        TravelLiveActivityAttributes.Theme(
            background: backgroundHex,
            accent: accentHex,
            onBackground: foregroundHex.isEmpty ? nil : foregroundHex
        )
    }

    func currentContentState(forcing phase: TravelLiveActivityAttributes.Phase? = nil) -> TravelLiveActivityAttributes.ContentState {
        let p = phase ?? selectedPhase
        // The boarding/free-text override is allowed on all phases now -
        // the widget will use it on the status pill regardless of layout.
        let overrideLabel = boardingStatus.isEmpty ? nil : boardingStatus
        let resolvedColor = statusColorMode.resolvedHex(custom: customStatusHex)
        return TravelLiveActivityAttributes.ContentState(
            phase: p,
            theme: currentTheme(),
            flightNumber: flightNumber.isEmpty ? nil : flightNumber,
            departureAirport: departureAirport.isEmpty ? nil : departureAirport,
            arrivalAirport: arrivalAirport.isEmpty ? nil : arrivalAirport,
            departureTime: departureTime.isEmpty ? nil : departureTime,
            arrivalTime: arrivalTime.isEmpty ? nil : arrivalTime,
            timeStatus: timeStatus.isEmpty ? nil : timeStatus,
            status: p == .flight ? (status.isEmpty ? nil : status) : nil,
            journeyProgress: p == .flight ? Int(journeyProgress) : nil,
            wifiAvailable: p == .flight ? wifiAvailable : nil,
            currentLocation: p == .flight ? (currentLocation.isEmpty ? nil : currentLocation) : nil,
            boardingStatus: overrideLabel,
            terminal: p == .boarding ? (terminal.isEmpty ? nil : terminal) : nil,
            gate: p == .boarding ? (gate.isEmpty ? nil : gate) : nil,
            seatNumber: p == .boarding ? (seatNumber.isEmpty ? nil : seatNumber) : nil,
            statusMessage: (p == .boarding || p == .airport) ? (statusMessageField.isEmpty ? nil : statusMessageField) : nil,
            dwellTimeMessage: p == .airport ? (dwellTimeMessage.isEmpty ? nil : dwellTimeMessage) : nil,
            journeyStage: selectedJourneyStage,
            statusColor: resolvedColor
        )
    }

    func currentAttributes(liveActivityData: LiveActivityData, logoFileName: String?) -> TravelLiveActivityAttributes {
        TravelLiveActivityAttributes(
            liveActivityData: liveActivityData,
            appGroupID: TravelAppGroup.identifier,
            logoFileName: logoFileName,
            brandName: brandName.isEmpty ? nil : brandName
        )
    }

    func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            statusMessage = "Live Activities are disabled on this device."
            return
        }
        let trimmed = liveActivityID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showAlert = true
            return
        }

        Task {
            let logoFileName = await prefetchLogoIfNeeded()
            let attributes = currentAttributes(
                liveActivityData: LiveActivityData(liveActivityID: trimmed),
                logoFileName: logoFileName
            )
            do {
                let newActivity = try Activity<TravelLiveActivityAttributes>.request(
                    attributes: attributes,
                    contentState: currentContentState(),
                    pushType: .token
                )
                statusMessage = "Travel Live Activity started: \(newActivity.id)"
                refreshActivities()
            } catch {
                statusMessage = "Error requesting live activity: \(error.localizedDescription)"
            }
        }
    }

    func startChannelActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            statusMessage = "Live Activities are disabled on this device."
            return
        }
        let trimmed = channelID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            statusMessage = "Channel ID cannot be empty."
            return
        }

        Task {
            let logoFileName = await prefetchLogoIfNeeded()
            let attributes = currentAttributes(
                liveActivityData: LiveActivityData(channelID: trimmed),
                logoFileName: logoFileName
            )
            do {
                if #available(iOS 18.0, *) {
                    let newActivity = try Activity<TravelLiveActivityAttributes>.request(
                        attributes: attributes,
                        contentState: currentContentState(),
                        pushType: .channel(trimmed)
                    )
                    statusMessage = "Travel Live Activity (CHANNEL: \(trimmed)) started: \(newActivity.id)"
                }
                refreshActivities()
            } catch {
                statusMessage = "Error requesting live activity: \(error.localizedDescription)"
            }
        }
    }

    func applyCurrentFormState(to activity: Activity<TravelLiveActivityAttributes>) {
        Task {
            await activity.update(using: currentContentState())
            statusMessage = "Updated activity \(activity.id)"
            refreshActivities()
        }
    }

    /// Configures the form for the requested journey stage (label, colour
    /// reset to auto so the stage's semantic colour wins, suggested phase,
    /// and contextual messages) and immediately pushes to every running
    /// Travel activity. If no activities are running the form is still
    /// updated so the next "Start Live Activity" tap inherits the scenario.
    func applyScenario(_ stage: TravelLiveActivityAttributes.JourneyStage) {
        selectedJourneyStage = stage
        boardingStatus = ""           // let the stage's defaultLabel drive the pill
        statusColorMode = .auto       // let the stage's defaultColor drive the pill
        customStatusHex = ""

        let phase = stage.suggestedPhase
        selectedPhase = phase

        // Sensible per-stage status messages, dwell tips, and progress.
        switch stage {
        case .checkInOpen:
            statusMessageField = "Online check-in is now open"
            dwellTimeMessage = "Check in from the app and skip the desk"
        case .checkedIn:
            statusMessageField = "Boarding pass ready in your wallet"
            dwellTimeMessage = "Allow 90 minutes for security"
        case .goToSecurity:
            statusMessageField = "Head to security – flight in 90 minutes"
            dwellTimeMessage = "Liquids in clear bag, devices ready"
        case .throughSecurity:
            statusMessageField = "Welcome airside – enjoy your stay"
            dwellTimeMessage = "Lounge access available on Level 2"
        case .exploreAirport:
            statusMessageField = "Gate opens in 90 minutes"
            dwellTimeMessage = "Visit Al Dahlah Lounge - Level 2"
        case .goToGate:
            statusMessageField = "Walk to your gate now – allow 15 mins"
            dwellTimeMessage = "Your gate is a 12-minute walk away"
        case .boardingSoon:
            statusMessageField = "Boarding starts in 15 minutes"
            dwellTimeMessage = "Final shopping at duty free"
        case .boardingNow:
            statusMessageField = "Boarding now at \(gate.isEmpty ? "your gate" : "Gate \(gate)")"
        case .finalCall:
            statusMessageField = "Final call – proceed to the gate immediately"
        case .gateChange:
            statusMessageField = "Gate changed – please proceed to your new gate"
        case .gateClosing:
            statusMessageField = "Gate closing in 5 minutes"
        case .gateClosed:
            statusMessageField = "Gate closed – contact a member of staff"
        case .boarded:
            statusMessageField = "Welcome onboard – enjoy your flight"
        case .departed:
            statusMessageField = "Departed on time"
            status = "Departed"
            journeyProgress = 5
        case .inFlight:
            statusMessageField = "In flight – enjoy your journey"
            status = "In Flight"
            journeyProgress = 50
        case .landed:
            statusMessageField = "Welcome – we have landed"
            status = "Landed"
            journeyProgress = 100
        case .arrivedAtGate:
            statusMessageField = "Arrived at gate – please remain seated"
            status = "Arrived"
            journeyProgress = 100
        case .baggageReady:
            statusMessageField = "Baggage ready on belt"
            dwellTimeMessage = "Your bag is on belt 4"
        case .delayed:
            statusMessageField = "Flight delayed – we'll keep you posted"
            timeStatus = "Delayed"
        case .cancelled:
            statusMessageField = "Flight cancelled – rebooking options coming"
            timeStatus = "Cancelled"
        }

        let activities = Activity<TravelLiveActivityAttributes>.activities
        guard !activities.isEmpty else {
            statusMessage = "Form set to '\(stage.defaultLabel)'. Start a Live Activity to see it."
            return
        }
        Task {
            let state = currentContentState(forcing: phase)
            for activity in activities {
                await activity.update(using: state)
            }
            statusMessage = "Pushed scenario '\(stage.defaultLabel)' to \(activities.count) activity(ies)"
            refreshActivities()
        }
    }

    func updateAllRunningActivities(forcing phase: TravelLiveActivityAttributes.Phase) {
        let activities = Activity<TravelLiveActivityAttributes>.activities
        guard !activities.isEmpty else {
            statusMessage = "No running activities to update."
            return
        }
        Task {
            let state = currentContentState(forcing: phase)
            for activity in activities {
                await activity.update(using: state)
            }
            statusMessage = "Updated \(activities.count) activity(ies) → phase: \(phase.rawValue)"
            refreshActivities()
        }
    }

    func endSelectedActivity(activity: Activity<TravelLiveActivityAttributes>, immediate: Bool) {
        Task {
            if immediate {
                await activity.end(dismissalPolicy: .immediate)
            } else {
                await activity.end(dismissalPolicy: .default)
            }
            refreshActivities()
        }
    }

    /// Downloads the current `logoURL` into the App Group container. Returns
    /// the deterministic filename for the Live Activity attributes, or
    /// `nil` if the URL is empty / fails to download.
    func prefetchLogoIfNeeded() async -> String? {
        let trimmed = logoURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed) else { return nil }
        do {
            let name = try await TravelLogoCache.fetch(url, into: TravelAppGroup.identifier)
            return name
        } catch {
            DispatchQueue.main.async {
                statusMessage = "Logo fetch failed: \(error.localizedDescription) – using fallback."
            }
            return nil
        }
    }
}

#Preview {
    if #available(iOS 16.1, *) {
        TravelLiveActivityView()
    } else {
        Text("Requires iOS 16.1 or later")
    }
}
