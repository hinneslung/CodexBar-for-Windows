/// Retains environment values for execution while keeping automatic diagnostics count-only.
///
/// Mirrors upstream's `CodexBarCore.ProcessEnvironment`, which the Windows target does not link. Upstream's
/// storage tripwire scans every source directory for environment dictionaries stored without this wrapper.
@propertyWrapper
struct ProcessEnvironment<Value: Sendable & Equatable>: Sendable, Equatable,
    CustomReflectable, CustomStringConvertible, CustomDebugStringConvertible
{
    var wrappedValue: Value

    init(wrappedValue: Value) where Value == [String: String] {
        self.wrappedValue = wrappedValue
    }

    var description: String {
        "ProcessEnvironment(\(self.entryCount) entries; redacted)"
    }

    var debugDescription: String {
        self.description
    }

    var customMirror: Mirror {
        Mirror(self, children: ["entryCount": self.entryCount], displayStyle: .struct)
    }

    private var entryCount: Int {
        (self.wrappedValue as? [String: String])?.count ?? 0
    }
}
