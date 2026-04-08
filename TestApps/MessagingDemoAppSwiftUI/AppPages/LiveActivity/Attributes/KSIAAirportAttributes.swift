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
struct KSIAAirportAttributes: LiveActivityAttributes {
    
    var liveActivityData: LiveActivityData
    
    // Static attributes
    let flightNumber: String
    let airline: String  // "Riyadh Air"
    let departureAirport: String
    let arrivalAirport: String
    let departureTime: String
    let arrivalTime: String
    let flightDuration: String
    let terminal: String
    let gate: String
    let seatNumber: String
    
    // Dynamic attributes
    public struct ContentState: Codable, Hashable {
        let boardingStatus: String  // "Check-in", "Security Clear", "Explore Airport", "Boarding Soon", "Boarding Now", "Gate Closing", "Departed"
        let statusMessage: String   // e.g., "Enjoy dining & shopping - Gate opens in 90 min"
        let timeStatus: String      // "On time", "Delayed", "Boarding"
        let dwellTimeMessage: String  // e.g., "Visit Al Dahlah Lounge - Level 2"
    }
}

@available(iOS 16.1, *)
extension KSIAAirportAttributes : LiveActivityAssuranceDebuggable {
    static func getDebugInfo() -> (attributes: KSIAAirportAttributes, state: ContentState) {
        return (KSIAAirportAttributes(
            liveActivityData: LiveActivityData(channelID: "ksia-boarding"),
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
        ),
        ContentState(
            boardingStatus: "Explore Airport",
            statusMessage: "Gate opens in 90 minutes",
            timeStatus: "On time",
            dwellTimeMessage: "Visit Al Dahlah Lounge - Level 2"
        ))
    }
}
