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

// MARK: - KSIAAirportLiveActivity Widget

struct KSIAAirportLiveActivity: Widget {
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: KSIAAirportAttributes.self) { context in
            KSIAAirportLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image("KSIALogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 20)
                        VStack(alignment: .leading) {
                            Text(context.attributes.flightNumber)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(context.attributes.airline)
                                .font(.caption)
                                .foregroundColor(Color(red: 0.80, green: 0.67, blue: 0.20))
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text(context.state.timeStatus)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                context.state.timeStatus == "On time" ? Color.green :
                                context.state.timeStatus == "Delayed" ? Color.orange :
                                Color(red: 0.80, green: 0.67, blue: 0.20)
                            )
                            .cornerRadius(4)
                            .foregroundColor(.white)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        HStack {
                            Text(context.attributes.departureAirport)
                                .font(.title3)
                            Image(systemName: "airplane")
                            Text(context.attributes.arrivalAirport)
                                .font(.title3)
                        }
                        .foregroundColor(.white)
                        
                        Text(context.state.boardingStatus)
                            .font(.caption)
                            .foregroundColor(Color(red: 0.80, green: 0.67, blue: 0.20))
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 4) {
                        HStack {
                            Text(context.attributes.departureTime)
                            Text(context.attributes.flightDuration)
                                .foregroundColor(.white.opacity(0.6))
                            Text(context.attributes.arrivalTime)
                        }
                        .font(.caption2)
                        .foregroundColor(.white)
                        
                        Text("💎 \(context.state.dwellTimeMessage)")
                            .font(.caption2)
                            .foregroundColor(Color(red: 0.80, green: 0.67, blue: 0.20))
                    }
                }
            } compactLeading: {
                Image("KSIALogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 12)
            } compactTrailing: {
                Text(context.attributes.flightNumber)
                    .font(.caption)
                    .foregroundColor(Color(red: 0.80, green: 0.67, blue: 0.20))
            } minimal: {
                Image("KSIALogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 8)
            }
        }
    }
}

// MARK: - Lock Screen / Banner View

struct KSIAAirportLiveActivityView: View {
    let context: ActivityViewContext<KSIAAirportAttributes>
    
    var body: some View {
        HStack(spacing: 0) {
            // Left side - KSIA/Riyadh Air icon
            VStack {
                Image("KSIALogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 32)
            }
            .frame(width: 50)
            .padding(.leading, 8)
            
            // Middle - Flight and dwell time info
            VStack(alignment: .leading, spacing: 8) {
                // Top row: Airline + Flight Number on same line + status badge
                HStack {
                    HStack(spacing: 6) {
                        Text(context.attributes.airline)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Text("-")
                            .foregroundColor(.white.opacity(0.5))
                        Text(context.attributes.flightNumber)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.80, green: 0.67, blue: 0.20))
                    }
                    
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
                            Color(red: 0.80, green: 0.67, blue: 0.20)
                        )
                        .cornerRadius(4)
                        .foregroundColor(.white)
                }
                
                // Route with boarding status centered over airplane
                VStack(spacing: 4) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.attributes.departureAirport)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text(context.attributes.departureTime)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        // Centered boarding status over airplane
                        VStack(spacing: 2) {
                            Text(context.state.boardingStatus)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.80, green: 0.67, blue: 0.20))
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color(red: 0.80, green: 0.67, blue: 0.20).opacity(0.5))
                                    .frame(width: 4, height: 4)
                                
                                Image(systemName: "airplane")
                                    .font(.caption)
                                    .foregroundColor(Color(red: 0.80, green: 0.67, blue: 0.20))
                                
                                Rectangle()
                                    .fill(Color(red: 0.80, green: 0.67, blue: 0.20).opacity(0.5))
                                    .frame(width: 20, height: 1)
                            }
                            
                            Text(context.attributes.flightDuration)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(context.attributes.arrivalAirport)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text(context.attributes.arrivalTime)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                
                // Dwell time promotion message
                HStack(spacing: 4) {
                    Text("💎")
                        .font(.caption)
                    Text(context.state.dwellTimeMessage)
                        .font(.caption)
                        .foregroundColor(Color(red: 0.80, green: 0.67, blue: 0.20))
                }
                
                // Status message
                Text(context.state.statusMessage)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity)
        // KSIA dark background (from the image - dark navy/black)
        .background(Color(red: 0.12, green: 0.12, blue: 0.15))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview("Notification", as: .content,
         using: KSIAAirportAttributes(
            liveActivityData: LiveActivityData(liveActivityID: "KSIA-TEST"),
            flightNumber: "RX 123",
            airline: "Riyadh Air",
            departureAirport: "RUH",
            arrivalAirport: "DXB",
            departureTime: "14:30",
            arrivalTime: "17:45",
            flightDuration: "3h 15m",
            terminal: "Terminal 1",
            gate: "A12",
            seatNumber: "12A"
         )
) {
    KSIAAirportLiveActivity()
} contentStates: {
    KSIAAirportAttributes.ContentState(
        boardingStatus: "Check-in Complete",
        statusMessage: "Proceed to security",
        timeStatus: "On time",
        dwellTimeMessage: "Explore KSIA's dining & shopping"
    )
    KSIAAirportAttributes.ContentState(
        boardingStatus: "Security Clear",
        statusMessage: "Gate opens in 90 minutes",
        timeStatus: "On time",
        dwellTimeMessage: "Visit Al Dahlah Lounge - Level 2"
    )
    KSIAAirportAttributes.ContentState(
        boardingStatus: "Explore Airport",
        statusMessage: "Gate opens in 60 minutes",
        timeStatus: "On time",
        dwellTimeMessage: "Duty Free - 30% off luxury brands"
    )
    KSIAAirportAttributes.ContentState(
        boardingStatus: "Boarding Soon",
        statusMessage: "Gate A12 - Please proceed",
        timeStatus: "On time",
        dwellTimeMessage: "Grab a coffee at Starbucks - Gate A"
    )
    KSIAAirportAttributes.ContentState(
        boardingStatus: "Boarding Now",
        statusMessage: "Terminal 1 - Gate A12",
        timeStatus: "Boarding",
        dwellTimeMessage: "Final call - Proceed to gate"
    )
}
