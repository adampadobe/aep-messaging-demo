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
//import AEPEdgeConsent
import AEPEdgeIdentity
import AEPLifecycle
import AEPSignal
import AEPMessaging
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    /// Avoid starting Assurance before remote Tag config is applied; `configureWith(appId:)` is async and
    /// Assurance needs `experienceCloud.org` from that config (otherwise org/sandbox show as unknown).
    private var didStartAssuranceAfterConfiguration = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        MobileCore.setLogLevel(.trace)

        let extensions = [
            Identity.self,
            Lifecycle.self,
            Signal.self,
            Edge.self,
//            Consent.self,
            Messaging.self,
            Assurance.self,
            TokenCollector.self  // Re-enabled for push-to-start tokens
        ]
        
        // Defer all SDK registration to next run loop so the window and first frame can render (avoids hang on device)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            MobileCore.registerExtensions(extensions) {
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

                    MobileCore.configureWith(appId: Constants.APPID)
                    if Constants.isStage {
                        MobileCore.updateConfigurationWith(configDict: ["edge.environment": "int"])
                    }
                    #if DEBUG
                    MobileCore.updateConfigurationWith(configDict: ["messaging.useSandbox": true])
                    #endif
                    self.registerForPushNotifications(application)
                }
                // Live Activity registration is done when user opens Live Activity tab (see LiveActivityView) to avoid launch hang
            }
        }
        
        return true
    }

    private func startAssuranceAndLoadMessagingSurfaces() {
        if let assuranceURL = URL(string: Constants.assuranceURL), !Constants.assuranceURL.isEmpty {
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
        completionHandler([.alert, .sound, .badge])
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
