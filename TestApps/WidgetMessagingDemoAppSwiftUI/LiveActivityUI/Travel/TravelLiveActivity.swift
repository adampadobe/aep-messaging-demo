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
#if canImport(UIKit)
import UIKit
#endif

// MARK: - TravelLiveActivity Widget

/// Repeatable, themeable Travel Live Activity. Supports three layouts –
/// flight, boarding, airport – chosen dynamically by the payload, with a
/// hex-driven color theme and a remote logo pre-cached by the app.
struct TravelLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TravelLiveActivityAttributes.self) { context in
            TravelLockScreenView(context: context)
        } dynamicIsland: { context in
            let theme = context.state.theme
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: leadingIcon(for: context.state.phase))
                            .foregroundColor(theme.foregroundColor)
                        Text(context.state.departureAirport ?? "")
                            .font(.title3)
                            .foregroundColor(theme.foregroundColor)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 6) {
                        Text(context.state.arrivalAirport ?? "")
                            .font(.title3)
                            .foregroundColor(theme.foregroundColor)
                        Image(systemName: trailingIcon(for: context.state.phase))
                            .foregroundColor(theme.foregroundColor)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        Text(context.state.flightNumber ?? "")
                            .font(.headline)
                            .foregroundColor(theme.foregroundColor)
                        if let brand = context.attributes.brandName {
                            Text(brand)
                                .font(.caption2)
                                .foregroundColor(theme.foregroundColor.opacity(0.75))
                        }
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    expandedBottom(for: context)
                }
            } compactLeading: {
                Text(String((context.attributes.brandName ?? "T").prefix(1)).uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(theme.accentColor)
            } compactTrailing: {
                Text(context.state.flightNumber ?? "")
                    .font(.caption)
                    .foregroundColor(theme.accentColor)
            } minimal: {
                Image(systemName: leadingIcon(for: context.state.phase))
                    .foregroundColor(theme.accentColor)
            }
            .keylineTint(theme.accentColor)
        }
    }

    @ViewBuilder
    private func expandedBottom(for context: ActivityViewContext<TravelLiveActivityAttributes>) -> some View {
        let theme = context.state.theme
        let pillColor = context.state.effectiveStatusColor
        let pillLabel = context.state.effectiveStatusLabel
        switch context.state.phase {
        case .flight:
            HStack {
                VStack(alignment: .leading) {
                    Text(context.state.departureTime ?? "")
                        .font(.caption)
                    Text(context.state.timeStatus ?? "")
                        .font(.caption2)
                        .foregroundColor(theme.accentColor)
                }
                Spacer()
                if let pillLabel {
                    Text(pillLabel)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(pillColor)
                        .cornerRadius(6)
                        .foregroundColor(theme.foregroundColor)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(context.state.arrivalTime ?? "")
                        .font(.caption)
                    Text(context.state.timeStatus ?? "")
                        .font(.caption2)
                        .foregroundColor(theme.accentColor)
                }
            }
            .foregroundColor(theme.foregroundColor)
        case .boarding:
            VStack(spacing: 4) {
                if let pillLabel {
                    Text(pillLabel)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(pillColor)
                        .cornerRadius(6)
                        .foregroundColor(theme.foregroundColor)
                }
                if let message = context.state.statusMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(theme.foregroundColor.opacity(0.85))
                }
            }
        case .airport:
            VStack(spacing: 4) {
                if let pillLabel {
                    Text(pillLabel)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(pillColor)
                        .cornerRadius(6)
                        .foregroundColor(theme.foregroundColor)
                }
                if let dwell = context.state.dwellTimeMessage {
                    Text(dwell)
                        .font(.caption)
                        .foregroundColor(theme.foregroundColor.opacity(0.85))
                }
            }
        }
    }

    private func leadingIcon(for phase: TravelLiveActivityAttributes.Phase) -> String {
        switch phase {
        case .flight:   return "airplane"
        case .boarding: return "qrcode"
        case .airport:  return "building.2.crop.circle"
        }
    }

    private func trailingIcon(for phase: TravelLiveActivityAttributes.Phase) -> String {
        switch phase {
        case .flight:   return "airplane.arrival"
        case .boarding: return "ticket"
        case .airport:  return "tray.full"
        }
    }
}

// MARK: - Lock Screen / Banner View

struct TravelLockScreenView: View {
    let context: ActivityViewContext<TravelLiveActivityAttributes>

    var body: some View {
        let theme = context.state.theme
        HStack(spacing: 0) {
            VStack {
                TravelBrandMark(
                    brandName: context.attributes.brandName,
                    logoFileName: context.attributes.logoFileName,
                    appGroupID: context.attributes.appGroupID,
                    accent: theme.accentColor,
                    foreground: theme.foregroundColor
                )
            }
            .frame(width: 64)
            .padding(.leading, 12)

            VStack(spacing: 8) {
                switch context.state.phase {
                case .flight:
                    TravelFlightContent(context: context)
                case .boarding:
                    TravelBoardingContent(context: context)
                case .airport:
                    TravelAirportContent(context: context)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity)
        .background(theme.backgroundColor)
        .cornerRadius(12)
    }
}

// MARK: - Phase content views

private struct TravelFlightContent: View {
    let context: ActivityViewContext<TravelLiveActivityAttributes>

    var body: some View {
        let theme = context.state.theme
        let pillLabel = context.state.effectiveStatusLabel
        let pillColor = context.state.effectiveStatusColor
        VStack(spacing: 8) {
            HStack {
                Text(context.state.flightNumber ?? "")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(theme.foregroundColor)
                Spacer()
                if let pillLabel {
                    Text(pillLabel)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(pillColor)
                        .cornerRadius(4)
                        .foregroundColor(theme.foregroundColor)
                }
            }

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.departureAirport ?? "")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.foregroundColor)
                    Text(context.state.departureTime ?? "")
                        .font(.caption)
                        .foregroundColor(theme.accentColor)
                }
                Spacer()
                GeometryReader { geo in
                    let progress = CGFloat(context.state.journeyProgress ?? 0) / 100.0
                    let width = geo.size.width
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(theme.foregroundColor.opacity(0.3))
                            .frame(height: 1)
                        Rectangle()
                            .fill(theme.foregroundColor)
                            .frame(width: width * progress, height: 2)
                        Image(systemName: "airplane")
                            .font(.caption)
                            .foregroundColor(theme.foregroundColor)
                            .offset(x: max(0, min(width * progress - 8, width - 16)))
                    }
                    .frame(height: 20)
                }
                .frame(width: 80, height: 20)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(context.state.arrivalAirport ?? "")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.foregroundColor)
                    Text(context.state.arrivalTime ?? "")
                        .font(.caption)
                        .foregroundColor(theme.accentColor)
                }
            }

            if context.state.wifiAvailable == true, let location = context.state.currentLocation {
                HStack(spacing: 4) {
                    Image(systemName: "wifi")
                        .font(.caption)
                    Text(location)
                        .font(.caption)
                }
                .foregroundColor(theme.foregroundColor.opacity(0.85))
            }
        }
    }
}

private struct TravelBoardingContent: View {
    let context: ActivityViewContext<TravelLiveActivityAttributes>

    var body: some View {
        let theme = context.state.theme
        let pillLabel = context.state.effectiveStatusLabel
        let pillColor = context.state.effectiveStatusColor
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.flightNumber ?? "")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(theme.foregroundColor)
                    Text("\(context.state.departureAirport ?? "") → \(context.state.arrivalAirport ?? "")")
                        .font(.caption)
                        .foregroundColor(theme.foregroundColor.opacity(0.8))
                }
                Spacer()
                if let pillLabel {
                    Text(pillLabel)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(pillColor)
                        .cornerRadius(4)
                        .foregroundColor(theme.foregroundColor)
                }
            }

            HStack(spacing: 12) {
                if let terminal = context.state.terminal {
                    boardingPill(label: "Terminal", value: terminal, theme: theme)
                }
                if let gate = context.state.gate {
                    boardingPill(label: "Gate", value: gate, theme: theme)
                }
                if let seat = context.state.seatNumber {
                    boardingPill(label: "Seat", value: seat, theme: theme)
                }
                if let time = context.state.departureTime {
                    boardingPill(label: "Departs", value: time, theme: theme)
                }
            }

            if let message = context.state.statusMessage {
                Text(message)
                    .font(.caption)
                    .foregroundColor(theme.foregroundColor.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func boardingPill(label: String, value: String, theme: TravelLiveActivityAttributes.Theme) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(theme.foregroundColor.opacity(0.6))
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(theme.foregroundColor)
        }
    }
}

private struct TravelAirportContent: View {
    let context: ActivityViewContext<TravelLiveActivityAttributes>

    var body: some View {
        let theme = context.state.theme
        let pillLabel = context.state.effectiveStatusLabel
        let pillColor = context.state.effectiveStatusColor
        VStack(spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.brandName ?? "Travel")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(theme.foregroundColor)
                    Text("\(context.state.flightNumber ?? "") • \(context.state.departureAirport ?? "") → \(context.state.arrivalAirport ?? "")")
                        .font(.caption)
                        .foregroundColor(theme.foregroundColor.opacity(0.8))
                }
                Spacer()
                if let pillLabel {
                    Text(pillLabel)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(pillColor)
                        .cornerRadius(4)
                        .foregroundColor(theme.foregroundColor)
                }
            }

            if let dwell = context.state.dwellTimeMessage {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundColor(theme.accentColor)
                    Text(dwell)
                        .font(.caption)
                        .foregroundColor(theme.foregroundColor.opacity(0.9))
                    Spacer()
                }
            }

            if let message = context.state.statusMessage {
                HStack {
                    Text(message)
                        .font(.caption2)
                        .foregroundColor(theme.foregroundColor.opacity(0.7))
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Brand mark (logo or fallback initial)

private struct TravelBrandMark: View {
    let brandName: String?
    let logoFileName: String?
    let appGroupID: String
    let accent: Color
    let foreground: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(foreground.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(foreground.opacity(0.25), lineWidth: 1)
                )

            #if canImport(UIKit)
            if let logoFileName,
               let url = TravelLogoCache.cachedURL(forFileName: logoFileName, in: appGroupID),
               let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(6)
            } else {
                fallbackInitial
            }
            #else
            fallbackInitial
            #endif
        }
        .frame(width: 48, height: 48)
    }

    private var fallbackInitial: some View {
        Text(String((brandName ?? "T").prefix(1)).uppercased())
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .foregroundColor(foreground)
    }
}

// MARK: - Preview

#Preview("Notification", as: .content,
         using: TravelLiveActivityAttributes(
            liveActivityData: LiveActivityData(liveActivityID: "TRAVEL-DEMO"),
            appGroupID: TravelAppGroup.identifier,
            logoFileName: nil,
            brandName: "Acme Air"
         )
) {
    TravelLiveActivity()
} contentStates: {
    TravelLiveActivityAttributes.debugFlightState
    TravelLiveActivityAttributes.debugBoardingState
    TravelLiveActivityAttributes.debugAirportState
}
