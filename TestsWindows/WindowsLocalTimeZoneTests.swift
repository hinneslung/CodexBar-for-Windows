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
    func `an unmapped key or missing ICU falls back to the current UTC offset`() throws {
        for key: String? in ["Unknown Standard Time", nil, ""] {
            let zone = try #require(WindowsLocalTimeZone.resolve(
                info: .init(key: key, biasMinutes: -480),
                ianaIdentifier: { _ in nil }))
            #expect(zone.secondsFromGMT() == 8 * 3600)
        }
        let unknownIdentifier = try #require(WindowsLocalTimeZone.resolve(
            info: .init(key: "Pacific Standard Time", biasMinutes: 420),
            ianaIdentifier: { _ in "Not/AZone" }))
        #expect(unknownIdentifier.secondsFromGMT() == -7 * 3600)
        #expect(WindowsLocalTimeZone.resolve(info: nil, ianaIdentifier: { _ in "Asia/Singapore" }) == nil)
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
