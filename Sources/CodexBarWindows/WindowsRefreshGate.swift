/// Serializes provider refreshes and decides what a finished refresh does with its result.
struct WindowsRefreshGate: Equatable, Sendable {
    enum Trigger: Equatable, Sendable {
        /// The periodic timer. A refresh already running delivers the data it asks for.
        case scheduled
        /// A user action or configuration change, which needs a refresh that starts after the request.
        case requested
    }

    struct Completion: Equatable, Sendable {
        /// The result belongs to the current configuration and should be shown.
        let publishes: Bool
        /// A requested refresh arrived while this one ran and must start once it is handled.
        let restarts: Bool
    }

    private(set) var isRunning = false
    private var isRestartQueued = false

    mutating func request(_ trigger: Trigger = .requested) -> Bool {
        guard !self.isRunning else {
            if trigger == .requested { self.isRestartQueued = true }
            return false
        }
        self.isRunning = true
        return true
    }

    /// A result made stale by a configuration change is discarded. A current result is always shown, even when
    /// another refresh is queued, so a refresh slower than the timer interval still updates the dashboard.
    mutating func complete(resultIsCurrent: Bool) -> Completion {
        precondition(self.isRunning, "A refresh must be running before it can complete.")
        self.isRunning = false
        let restarts = self.isRestartQueued
        self.isRestartQueued = false
        return Completion(publishes: resultIsCurrent, restarts: restarts)
    }
}
