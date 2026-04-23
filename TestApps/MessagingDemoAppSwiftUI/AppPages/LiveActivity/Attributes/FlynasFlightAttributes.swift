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

@available(iOS 16.1, *)
struct FlynasFlightAttributes: LiveActivityAttributes {

    var liveActivityData: LiveActivityData

    // Static attributes
    let flightNumber: String
    let departureAirport: String
    let arrivalAirport: String
    let departureTime: String
    let arrivalTime: String
    let departureDate: String
    let arrivalDate: String

    // Dynamic attributes
    public struct ContentState: Codable, Hashable {
        let status: String
        let wifiAvailable: Bool
        let currentLocation: String
        let journeyProgress: Int
    }
}

@available(iOS 16.1, *)
extension FlynasFlightAttributes: LiveActivityAssuranceDebuggable {
    static func getDebugInfo() -> (attributes: FlynasFlightAttributes, state: ContentState) {
        return (
            FlynasFlightAttributes(
                liveActivityData: LiveActivityData(channelID: "flynas-flight"),
                flightNumber: "XY 224",
                departureAirport: "RUH",
                arrivalAirport: "DXB",
                departureTime: "18:45",
                arrivalTime: "21:10",
                departureDate: "On time",
                arrivalDate: "On time"
            ),
            ContentState(
                status: "Departed",
                wifiAvailable: true,
                currentLocation: "Wi-Fi available onboard",
                journeyProgress: 25
            )
        )
    }
}
