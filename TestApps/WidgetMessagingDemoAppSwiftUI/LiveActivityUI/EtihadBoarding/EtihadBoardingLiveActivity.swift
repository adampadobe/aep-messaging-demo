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

import WidgetKit
import ActivityKit
import SwiftUI
import AEPMessagingLiveActivity

// MARK: - EtihadBoardingLiveActivity Widget

struct EtihadBoardingLiveActivity: Widget {
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EtihadBoardingAttributes.self) { context in
            EtihadBoardingLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: "airplane.departure")
                            .font(.title2)
                            .foregroundColor(.white)
                        VStack(alignment: .leading) {
                            Text(context.attributes.flightNumber)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(context.state.boardingStatus)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text(context.state.timeStatus)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(4)
                            .foregroundColor(.white)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    HStack {
                        Text(context.attributes.departureAirport)
                            .font(.title3)
                        Image(systemName: "airplane")
                        Text(context.attributes.arrivalAirport)
                            .font(.title3)
                    }
                    .foregroundColor(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 4) {
                        Text(context.state.statusMessage)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        HStack {
                            Text(context.attributes.departureTime)
                            Text(context.attributes.flightDuration)
                                .foregroundColor(.white.opacity(0.6))
                            Text(context.attributes.arrivalTime)
                        }
                        .font(.caption2)
                        .foregroundColor(.white)
                    }
                }
            } compactLeading: {
                Image(systemName: "airplane.departure")
                    .foregroundColor(.white)
            } compactTrailing: {
                Text(context.attributes.flightNumber)
                    .font(.caption)
                    .foregroundColor(.white)
            } minimal: {
                Image(systemName: "airplane.departure")
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Lock Screen / Banner View

struct EtihadBoardingLiveActivityView: View {
    let context: ActivityViewContext<EtihadBoardingAttributes>
    
    var body: some View {
        HStack(spacing: 0) {
            // Left side - Etihad icon
            VStack {
                Image("EtihadIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
            }
            .frame(width: 50)
            .padding(.leading, 8)
            
            // Middle - Flight info
            VStack(alignment: .leading, spacing: 8) {
                // Top row: Flight number and status badge
                HStack {
                    Text(context.attributes.flightNumber)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Status badge
                    Text(context.state.timeStatus)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            context.state.timeStatus == "On time" ? Color.green :
                            context.state.timeStatus == "Delayed" ? Color.orange :
                            Color.blue
                        )
                        .cornerRadius(4)
                        .foregroundColor(.white)
                }
                
                // Boarding status message
                Text(context.state.boardingStatus)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                
                // Route with times
                HStack(spacing: 12) {
                    Text(context.attributes.departureAirport)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 4, height: 4)
                        
                        Image(systemName: "airplane")
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 20, height: 1)
                    }
                    
                    Text(context.attributes.arrivalAirport)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                // Times row
                HStack {
                    Text(context.attributes.departureTime)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(context.attributes.flightDuration)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text(context.attributes.arrivalTime)
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                
                // Terminal and gate info
                Text(context.state.statusMessage)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity)
        // Etihad dark teal/navy background
        .background(Color(red: 0.20, green: 0.31, blue: 0.35))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview("Notification", as: .content,
         using: EtihadBoardingAttributes(
            liveActivityData: LiveActivityData(liveActivityID: "EY62-BOARDING-TEST"),
            flightNumber: "EY 62",
            departureAirport: "LHR",
            arrivalAirport: "AUH",
            departureTime: "22:10",
            arrivalTime: "08:05",
            flightDuration: "6h 55m",
            terminal: "Terminal A",
            gate: "Gate D4B"
         )
) {
    EtihadBoardingLiveActivity()
} contentStates: {
    EtihadBoardingAttributes.ContentState(
        boardingStatus: "Check-in Open",
        statusMessage: "Check-in opens 24 hours before departure",
        timeStatus: "On time"
    )
    EtihadBoardingAttributes.ContentState(
        boardingStatus: "Checked In",
        statusMessage: "Terminal A - Gate D4B",
        timeStatus: "On time"
    )
    EtihadBoardingAttributes.ContentState(
        boardingStatus: "Go to Security",
        statusMessage: "Terminal A - Gate D4B",
        timeStatus: "On time"
    )
    EtihadBoardingAttributes.ContentState(
        boardingStatus: "Boarding now",
        statusMessage: "Terminal A - Gate D4B",
        timeStatus: "On time"
    )
    EtihadBoardingAttributes.ContentState(
        boardingStatus: "Gate Closing",
        statusMessage: "Terminal A - Gate D4B",
        timeStatus: "Boarding"
    )
}
