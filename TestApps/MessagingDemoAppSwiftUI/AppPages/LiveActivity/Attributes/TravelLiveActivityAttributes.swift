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

    /// Comprehensive enumeration of journey stages for a travel companion
    /// experience. Covers the natural flow from check-in through arrival.
    /// Each stage has a default display label and a default semantic color
    /// (red / amber / green / blue) used by the status pill — the payload
    /// can override either via `boardingStatus` (free text) or `statusColor`
    /// (hex). Order of cases is the natural travel order, used for the
    /// presenter UI picker.
    enum JourneyStage: String, Codable, Hashable, CaseIterable {
        // Pre-airport
        case checkInOpen     = "checkInOpen"
        case checkedIn       = "checkedIn"
        // Security & airside
        case goToSecurity    = "goToSecurity"
        case throughSecurity = "throughSecurity"
        case exploreAirport  = "exploreAirport"
        case goToGate        = "goToGate"
        // Gate / boarding
        case boardingSoon    = "boardingSoon"
        case boardingNow     = "boardingNow"
        case finalCall       = "finalCall"
        case gateChange      = "gateChange"
        case gateClosing     = "gateClosing"
        case gateClosed      = "gateClosed"
        case boarded         = "boarded"
        // Flight
        case departed        = "departed"
        case inFlight        = "inFlight"
        case landed          = "landed"
        // Arrival
        case arrivedAtGate   = "arrivedAtGate"
        case baggageReady    = "baggageReady"
        // Disruption (can occur at any time)
        case delayed         = "delayed"
        case cancelled       = "cancelled"

        /// Default label shown on the status pill when `boardingStatus` is
        /// not provided.
        var defaultLabel: String {
            switch self {
            case .checkInOpen:     return "Check-in Open"
            case .checkedIn:       return "Checked In"
            case .goToSecurity:    return "Go to Security"
            case .throughSecurity: return "Through Security"
            case .exploreAirport:  return "Explore Airport"
            case .goToGate:        return "Go to Gate"
            case .boardingSoon:    return "Boarding Soon"
            case .boardingNow:     return "Boarding Now"
            case .finalCall:       return "Final Call"
            case .gateChange:      return "Gate Change"
            case .gateClosing:     return "Gate Closing"
            case .gateClosed:      return "Gate Closed"
            case .boarded:         return "Boarded"
            case .departed:        return "Departed"
            case .inFlight:        return "In Flight"
            case .landed:          return "Landed"
            case .arrivedAtGate:   return "At Gate"
            case .baggageReady:    return "Baggage Ready"
            case .delayed:         return "Delayed"
            case .cancelled:       return "Cancelled"
            }
        }

        /// Default semantic-color hex for the status pill background.
        /// Overridable via the `statusColor` field in `ContentState`.
        ///
        ///   • Red   – urgent / negative (gate closing, cancelled, delayed)
        ///   • Amber – needs attention   (boarding soon, gate change, final call, go-to-gate)
        ///   • Green – positive          (boarding now, boarded, checked in, landed, baggage ready)
        ///   • Blue  – informational     (check-in open, in-flight, departed, security, explore)
        var defaultColorHex: String {
            switch self {
            // Red
            case .gateClosing, .gateClosed, .cancelled:
                return "#E53935"
            // Amber / orange
            case .gateChange, .boardingSoon, .finalCall, .goToGate, .delayed:
                return "#F39C12"
            // Green
            case .boardingNow, .boarded, .checkedIn, .throughSecurity, .landed, .baggageReady, .arrivedAtGate:
                return "#27AE60"
            // Blue
            case .checkInOpen, .goToSecurity, .exploreAirport, .departed, .inFlight:
                return "#2D7AB8"
            }
        }

        /// Suggested phase layout for the activity when this stage fires.
        /// Used as a fallback when the payload doesn't pin a `phase` —
        /// keeps the UI's "Quick scenario" buttons short.
        var suggestedPhase: Phase {
            switch self {
            case .checkInOpen, .checkedIn, .goToSecurity, .throughSecurity,
                 .exploreAirport, .goToGate:
                return .airport
            case .boardingSoon, .boardingNow, .finalCall, .gateChange,
                 .gateClosing, .gateClosed, .boarded:
                return .boarding
            case .departed, .inFlight, .landed, .arrivedAtGate, .baggageReady,
                 .delayed, .cancelled:
                return .flight
            }
        }
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
        let boardingStatus: String?         // free-text label, wins over `journeyStage.defaultLabel`
        let terminal: String?
        let gate: String?
        let seatNumber: String?             // e.g. "12A"
        let statusMessage: String?          // e.g. "Terminal A - Gate D4B"

        // phase = .airport
        let dwellTimeMessage: String?       // e.g. "Visit Al Dahlah Lounge - Level 2"

        // Cross-phase journey companion
        /// Optional, payload-driven journey stage. When present the status
        /// pill auto-picks a default label + color, overridable by
        /// `boardingStatus` and `statusColor`.
        let journeyStage: JourneyStage?

        /// Optional hex (e.g. "#E53935") that overrides the per-stage
        /// default color of the status pill background. Useful for
        /// brand-specific palettes that still need urgent-red moments.
        let statusColor: String?
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
            seatNumber: nil,
            statusMessage: nil,
            dwellTimeMessage: nil,
            journeyStage: .departed,
            statusColor: nil
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
            boardingStatus: nil,
            terminal: "Terminal A",
            gate: "D4B",
            seatNumber: "12A",
            statusMessage: "Terminal A - Gate D4B",
            dwellTimeMessage: nil,
            journeyStage: .boardingNow,
            statusColor: nil
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
            boardingStatus: nil,
            terminal: "Terminal A",
            gate: "D4B",
            seatNumber: "12A",
            statusMessage: "Gate opens in 90 minutes",
            dwellTimeMessage: "Visit Al Dahlah Lounge - Level 2",
            journeyStage: .exploreAirport,
            statusColor: nil
        )
    }
}

/// Default App Group used by the demo. Match this to the App Group
/// granted to both the host app and the widget extension.
enum TravelAppGroup {
    static let identifier = "group.com.adampadobe.aep-messaging-demo"
}
