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

import ActivityKit
import Foundation
import AEPMessagingLiveActivity

/// One reusable Travel Live Activity that can render flight, boarding, or
/// airport phases. The look is driven entirely by the push payload via a
/// hex `Theme` and a pre-cached logo file in the shared App Group.
@available(iOS 16.1, *)
struct TravelLiveActivityAttributes: LiveActivityAttributes {

    var liveActivityData: LiveActivityData

    /// Shared App Group identifier (e.g. "group.com.adampadobe.aep-messaging-demo").
    /// Lives in the payload so a single demo build can target any group the
    /// host app + widget have entitlement for.
    let appGroupID: String

    /// File name (inside the App Group container) of the cached brand logo.
    /// `nil` means render the brand-name fallback.
    let logoFileName: String?

    /// Optional brand label used for the text fallback when no logo is cached.
    let brandName: String?

    /// Phases supported by the Travel Live Activity layout.
    enum Phase: String, Codable, Hashable, CaseIterable {
        case flight
        case boarding
        case airport
    }

    /// Hex-driven palette delivered with every update.
    struct Theme: Codable, Hashable {
        let background: String              // e.g. "#0F7D47"
        let accent: String                  // e.g. "#69D444"
        let onBackground: String?           // optional, defaults to "#FFFFFF"
    }

    /// Mutable content. All route metadata lives here so push updates can
    /// change phase, colors, route or schedule mid-activity.
    struct ContentState: Codable, Hashable {
        let phase: Phase
        let theme: Theme

        // Common
        let flightNumber: String?
        let departureAirport: String?
        let arrivalAirport: String?
        let departureTime: String?
        let arrivalTime: String?
        let timeStatus: String?             // "On time" | "Delayed" | "Boarding"

        // phase = .flight
        let status: String?                 // "Departed" | "Landed" | ...
        let journeyProgress: Int?           // 0...100
        let wifiAvailable: Bool?
        let currentLocation: String?

        // phase = .boarding
        let boardingStatus: String?         // "Check-in Open" .. "Departed"
        let terminal: String?
        let gate: String?
        let statusMessage: String?          // e.g. "Terminal A - Gate D4B"

        // phase = .airport
        let dwellTimeMessage: String?       // e.g. "Visit Al Dahlah Lounge - Level 2"
    }
}

@available(iOS 16.1, *)
extension TravelLiveActivityAttributes: LiveActivityAssuranceDebuggable {

    /// Single fixture used by Assurance previews; demonstrates the flight phase.
    /// Boarding/airport fixtures are exposed via the dedicated helpers below
    /// so demo and preview code can show all three.
    static func getDebugInfo() -> (attributes: TravelLiveActivityAttributes, state: ContentState) {
        return (debugAttributes, debugFlightState)
    }

    static var debugAttributes: TravelLiveActivityAttributes {
        TravelLiveActivityAttributes(
            liveActivityData: LiveActivityData(channelID: "travel-demo"),
            appGroupID: TravelAppGroup.identifier,
            logoFileName: nil,
            brandName: "Acme Air"
        )
    }

    static var debugFlightState: ContentState {
        ContentState(
            phase: .flight,
            theme: Theme(background: "#0F7D47", accent: "#69D444", onBackground: "#FFFFFF"),
            flightNumber: "AA 101",
            departureAirport: "RUH",
            arrivalAirport: "DXB",
            departureTime: "18:45",
            arrivalTime: "21:10",
            timeStatus: "On time",
            status: "Departed",
            journeyProgress: 25,
            wifiAvailable: true,
            currentLocation: "Wi-Fi available onboard",
            boardingStatus: nil,
            terminal: nil,
            gate: nil,
            statusMessage: nil,
            dwellTimeMessage: nil
        )
    }

    static var debugBoardingState: ContentState {
        ContentState(
            phase: .boarding,
            theme: Theme(background: "#1F4FA8", accent: "#FFD23F", onBackground: "#FFFFFF"),
            flightNumber: "AA 101",
            departureAirport: "RUH",
            arrivalAirport: "DXB",
            departureTime: "18:45",
            arrivalTime: "21:10",
            timeStatus: "On time",
            status: nil,
            journeyProgress: nil,
            wifiAvailable: nil,
            currentLocation: nil,
            boardingStatus: "Boarding now",
            terminal: "Terminal A",
            gate: "D4B",
            statusMessage: "Terminal A - Gate D4B",
            dwellTimeMessage: nil
        )
    }

    static var debugAirportState: ContentState {
        ContentState(
            phase: .airport,
            theme: Theme(background: "#1A1A2E", accent: "#E94560", onBackground: "#FFFFFF"),
            flightNumber: "AA 101",
            departureAirport: "RUH",
            arrivalAirport: "DXB",
            departureTime: "18:45",
            arrivalTime: "21:10",
            timeStatus: "On time",
            status: nil,
            journeyProgress: nil,
            wifiAvailable: nil,
            currentLocation: nil,
            boardingStatus: "Explore Airport",
            terminal: "Terminal A",
            gate: "D4B",
            statusMessage: "Gate opens in 90 minutes",
            dwellTimeMessage: "Visit Al Dahlah Lounge - Level 2"
        )
    }
}

/// Default App Group used by the demo. Match this to the App Group
/// granted to both the host app and the widget extension.
enum TravelAppGroup {
    static let identifier = "group.com.adampadobe.aep-messaging-demo"
}
