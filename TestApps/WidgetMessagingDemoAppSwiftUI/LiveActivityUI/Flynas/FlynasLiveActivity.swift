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

// MARK: - FlynasLiveActivity Widget

struct FlynasLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FlynasFlightAttributes.self) { context in
            FlynasFlightLiveActivityView(context: context)
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
                            .foregroundColor(Color.white.opacity(0.9))
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
                                .foregroundColor(flynasAccentColor)
                        }
                        Spacer()
                        Text(context.state.status)
                            .font(.subheadline)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                context.state.status == "Departed" ? flynasAccentColor.opacity(0.35) :
                                context.state.status == "On time" ? flynasAccentColor.opacity(0.55) :
                                Color.orange.opacity(0.3)
                            )
                            .cornerRadius(6)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(context.attributes.arrivalTime)
                                .font(.caption)
                            Text(context.attributes.arrivalDate)
                                .font(.caption2)
                                .foregroundColor(flynasAccentColor)
                        }
                    }
                    .foregroundColor(.white)
                }
            } compactLeading: {
                Text("F")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            } compactTrailing: {
                Text(context.attributes.flightNumber)
                    .font(.caption)
                    .foregroundColor(.white)
            } minimal: {
                Text("F")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .keylineTint(flynasAccentColor)
        }
    }
}

// MARK: - Lock Screen / Banner View

struct FlynasFlightLiveActivityView: View {
    let context: ActivityViewContext<FlynasFlightAttributes>

    var body: some View {
        HStack(spacing: 0) {
            VStack {
                FlynasBrandMark()
            }
            .frame(width: 60)
            .padding(.leading, 12)

            VStack(spacing: 8) {
                HStack {
                    Text(context.attributes.flightNumber)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Text(context.state.status)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            context.state.status == "Departed" ? flynasAccentColor.opacity(0.5) :
                            context.state.status == "On time" ? flynasAccentColor :
                            Color.orange
                        )
                        .cornerRadius(4)
                        .foregroundColor(.white)
                }

                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.departureAirport)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text(context.attributes.departureTime)
                            .font(.caption)
                            .foregroundColor(flynasAccentColor)
                        Text(context.attributes.departureDate)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    GeometryReader { geo in
                        let progress = CGFloat(context.state.journeyProgress) / 100.0
                        let width = geo.size.width

                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)

                            Rectangle()
                                .fill(Color.white)
                                .frame(width: width * progress, height: 2)

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
                            .foregroundColor(flynasAccentColor)
                        Text(context.attributes.arrivalDate)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

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
        .background(flynasBackgroundColor)
        .cornerRadius(12)
    }
}

private struct FlynasBrandMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )

            Text("flynas")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(width: 42, height: 42)
    }
}

private let flynasBackgroundColor = Color(red: 0.06, green: 0.49, blue: 0.28)
private let flynasAccentColor = Color(red: 0.41, green: 0.83, blue: 0.27)

#Preview("Notification", as: .content,
         using: FlynasFlightAttributes(
            liveActivityData: LiveActivityData(liveActivityID: "XY224-TEST"),
            flightNumber: "XY 224",
            departureAirport: "RUH",
            arrivalAirport: "DXB",
            departureTime: "18:45",
            arrivalTime: "21:10",
            departureDate: "On time",
            arrivalDate: "On time"
         )
) {
    FlynasLiveActivity()
} contentStates: {
    FlynasFlightAttributes.ContentState(
        status: "Departed",
        wifiAvailable: true,
        currentLocation: "Wi-Fi available onboard",
        journeyProgress: 25
    )
    FlynasFlightAttributes.ContentState(
        status: "On time",
        wifiAvailable: true,
        currentLocation: "Wi-Fi available onboard",
        journeyProgress: 50
    )
    FlynasFlightAttributes.ContentState(
        status: "Landed",
        wifiAvailable: false,
        currentLocation: "Welcome to Dubai",
        journeyProgress: 100
    )
}
