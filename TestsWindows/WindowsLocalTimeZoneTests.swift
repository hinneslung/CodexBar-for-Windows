#if canImport(CodexBarWindows)
import Foundation
import Testing
@testable import CodexBarWindows

@Suite("Windows local time zone")
struct WindowsLocalTimeZoneTests {
    @Test
    func `a mapped Windows key resolves to its IANA zone`() throws {
        let zone = try #require(WindowsLocalTimeZone.resolve(
            info: .init(key: "Singapore Standard Time", biasMinutes: -480),
            ianaIdentifier: { $0 == "Singapore Standard Time" ? "Asia/Singapore" : nil }))
        #expect(zone.identifier == "Asia/Singapore")
    }

    @Test
    func `an unmapped key or missing ICU falls back to a whole-hour Etc zone`() throws {
        for key: String? in ["Unknown Standard Time", nil, ""] {
            let zone = try #require(WindowsLocalTimeZone.resolve(
                info: .init(key: key, biasMinutes: -480),
                ianaIdentifier: { _ in nil }))
            #expect(zone.identifier == "Etc/GMT-8")
            #expect(zone.secondsFromGMT() == 8 * 3600)
        }
        let unknownIdentifier = try #require(WindowsLocalTimeZone.resolve(
            info: .init(key: "Pacific Standard Time", biasMinutes: 420),
            ianaIdentifier: { _ in "Not/AZone" }))
        #expect(unknownIdentifier.identifier == "Etc/GMT+7")
        #expect(WindowsLocalTimeZone.resolve(info: nil, ianaIdentifier: { _ in "Asia/Singapore" }) == nil)
    }

    @Test
    func `zones that crash as Foundation's default are never returned`() throws {
        // Etc/UTC and TimeZone(secondsFromGMT:) zones crash the process when set as NSTimeZone.default on Windows.
        let utc = try #require(WindowsLocalTimeZone.resolve(
            info: .init(key: "UTC", biasMinutes: 0),
            ianaIdentifier: { _ in "Etc/UTC" }))
        #expect(utc.identifier == "GMT")
        #expect(WindowsLocalTimeZone.etcZone(biasMinutes: 0)?.identifier == "Etc/GMT")
        #expect(WindowsLocalTimeZone.etcZone(biasMinutes: 720)?.identifier == "Etc/GMT+12")
        #expect(WindowsLocalTimeZone.etcZone(biasMinutes: -840)?.identifier == "Etc/GMT-14")
        // India (UTC+5:30) and other non-whole-hour offsets have no Etc zone; Foundation's zone is kept.
        #expect(WindowsLocalTimeZone.etcZone(biasMinutes: -330) == nil)
        #expect(WindowsLocalTimeZone.resolve(info: .init(key: nil, biasMinutes: -330), ianaIdentifier: { _ in nil })
            == nil)
    }

    @Test
    func `Foundation's zone is replaced only when its offset is wrong`() throws {
        let now = try #require(ISO8601DateFormatter().date(from: "2026-11-19T08:30:00Z"))
        let singapore = try #require(TimeZone(identifier: "Asia/Singapore"))
        let gmt = try #require(TimeZone(identifier: "GMT"))
        #expect(WindowsLocalTimeZone.needsOverride(resolved: singapore, foundation: gmt, now: now))
        #expect(!WindowsLocalTimeZone.needsOverride(resolved: gmt, foundation: gmt, now: now))
        #expect(!WindowsLocalTimeZone.needsOverride(
            resolved: singapore,
            foundation: try #require(TimeZone(identifier: "Asia/Hong_Kong")),
            now: now))
    }

    #if os(Windows)
    @Test
    func `Windows ICU maps zone keys whose display names differ`() {
        // Skipped when icu.dll is unavailable (before Windows 10 1903); the app then uses the UTC offset.
        guard let singapore = WindowsLocalTimeZone.ianaIdentifier(forWindowsKey: "Singapore Standard Time") else {
            return
        }
        #expect(singapore == "Asia/Singapore")
        #expect(WindowsLocalTimeZone.ianaIdentifier(forWindowsKey: "Pacific Standard Time") == "America/Los_Angeles")
        #expect(WindowsLocalTimeZone.ianaIdentifier(forWindowsKey: "Not A Windows Zone") == nil)
    }

    @Test
    func `the current Windows zone has a key and an offset`() throws {
        let info = try #require(WindowsLocalTimeZone.currentInfo())
        #expect(abs(info.biasMinutes) <= 14 * 60)
    }
    #endif

    @Test
    func `reset times are shown in the resolved zone`() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Singapore"))
        let now = try #require(ISO8601DateFormatter().date(from: "2026-11-18T08:30:00Z"))
        let resetsAt = try #require(ISO8601DateFormatter().date(from: "2026-11-20T06:22:00Z"))
        #expect(
            WindowsResetLabelFormatter.label(resetsAt: resetsAt, description: nil, now: now, calendar: calendar)
                == "Fri 14:22")
    }
}
#endif
