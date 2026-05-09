/*
Copyright 2023 Adobe. All rights reserved.
This file is licensed to you under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy
of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under
the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
OF ANY KIND, either express or implied. See the License for the specific language
governing permissions and limitations under the License.
*/

import Foundation

enum Constants {
    // If you change any of the below properties, please uninstall and reinstall the application
    
    // UPDATED: Now configured for Demo EMEA Org (BF9C27AA6464801C0A495FD0@AdobeOrg)
    // Datastream: 18fe5e7c-94ad-4f67-ba93-35cc04d726cc
    // Property: apalmer iOS MessagingDemo App
    static let APPID = "60e5fd51ad90/03598b9be987/launch-055cedda7e10-development"
    
    // Previous AppID's (different orgs)
    // "staging/1b50a869c4a2/bcd1a623883f/launch-e44d085fc760-development" << Steve B's org
    // "3149c49c3910/b6541e5e6301/launch-f7ac0a320fb3-development"
    
    static let isStage = false
    // To auto-connect on launch, paste the full deep link with a real session UUID from Assurance
    // (https://experience.adobe.com/assurance → Create Session → connect app). Leave the placeholder below to
    // connect via QR / deep link only; the app will not call `Assurance.startSession` until `experienceCloud.org`
    // is available from Launch / Edge config.
    // Example with a real id: "messagingdemo://?adb_validation_sessionid=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    static let assuranceURL = "messagingdemo://?adb_validation_sessionid=eb0716b2-1c4d-4829-9316-3899914dbe1c"
    
    // Surface Names (must match Adobe Journey Optimizer channel / code-based experience paths)
    enum SurfaceName {
        /// AJO Messaging Inbox surface — align with your Inbox channel in AJO (see Adobe Inbox UI tutorial).
        static let INBOX = "inbox"
        static let CONTENT_CARD = "cardstab"
        //static let CONTENT_CARD = "largeImageCards"
        static let CBE_HTML = "cbehtml"
        static let CBE_JSON = "cbejson"
    }
}
