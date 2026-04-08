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

// MARK: - EtihadBoardingLiveActivityView

@available(iOS 16.1, *)
struct EtihadBoardingLiveActivityView: View {
    // MARK: - State Properties
    
    @State private var runningActivities: [Activity<EtihadBoardingAttributes>] = []
    @State private var expandedActivities: [String: Bool] = [:]
    @State private var endImmediateToggles: [String: Bool] = [:]
    @State private var liveActivityID: String = ""
    @State private var channelID: String = ""
    @State private var showAlert: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // MARK: - Start Live Activity
                BigHeader(title: "Start Boarding Live Activity")
                
                // 1) Push-to-start (iOS 17.2+)
                if #available(iOS 17.2, *) {
                    PushToStartSection<EtihadBoardingAttributes>(
                        pushToStartToken: TokenCollector.etihadBoardingPushToStartToken
                    )
                } else {
                    Text("Push-to-start not available on < iOS 17.2")
                }
                
                // 2) Start in-app
                startActivitySection
                
                channelActivitySection
                
                // MARK: - Live Activity in Progress
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
            .navigationTitle("🎫 Etihad Boarding")
            .padding(.horizontal, 10)
            .alert("Live Activity ID Required", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enter a Live Activity ID to start the activity.")
            }
        }
        .onAppear {
            refreshActivities()
        }
    }
}

// MARK: - Private Extension

@available(iOS 16.1, *)
private extension EtihadBoardingLiveActivityView {
    
    var startActivitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionHeader(title: "Local")
                Spacer()
                SectionSubHeader(title: "iOS 16.1+")
            }
            SectionDescription(text: "Start an Etihad boarding Live Activity. Track check-in, security, and boarding status.")
            
            TextField("Enter Live Activity ID", text: $liveActivityID)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.vertical, 4)
            
            Button(action: startLiveActivity) {
                Text("Start Live Activity")
                    .fontWeight(.medium)
                    .padding(.all, 10)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(8)
            }
            .foregroundColor(.blue)
            .padding(.top, 10)
        }
        .padding(.horizontal, 10)
    }
    
    var channelActivitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionHeader(title: "Using Channel")
                Spacer()
            }
            SectionDescription(text: "Use channel to provide updates to the live activity.")
            
            TextField("Enter Channel ID", text: $channelID)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.vertical, 4)
            
            Button(action: startChannelActivity) {
                Text("Subscribe and Start Activity")
                    .fontWeight(.medium)
                    .padding(.all, 10)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(8)
            }
            .foregroundColor(.green)
            .padding(.top, 10)
        }
        .padding(.horizontal, 10)
    }
    
    func activityRow(activity: Activity<EtihadBoardingAttributes>, index: Int) -> some View {
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
                
                VStack(alignment: .trailing, spacing: 2) {
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
            }
            
            let contentState = activity.contentState
            Text("Status: \(contentState.boardingStatus)\nFlight: \(activity.attributes.flightNumber)\n\(contentState.statusMessage)")
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
    
    // MARK: - Methods
    
    func refreshActivities() {
        let current = Activity<EtihadBoardingAttributes>.activities
        runningActivities = current
    }
    
    func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are disabled on this device.")
            return
        }
        
        let trimmedLiveActivityID = liveActivityID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLiveActivityID.isEmpty else {
            showAlert = true
            return
        }
        
        let attributes = EtihadBoardingAttributes(
            liveActivityData: LiveActivityData(liveActivityID: trimmedLiveActivityID),
            flightNumber: "EY 62",
            departureAirport: "LHR",
            arrivalAirport: "AUH",
            departureTime: "22:10",
            arrivalTime: "08:05",
            flightDuration: "6h 55m",
            terminal: "Terminal A",
            gate: "Gate D4B"
        )
        let initialContentState = EtihadBoardingAttributes.ContentState(
            boardingStatus: "Check-in Open",
            statusMessage: "Check-in opens 24 hours before departure",
            timeStatus: "On time"
        )
        
        do {
            let newActivity = try Activity<EtihadBoardingAttributes>.request(
                attributes: attributes,
                contentState: initialContentState,
                pushType: .token
            )
            
            print("EtihadBoarding Live Activity requested. ID: \(newActivity.id)")
            refreshActivities()
        } catch {
            print("Error requesting live activity: \(error.localizedDescription)")
        }
    }
    
    func startChannelActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are disabled on this device.")
            return
        }
        
        let trimmedChannelID = channelID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedChannelID.isEmpty else {
            print("Channel ID cannot be empty.")
            return
        }
        
        let attributes = EtihadBoardingAttributes(
            liveActivityData: LiveActivityData(channelID: trimmedChannelID),
            flightNumber: "EY 62",
            departureAirport: "LHR",
            arrivalAirport: "AUH",
            departureTime: "22:10",
            arrivalTime: "08:05",
            flightDuration: "6h 55m",
            terminal: "Terminal A",
            gate: "Gate D4B"
        )
        let initialContentState = EtihadBoardingAttributes.ContentState(
            boardingStatus: "Check-in Open",
            statusMessage: "Check-in opens 24 hours before departure",
            timeStatus: "On time"
        )
        
        do {
            if #available(iOS 18.0, *) {
                let newActivity = try Activity<EtihadBoardingAttributes>.request(
                    attributes: attributes,
                    contentState: initialContentState,
                    pushType: .channel(trimmedChannelID)
                )
                print("EtihadBoarding Live Activity (CHANNEL: \(trimmedChannelID)) requested. ID: \(newActivity.id)")
            }
            refreshActivities()
        } catch {
            print("Error requesting live activity: \(error.localizedDescription)")
        }
    }
    
    func endSelectedActivity(activity: Activity<EtihadBoardingAttributes>, immediate: Bool) {
        Task {
            if immediate {
                await activity.end(dismissalPolicy: .immediate)
            } else {
                await activity.end(dismissalPolicy: .default)
            }
            
            print("Live Activity ended: \(activity.id)")
            refreshActivities()
        }
    }
}

// MARK: - Preview

#Preview {
    if #available(iOS 16.1, *) {
        EtihadBoardingLiveActivityView()
    } else {
        Text("Requires iOS 16.1 or later")
    }
}
