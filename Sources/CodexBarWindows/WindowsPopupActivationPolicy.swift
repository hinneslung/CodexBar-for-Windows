enum WindowsPopupActivationAction: Equatable, Sendable {
    case showFromTray
    case hide
    case ignoreDuplicateTrayActivation
    case scheduleDeferredHide
    case cancelDeferredHideAndReactivate
    case reactivatePinned
    case none
}

struct WindowsPopupActivationPolicy: Sendable {
    static let pinnedOpacityAlpha: UInt8 = 204
    static let normalOpacityAlpha: UInt8 = 255
    private(set) var isAwaitingPostTrayActivation = false
    private(set) var isPinned = false

    var opacityAlpha: UInt8 {
        self.isPinned ? Self.pinnedOpacityAlpha : Self.normalOpacityAlpha
    }

    mutating func setPinned(_ pinned: Bool) {
        self.isPinned = pinned
        self.isAwaitingPostTrayActivation = false
    }

    mutating func trayActivated(isPopupVisible: Bool) -> WindowsPopupActivationAction {
        if self.isPinned { return .reactivatePinned }
        if self.isAwaitingPostTrayActivation {
            return .ignoreDuplicateTrayActivation
        }
        if isPopupVisible {
            return .hide
        }
        self.isAwaitingPostTrayActivation = true
        return .showFromTray
    }

    func deactivated(automaticallyHides: Bool) -> WindowsPopupActivationAction {
        automaticallyHides && !self.isPinned ? .scheduleDeferredHide : .none
    }

    mutating func postTrayActivationTimerFired(isPopupVisible: Bool) -> WindowsPopupActivationAction {
        guard !self.isPinned else { return .none }
        guard self.isAwaitingPostTrayActivation else { return .none }
        self.isAwaitingPostTrayActivation = false
        return isPopupVisible ? .cancelDeferredHideAndReactivate : .none
    }

    mutating func deferredHideTimerFired(isPopupVisible: Bool) -> WindowsPopupActivationAction {
        guard !self.isPinned else { return .none }
        guard isPopupVisible else {
            self.isAwaitingPostTrayActivation = false
            return .none
        }
        if self.isAwaitingPostTrayActivation {
            self.isAwaitingPostTrayActivation = false
            return .cancelDeferredHideAndReactivate
        }
        return .hide
    }

    mutating func popupHidden() {
        self.isAwaitingPostTrayActivation = false
    }
}

enum WindowsPopupPlacement {
    static func clampedOrigin(preferred: Int32, extent: Int32, lower: Int32, upper: Int32, gap: Int32) -> Int32 {
        let available = max(0, upper - lower)
        let inset = min(max(0, gap), max(0, (available - extent) / 2))
        return max(lower + inset, min(preferred, upper - extent - inset))
    }
}

struct WindowsTrayActivationGate: Sendable {
    private static let duplicateWindowMilliseconds: UInt32 = 250
    private var lastActivationTimestamp: UInt32?

    mutating func shouldHandle(timestamp: UInt32) -> Bool {
        defer { self.lastActivationTimestamp = timestamp }
        guard let lastActivationTimestamp else { return true }
        return timestamp &- lastActivationTimestamp > Self.duplicateWindowMilliseconds
    }
}
