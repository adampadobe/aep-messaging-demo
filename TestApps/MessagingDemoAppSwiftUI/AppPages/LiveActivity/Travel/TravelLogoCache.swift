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

import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Helper used by both the host app and the widget extension to resolve a
/// logo file inside the shared App Group container.
///
/// Workflow:
///   1. App side calls `TravelLogoCache.fetch(url, into: appGroupID)` *before*
///      starting the Live Activity. The download is performed once and
///      persisted into the shared container under `TravelLogos/<sha256>.<ext>`.
///   2. The activity attributes carry the resulting `logoFileName` plus the
///      `appGroupID` they were started with.
///   3. Widget side uses `cachedURL(forFileName:in:)` to read the asset
///      without ever performing network I/O itself.
enum TravelLogoCache {

    /// Errors thrown by `fetch(_:into:)`.
    enum Error: Swift.Error {
        case missingAppGroupContainer
        case invalidHTTPResponse(Int)
        case notAnImage
    }

    // MARK: - Path helpers (shared between app and widget)

    /// Returns the URL of the shared App Group container, if available.
    static func containerURL(for appGroupID: String) -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    /// Returns the directory where Travel logos live, creating it if needed.
    static func logosDirectory(in appGroupID: String) -> URL? {
        guard let container = containerURL(for: appGroupID) else { return nil }
        let dir = container.appendingPathComponent("TravelLogos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// Returns the on-disk URL of a previously cached file (or `nil` if it
    /// hasn't been written yet).
    static func cachedURL(forFileName fileName: String, in appGroupID: String) -> URL? {
        guard let dir = logosDirectory(in: appGroupID) else { return nil }
        let url = dir.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    // MARK: - Download (host app only)

    /// Downloads `url` into the App Group container if it isn't already
    /// cached and returns the deterministic filename to embed in the
    /// Live Activity attributes. Safe to call repeatedly.
    @discardableResult
    static func fetch(_ url: URL, into appGroupID: String) async throws -> String {
        guard let dir = logosDirectory(in: appGroupID) else {
            throw Error.missingAppGroupContainer
        }

        let fileName = self.fileName(for: url)
        let target = dir.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: target.path) {
            return fileName
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw Error.invalidHTTPResponse(http.statusCode)
        }

        guard isLikelyImage(data) else {
            throw Error.notAnImage
        }

        try data.write(to: target, options: .atomic)
        NSLog("TravelLogoCache: cached logo \(fileName) (\(data.count) bytes)")
        return fileName
    }

    // MARK: - Filename + image validation

    /// Builds a stable filename for a remote URL so the app and widget agree
    /// on where the asset lives without communicating directly.
    static func fileName(for url: URL) -> String {
        let raw = url.absoluteString
        let ext = url.pathExtension.lowercased().filter { $0.isLetter || $0.isNumber }
        let safeExt = ext.isEmpty ? "img" : ext
        return "\(hash(of: raw)).\(safeExt)"
    }

    /// Lightweight content sniff so we don't persist HTML error pages or
    /// arbitrary blobs. Recognizes PNG, JPEG, GIF, WebP. Falls back to
    /// `UIImage` parsing on Apple platforms when the magic numbers don't
    /// match (e.g. for SVG or other formats UIKit can decode).
    static func isLikelyImage(_ data: Data) -> Bool {
        if data.count >= 8 {
            let png: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
            if data.prefix(8).elementsEqual(png) { return true }
        }
        if data.count >= 3 {
            let jpeg: [UInt8] = [0xFF, 0xD8, 0xFF]
            if data.prefix(3).elementsEqual(jpeg) { return true }
        }
        if data.count >= 6 {
            let gif87: [UInt8] = [0x47, 0x49, 0x46, 0x38, 0x37, 0x61]
            let gif89: [UInt8] = [0x47, 0x49, 0x46, 0x38, 0x39, 0x61]
            if data.prefix(6).elementsEqual(gif87) || data.prefix(6).elementsEqual(gif89) { return true }
        }
        if data.count >= 12 {
            let bytes = Array(data.prefix(12))
            let isRIFF = bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46
            let isWEBP = bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50
            if isRIFF && isWEBP { return true }
        }
        #if canImport(UIKit)
        return UIImage(data: data) != nil
        #else
        return false
        #endif
    }

    private static func hash(of input: String) -> String {
        let data = Data(input.utf8)
        #if canImport(CryptoKit)
        if #available(iOS 13.0, *) {
            let digest = SHA256.hash(data: data)
            return digest.map { String(format: "%02x", $0) }.joined()
        }
        #endif
        var hasher = Hasher()
        hasher.combine(input)
        return String(UInt(bitPattern: hasher.finalize()), radix: 16)
    }
}
