/*
Copyright 2024 Adobe. All rights reserved.
This file is licensed to you under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy
of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under
the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
OF ANY KIND, either express or implied. See the License for the specific language
governing permissions and limitations under the License.
*/

import AEPAssurance
import AEPCore
import AEPEdge
import AEPEdgeConsent
import AEPEdgeIdentity
import AEPLifecycle
import AEPSignal
import AEPMessaging
import AEPServices
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    /// Avoid starting Assurance before remote Tag config is applied; `configureWith(appId:)` is async and
    /// Assurance needs `experienceCloud.org` from that config (otherwise org/sandbox show as unknown).
    private var didStartAssuranceAfterConfiguration = false

    /// QR / deep link received before the first configuration response with `experienceCloud.org`.
    private var pendingAssuranceDeepLinkURL: URL?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        MobileCore.setLogLevel(.trace)

        // Clear the live activity push-to-start token cache BEFORE the SDK initializes.
        // MessagingStateManager loads pushToStartTokenStore from disk during extension
        // initialization (which runs on background threads inside registerExtensions,
        // BEFORE the completion callback fires). Clearing here guarantees the Messaging
        // extension sees a clean store and treats every token as new on this launch,
        // bypassing the SDK's de-duplication guard. FileSystemNamedCollection uses a
        // serial queue: the async remove() completes before any subsequent sync get()
        // during extension init. Remove this block once the DCVS descriptor is fixed.
        #if DEBUG
        if #available(iOS 16.1, *) {
            NamedCollectionDataStore(name: "com.adobe.messaging").remove(key: "liveActivity.pushToStartTokens")
        }
        #endif

        let extensions = [
            Identity.self,
            AEPEdgeIdentity.Identity.self,
            Lifecycle.self,
            Signal.self,
            Edge.self,
            Consent.self,
            Messaging.self,
            Assurance.self,
            TokenCollector.self  // Re-enabled for push-to-start tokens
        ]
        
        // registerExtensions is non-blocking — heavy work happens on background threads.
        // Call it synchronously here so the Lifecycle extension is ready before scenePhase
        // fires .active, and so the push token safety re-dispatch runs on the right session.
        MobileCore.registerExtensions(extensions) { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                    MobileCore.registerEventListener(type: EventType.configuration, source: EventSource.responseContent) { [weak self] event in
                        guard let self = self else { return }
                        guard !self.didStartAssuranceAfterConfiguration else { return }
                        guard let org = event.data?["experienceCloud.org"] as? String, !org.isEmpty else { return }
                        self.didStartAssuranceAfterConfiguration = true
                        DispatchQueue.main.async {
                            self.startAssuranceAndLoadMessagingSurfaces()
                        }
                    }

                    // Set default collect consent to "yes" so Edge events are not held
                    // in "pending" state. Without the Consent extension registering a
                    // value, some Launch configurations leave events queued indefinitely.
                    Consent.update(with: ["consents": ["collect": ["val": "y"]]])

                    MobileCore.configureWith(appId: Constants.APPID)
                    if Constants.isStage {
                        MobileCore.updateConfigurationWith(configDict: ["edge.environment": "int"])
                    }
                    #if DEBUG
                    MobileCore.updateConfigurationWith(configDict: ["messaging.useSandbox": true])
                    #endif
                    self.registerForPushNotifications(application)
                    // Safety net: if the APNs token was already stored from a previous launch,
                    // re-send it now so AEP always has a current push identifier even if
                    // didRegisterForRemoteNotificationsWithDeviceToken fires before SDK is ready.
                    self.redispatchStoredPushIdentifierToAdobeIfNeeded()

                    // Register Live Activities at launch (not deferred to tab navigation) so
                    // push-to-start tokens are sent to AEP on every app start, regardless of
                    // which screen the user opens. Required for real-device token delivery.
                    if #available(iOS 16.1, *) {
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
            }

        return true
    }

    /// Called from SwiftUI `onOpenURL` (and may be used from `application(_:open:options:)`). Starts Assurance only
    /// after `experienceCloud.org` is present unless the session URL arrived after that milestone.
    func enqueueAssuranceDeepLink(_ url: URL) {
        let work = { [weak self] in
            guard let self = self else { return }
            guard Self.urlHasValidAssuranceSessionID(url) else { return }
            if self.didStartAssuranceAfterConfiguration {
                Assurance.startSession(url: url)
            } else {
                self.pendingAssuranceDeepLinkURL = url
            }
        }
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    /// `adb_validation_sessionid` must be a real UUID (excludes placeholder `YOUR_SESSION_ID` and empty values).
    private static func urlHasValidAssuranceSessionID(_ url: URL) -> Bool {
        guard let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
              let raw = items.first(where: { $0.name == "adb_validation_sessionid" })?.value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else { return false }
        return UUID(uuidString: raw) != nil
    }

    /// Auto-connect from `Constants.assuranceURL` only when the session id is a valid UUID (not the template placeholder).
    private func shouldStartAssuranceFromConstantsURL() -> Bool {
        guard !Constants.assuranceURL.isEmpty, let url = URL(string: Constants.assuranceURL) else { return false }
        return Self.urlHasValidAssuranceSessionID(url)
    }

    private func startAssuranceAndLoadMessagingSurfaces() {
        if let pending = pendingAssuranceDeepLinkURL {
            pendingAssuranceDeepLinkURL = nil
            Assurance.startSession(url: pending)
        } else if shouldStartAssuranceFromConstantsURL(), let assuranceURL = URL(string: Constants.assuranceURL) {
            Assurance.startSession(url: assuranceURL)
        }
        let cardSurface = Surface(path: Constants.SurfaceName.CONTENT_CARD)
        let cbeSurface1 = Surface(path: Constants.SurfaceName.CBE_HTML)
        let cbeSurface2 = Surface(path: Constants.SurfaceName.CBE_JSON)
        let inboxSurface = Surface(path: Constants.SurfaceName.INBOX)
        Messaging.updatePropositionsForSurfaces([cardSurface, cbeSurface1, cbeSurface2, inboxSurface])
    }

    // MARK: - Push Notification registration methods
    func registerForPushNotifications(_ application : UIApplication) {
        let center = UNUserNotificationCenter.current()
        // Ask for user permission
        center.requestAuthorization(options: [.badge, .sound, .alert]) { [weak self] granted, _ in
            guard granted else { return }
            
            center.delegate = self
            
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
    }
    
    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device token is - \(token)")
        UserDefaults.standard.set(token, forKey: "devicePushToken")
        MobileCore.setPushIdentifier(deviceToken)
    }

    func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        MobileCore.setPushIdentifier(nil)
        #if targetEnvironment(simulator)
        // Simulator doesn't get a real APNs token; store a placeholder so the Push tab shows something.
        let placeholder = "SIM_\(String((0..<60).map { _ in "0123456789abcdef".randomElement()! }))"
        UserDefaults.standard.set(placeholder, forKey: "devicePushToken")
        print("Simulator: no real push token. Stored placeholder for UI. Use a real device for AEP.")
        #endif
    }

    /// After `MobileCore.resetIdentities()`, Edge/Messaging must receive the push token again. Converts the
    /// hex string stored under `devicePushToken` (same format as `MessagingDemoApp` `String.toData()`).
    /// Simulator `SIM_` placeholders are not sent to the SDK.
    func redispatchStoredPushIdentifierToAdobeIfNeeded() {
        guard let token = UserDefaults.standard.string(forKey: "devicePushToken"), !token.isEmpty else { return }
        if token.hasPrefix("SIM_") { return }
        guard let data = Self.hexStringToApnsTokenData(token) else { return }
        MobileCore.setPushIdentifier(data)
    }

    /// Same parsing rules as `TestApps/MessagingDemoApp/String+DataConversion.swift` `String.toData()`.
    private static func hexStringToApnsTokenData(_ hex: String) -> Data? {
        let cleaned = hex.replacingOccurrences(of: " ", with: "")
        guard cleaned.count % 2 == 0 else { return nil }
        var data = Data()
        var index = cleaned.startIndex
        while index < cleaned.endIndex {
            let nextIndex = cleaned.index(index, offsetBy: 2)
            guard nextIndex <= cleaned.endIndex else { return nil }
            let byteString = cleaned[index..<nextIndex]
            guard let byte = UInt8(byteString, radix: 16) else { return nil }
            data.append(byte)
            index = nextIndex
        }
        return data
    }
    
    // MARK: - Handle Push Notification Reception
    // Delegate method that tells the app that a remote notification arrived that indicates there is data to be fetched.
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Handle the silent notifications received from AJO in here
        print("silent notification received")
        completionHandler(.noData)
    }
    

    // Delegate method to handle a notification that arrived while the app was running in the foreground.
    func userNotificationCenter(_: UNUserNotificationCenter,
                                willPresent _: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound, .badge])
    }

    // Delegate method is called when a notification is interacted with
    func userNotificationCenter(_: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // Perform the task associated with the action.
        switch response.actionIdentifier {
        case "ACCEPT_ACTION":
            Messaging.handleNotificationResponse(response)

        case "DECLINE_ACTION":
            Messaging.handleNotificationResponse(response)

        // Handle other actions…
        default:
            Messaging.handleNotificationResponse(response)
        }

        // Always call the completion handler when done.
        completionHandler()
    }
}
