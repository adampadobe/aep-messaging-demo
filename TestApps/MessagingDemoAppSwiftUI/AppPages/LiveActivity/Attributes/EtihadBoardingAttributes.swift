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
struct EtihadBoardingAttributes: LiveActivityAttributes {
    
    var liveActivityData: LiveActivityData
    
    // Static attributes
    let flightNumber: String
    let departureAirport: String
    let arrivalAirport: String
    let departureTime: String
    let arrivalTime: String
    let flightDuration: String
    let terminal: String
    let gate: String
    
    // Dynamic attributes
    public struct ContentState: Codable, Hashable {
        let boardingStatus: String  // "Check-in Open", "Checked In", "Go to Security", "Boarding Now", "Gate Closing", "Departed"
        let statusMessage: String   // e.g., "Terminal A - Gate D4B"
        let timeStatus: String      // "On time", "Delayed", "Boarding"
    }
}

@available(iOS 16.1, *)
extension EtihadBoardingAttributes : LiveActivityAssuranceDebuggable {
    static func getDebugInfo() -> (attributes: EtihadBoardingAttributes, state: ContentState) {
        return (EtihadBoardingAttributes(
            liveActivityData: LiveActivityData(channelID: "etihad-boarding"),
            flightNumber: "EY 62",
            departureAirport: "LHR",
            arrivalAirport: "AUH",
            departureTime: "22:10",
            arrivalTime: "08:05",
            flightDuration: "6h 55m",
            terminal: "Terminal A",
            gate: "Gate D4B"
        ),
        ContentState(
            boardingStatus: "Boarding now",
            statusMessage: "Terminal A - Gate D4B",
            timeStatus: "On time"
        ))
    }
}
