import Foundation

#if os(Windows)
import WinSDK
#endif

/// Foundation on Windows can report GMT as the current time zone. It does so for zones whose display name differs
/// from their Windows key, such as "Singapore Standard Time" (displayed as "Malay Peninsula Standard Time"), which
/// shifts every reset time by the zone's offset. The app resolves the key through Windows' own ICU instead and makes
/// the result Foundation's default, which `Calendar.current` and new date formatters use.
enum WindowsLocalTimeZone {
    /// The Windows time zone key and the current offset, as `GetDynamicTimeZoneInformation` reports them.
    struct Info: Equatable, Sendable {
        let key: String?
        /// Minutes to add to local time to get UTC, including any daylight saving bias in effect.
        let biasMinutes: Int
    }

    /// The zone for a Windows key, or a whole-hour `Etc/GMT±N` zone when the key cannot be mapped to an IANA zone.
    ///
    /// Setting Foundation's default on Windows crashes the process for `Etc/UTC` and for fixed-offset zones made with
    /// `TimeZone(secondsFromGMT:)`, so neither is ever returned: `Etc/UTC` becomes `GMT`, and offsets that are not
    /// whole hours have no fallback.
    static func resolve(info: Info?, ianaIdentifier: (String) -> String?) -> TimeZone? {
        guard let info else { return nil }
        if let key = info.key, !key.isEmpty, let identifier = ianaIdentifier(key) {
            let safeIdentifier = self.crashingDefaultIdentifiers.contains(identifier) ? "GMT" : identifier
            if let zone = TimeZone(identifier: safeIdentifier) { return zone }
        }
        return self.etcZone(biasMinutes: info.biasMinutes)
    }

    private static let crashingDefaultIdentifiers: Set<String> = ["Etc/UTC", "Etc/UCT", "Etc/Universal", "Etc/Zulu"]

    /// `Etc/GMT` zones invert the usual sign: UTC+8 is `Etc/GMT-8`. The database covers UTC-12 through UTC+14.
    static func etcZone(biasMinutes: Int) -> TimeZone? {
        guard biasMinutes.isMultiple(of: 60) else { return nil }
        let hours = biasMinutes / 60
        guard (-14...12).contains(hours) else { return nil }
        let identifier = hours == 0 ? "Etc/GMT" : "Etc/GMT\(hours > 0 ? "+" : "-")\(abs(hours))"
        return TimeZone(identifier: identifier)
    }

    /// Whether Foundation's own zone is wrong now. Foundation is right for most zones, and the default is only
    /// replaced when it is not, so a machine whose zone Foundation already handles keeps Foundation's behavior.
    static func needsOverride(resolved: TimeZone, foundation: TimeZone, now: Date = Date()) -> Bool {
        resolved.secondsFromGMT(for: now) != foundation.secondsFromGMT(for: now)
    }

    /// Resolves the Windows time zone and makes it Foundation's default when Foundation's own zone is wrong. Called at
    /// startup and when Windows reports a time change.
    @discardableResult
    static func apply() -> TimeZone? {
        guard let zone = self.resolve(info: self.currentInfo(), ianaIdentifier: self.ianaIdentifier(forWindowsKey:)),
              self.needsOverride(resolved: zone, foundation: NSTimeZone.default)
        else { return nil }
        NSTimeZone.default = zone
        return zone
    }

    #if os(Windows)
    static func currentInfo() -> Info? {
        var information = DYNAMIC_TIME_ZONE_INFORMATION()
        let result = GetDynamicTimeZoneInformation(&information)
        guard result != TIME_ZONE_ID_INVALID else { return nil }
        let key = withUnsafeBytes(of: information.TimeZoneKeyName) { raw in
            String(decoding: raw.bindMemory(to: UInt16.self).prefix { $0 != 0 }, as: UTF16.self)
        }
        let currentBias: Int32 =
            switch result {
            case DWORD(TIME_ZONE_ID_DAYLIGHT): information.DaylightBias
            case DWORD(TIME_ZONE_ID_STANDARD): information.StandardBias
            default: 0
            }
        return Info(key: key.isEmpty ? nil : key, biasMinutes: Int(information.Bias + currentBias))
    }

    private typealias WindowsIDToIANA = @convention(c) (
        UnsafePointer<UInt16>?, Int32, UnsafePointer<CChar>?, UnsafeMutablePointer<UInt16>?, Int32,
        UnsafeMutablePointer<Int32>?) -> Int32

    /// Maps a Windows time zone key to an IANA identifier with `icu.dll`, which Windows 10 1903 and later include.
    /// The toolchain's bundled ICU does not export this function. Returns nil when ICU is unavailable.
    static func ianaIdentifier(forWindowsKey key: String) -> String? {
        let library = "icu.dll".withCString(encodedAs: UTF16.self) {
            LoadLibraryExW($0, nil, DWORD(LOAD_LIBRARY_SEARCH_SYSTEM32))
        }
        guard let library, let symbol = GetProcAddress(library, "ucal_getTimeZoneIDForWindowsID") else {
            return nil
        }
        let function = unsafeBitCast(symbol, to: WindowsIDToIANA.self)
        let units = Array(key.utf16)
        var output = [UInt16](repeating: 0, count: 128)
        var status: Int32 = 0
        let length = function(units, Int32(units.count), nil, &output, Int32(output.count), &status)
        // ICU reports errors as positive status codes; zero and negative values are success and warnings.
        guard status <= 0, length > 0, Int(length) <= output.count else { return nil }
        return String(decoding: output.prefix(Int(length)), as: UTF16.self)
    }
    #else
    static func currentInfo() -> Info? {
        nil
    }

    static func ianaIdentifier(forWindowsKey _: String) -> String? {
        nil
    }
    #endif
}
