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

import SwiftUI
import AEPMessaging

// MARK: - LiveActivityView

struct LiveActivityView: View {
    /// Registration moved here from launch to avoid device hang; only runs once when user opens tab.
    private static var hasRegisteredLiveActivities = false
    
    var body: some View {
        if #available(iOS 16.1, *) {
            // Structure the view to ensure banner only shows on the main page
            NavigationView {
                mainContentView
            }
            .onAppear { Self.registerLiveActivitiesIfNeeded() }
        } else {
            // Fallback for older versions
            Text("Live Activities are available only on iOS 16.1 or newer.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
    
    // MARK: - Main Content View
    
    @available(iOS 16.1, *)
    private var mainContentView: some View {
        VStack(spacing: 20) {
            Text("Use cases")
                .font(.title)
                .padding(.top)
            
            // Cards in a grid layout
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                // Card 1: Game Live Activity
                NavigationLink(destination: GameScoreLiveActivityView()) {
                    CardView(
                        imageName: "nfl",
                        title: "Game \n Live Activity"
                    )
                }

                // Card 2: Food Delivery Live Activity
                NavigationLink(destination: FoodDeliveryLiveActivityView()) {
                    CardView(
                        imageName: "hungry",
                        title: "Food Delivery \n Live Activity"
                    )
                }

                // Card 3: Airplane Tracking Live Activity
                NavigationLink(destination: AirplaneTrackingLiveActivityView()) {
                    CardView(
                        imageName: "AirplaneLogo",
                        title: "Airplane Tracking \n Live Activity"
                    )
                }
                
                // Card 4: Etihad Premium Flight
                NavigationLink(destination: EtihadPremiumLiveActivityView()) {
                    CardView(
                        imageName: "EtihadLogo",
                        title: "Etihad Premium \n Flight"
                    )
                }
                
                // Card 5: Etihad Boarding
                NavigationLink(destination: EtihadBoardingLiveActivityView()) {
                    CardView(
                        imageName: "EtihadLogo",
                        title: "Etihad Boarding \n Pass"
                    )
                }
                
                // Card 6: Flynas Flight
                NavigationLink(destination: FlynasLiveActivityView()) {
                    BrandedCardView(
                        brandName: "flynas",
                        title: "Flynas \n Flight",
                        backgroundColor: Color(red: 0.06, green: 0.49, blue: 0.28)
                    )
                }

                // Card 7: KSIA Airport Experience
                NavigationLink(destination: KSIAAirportLiveActivityView()) {
                    CardView(
                        imageName: "KSIALogo",
                        title: "KSIA Airport \n Experience"
                    )
                }

                // Card 8: Travel (themeable, repeatable demo)
                NavigationLink(destination: TravelLiveActivityView()) {
                    BrandedCardView(
                        brandName: "travel",
                        title: "Travel \n Live Activity",
                        backgroundColor: Color(red: 0.12, green: 0.16, blue: 0.27)
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)            
            Spacer(minLength: 80) // Add space at the bottom for the banner
        }
    }
    
    @available(iOS 16.1, *)
    private static func registerLiveActivitiesIfNeeded() {
        guard !hasRegisteredLiveActivities else { return }
        hasRegisteredLiveActivities = true
        Messaging.registerLiveActivities([
            AirplaneTrackingAttributes.self,
            FoodDeliveryLiveActivityAttributes.self,
            GameScoreLiveActivityAttributes.self,
            EtihadPremiumFlightAttributes.self,
            EtihadBoardingAttributes.self,
            FlynasFlightAttributes.self,
            KSIAAirportAttributes.self,
            TravelLiveActivityAttributes.self
        ])
    }
}

// MARK: - CardView (for each card in the grid)
struct CardView: View {
    let imageName: String
    let title: String

    var body: some View {
        VStack(spacing: 12) {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 90, height: 90) // Increased size for images
                .foregroundColor(.blue)

            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 160, height: 180) // Ensures consistent size for all cards
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
}

struct BrandedCardView: View {
    let brandName: String
    let title: String
    let backgroundColor: Color

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(backgroundColor)

                Text(brandName)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(width: 90, height: 90)

            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 160, height: 180)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    LiveActivityView()
}
