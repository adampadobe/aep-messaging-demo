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

// MARK: - EtihadPremiumLiveActivity Widget

struct EtihadPremiumLiveActivity: Widget {
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EtihadPremiumFlightAttributes.self) { context in
            EtihadPremiumFlightLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: "airplane.departure")
                            .foregroundColor(.white)
                        Text(context.attributes.departureAirport)
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    HStack {
                        Text(context.attributes.arrivalAirport)
                            .font(.title3)
                            .foregroundColor(.white)
                        Image(systemName: "airplane.arrival")
                            .foregroundColor(.white)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        Text(context.attributes.flightNumber)
                            .font(.headline)
                            .foregroundColor(.white)
                        if context.state.wifiAvailable {
                            HStack(spacing: 4) {
                                Image(systemName: "wifi")
                                    .font(.caption)
                                Text("WiFi Available")
                                    .font(.caption)
                            }
                            .foregroundColor(Color.green)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(context.attributes.departureTime)
                                .font(.caption)
                            Text(context.attributes.departureDate)
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                        Spacer()
                        Text(context.state.status)
                            .font(.subheadline)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                context.state.status == "Departed" ? Color.blue.opacity(0.3) :
                                context.state.status == "On time" ? Color.green.opacity(0.3) :
                                Color.orange.opacity(0.3)
                            )
                            .cornerRadius(6)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(context.attributes.arrivalTime)
                                .font(.caption)
                            Text(context.attributes.arrivalDate)
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                    .foregroundColor(.white)
                }
            } compactLeading: {
                Image(systemName: "airplane")
                    .foregroundColor(.white)
            } compactTrailing: {
                Text(context.attributes.flightNumber)
                    .font(.caption)
                    .foregroundColor(.white)
            } minimal: {
                Image(systemName: "airplane")
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Lock Screen / Banner View

struct EtihadPremiumFlightLiveActivityView: View {
    let context: ActivityViewContext<EtihadPremiumFlightAttributes>
    
    var body: some View {
        HStack(spacing: 0) {
            // Left side - Etihad icon
            VStack {
                Image("EtihadIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 35, height: 35)
            }
            .frame(width: 60)
            .padding(.leading, 12)
            
            // Middle - Flight info
            VStack(spacing: 8) {
                // Flight number at top
                HStack {
                    Text(context.attributes.flightNumber)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    // Status badge
                    Text(context.state.status)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            context.state.status == "Departed" ? Color.blue.opacity(0.5) :
                            context.state.status == "On time" ? Color.green :
                            Color.orange
                        )
                        .cornerRadius(4)
                        .foregroundColor(.white)
                }
                
                // Route with airplane and progress line
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.departureAirport)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text(context.attributes.departureTime)
                            .font(.caption)
                            .foregroundColor(Color.green)
                        Text(context.attributes.departureDate)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // Progress line with airplane
                    GeometryReader { geo in
                        let progress = CGFloat(context.state.journeyProgress) / 100.0
                        let width = geo.size.width
                        
                        ZStack(alignment: .leading) {
                            // Background dashed line
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)
                            
                            // Progress line
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: width * progress, height: 2)
                            
                            // Airplane icon
                            Image(systemName: "airplane")
                                .font(.caption)
                                .foregroundColor(.white)
                                .offset(x: max(0, min(width * progress - 8, width - 16)))
                        }
                        .frame(height: 20)
                    }
                    .frame(width: 80, height: 20)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.attributes.arrivalAirport)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text(context.attributes.arrivalTime)
                            .font(.caption)
                            .foregroundColor(Color.green)
                        Text(context.attributes.arrivalDate)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                // WiFi status at bottom
                if context.state.wifiAvailable {
                    HStack(spacing: 4) {
                        Image(systemName: "wifi")
                            .font(.caption)
                        Text(context.state.currentLocation)
                            .font(.caption)
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity)
        // Etihad dark teal/navy background matching the image
        .background(Color(red: 0.18, green: 0.29, blue: 0.33))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview("Notification", as: .content,
         using: EtihadPremiumFlightAttributes(
            liveActivityData: LiveActivityData(liveActivityID: "EY62-TEST"),
            flightNumber: "EY 62",
            departureAirport: "LHR",
            arrivalAirport: "AUH",
            departureTime: "22:05",
            arrivalTime: "07:55",
            departureDate: "On time",
            arrivalDate: "On time"
         )
) {
    EtihadPremiumLiveActivity()
} contentStates: {
    EtihadPremiumFlightAttributes.ContentState(
        status: "Departed",
        wifiAvailable: true,
        currentLocation: "Wi-fi available onboard",
        journeyProgress: 25
    )
    EtihadPremiumFlightAttributes.ContentState(
        status: "On time",
        wifiAvailable: true,
        currentLocation: "Wi-fi available onboard",
        journeyProgress: 50
    )
    EtihadPremiumFlightAttributes.ContentState(
        status: "Landed",
        wifiAvailable: false,
        currentLocation: "Welcome to Abu Dhabi",
        journeyProgress: 100
    )
}
