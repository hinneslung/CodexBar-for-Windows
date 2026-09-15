#if canImport(CodexBarWindows)
import Testing
@testable import CodexBarWindows

struct WindowsPopupActivationPolicyTests {
    @Test
    func `pinning cancels the tray handshake and queued hide or activation timers`() {
        var policy = WindowsPopupActivationPolicy()
        #expect(policy.trayActivated(isPopupVisible: false) == .showFromTray)
        policy.setPinned(true)
        #expect(policy.isPinned)
        #expect(!policy.isAwaitingPostTrayActivation)
        #expect(policy.opacityAlpha == 204)
        #expect(policy.deactivated(automaticallyHides: true) == .none)
        #expect(policy.deferredHideTimerFired(isPopupVisible: true) == .none)
        #expect(policy.postTrayActivationTimerFired(isPopupVisible: true) == .none)
    }

    @Test
    func `pinned tray activations only reactivate without beginning an anchored show handshake`() {
        var policy = WindowsPopupActivationPolicy()
        policy.setPinned(true)
        #expect(policy.trayActivated(isPopupVisible: true) == .reactivatePinned)
        #expect(policy.trayActivated(isPopupVisible: true) == .reactivatePinned)
        #expect(!policy.isAwaitingPostTrayActivation)
        #expect(policy.isPinned)
    }

    @Test
    func `unpin restores opacity and normal tray behavior without stale reactivation`() {
        var policy = WindowsPopupActivationPolicy()
        _ = policy.trayActivated(isPopupVisible: false)
        policy.setPinned(true)
        policy.setPinned(false)
        policy.popupHidden()
        #expect(!policy.isPinned)
        #expect(policy.opacityAlpha == 255)
        #expect(policy.postTrayActivationTimerFired(isPopupVisible: false) == .none)
        #expect(policy.deferredHideTimerFired(isPopupVisible: false) == .none)
        #expect(policy.trayActivated(isPopupVisible: false) == .showFromTray)
        #expect(policy.postTrayActivationTimerFired(isPopupVisible: true) == .cancelDeferredHideAndReactivate)
        #expect(policy.trayActivated(isPopupVisible: true) == .hide)
    }

    @Test
    func `pin state is session only and ordinary keep open behavior is unchanged`() {
        let policy = WindowsPopupActivationPolicy()
        #expect(!policy.isPinned)
        #expect(policy.opacityAlpha == 255)
        #expect(policy.deactivated(automaticallyHides: false) == .none)
        #expect(policy.deactivated(automaticallyHides: true) == .scheduleDeferredHide)
    }

    @Test
    func `pinned placement retains top left through size changes when it fits`() {
        #expect(WindowsPopupPlacement.clampedOrigin(preferred: 120, extent: 300, lower: 0, upper: 1080, gap: 8) == 120)
        #expect(WindowsPopupPlacement.clampedOrigin(preferred: 120, extent: 580, lower: 0, upper: 1080, gap: 8) == 120)
    }

    @Test
    func `placement clamps on negative monitors and undersized work areas`() {
        #expect(WindowsPopupPlacement.clampedOrigin(preferred: -1800, extent: 630, lower: -1920, upper: 0, gap: 14)
            == -1800)
        #expect(WindowsPopupPlacement.clampedOrigin(preferred: -200, extent: 630, lower: -1920, upper: 0, gap: 14)
            == -644)
        #expect(WindowsPopupPlacement.clampedOrigin(preferred: 200, extent: 630, lower: 0, upper: 600, gap: 14) == 0)
        #expect(WindowsPopupPlacement.clampedOrigin(preferred: 200, extent: 600, lower: 0, upper: 600, gap: 14) == 0)
    }

    @Test
    func `late inactive notification cannot close a popup just shown from the tray`() {
        var policy = WindowsPopupActivationPolicy()

        #expect(policy.trayActivated(isPopupVisible: false) == .showFromTray)
        #expect(policy.deactivated(automaticallyHides: true) == .scheduleDeferredHide)
        #expect(
            policy.postTrayActivationTimerFired(isPopupVisible: true)
                == .cancelDeferredHideAndReactivate)
        #expect(policy.deactivated(automaticallyHides: true) == .scheduleDeferredHide)
    }

    @Test
    func `deferred hide firing before post activation reactivates instead of hiding`() {
        var policy = WindowsPopupActivationPolicy()

        #expect(policy.trayActivated(isPopupVisible: false) == .showFromTray)
        #expect(policy.deactivated(automaticallyHides: true) == .scheduleDeferredHide)
        #expect(
            policy.deferredHideTimerFired(isPopupVisible: true)
                == .cancelDeferredHideAndReactivate)
        #expect(policy.postTrayActivationTimerFired(isPopupVisible: true) == .none)
    }

    @Test
    func `outside deactivation after handshake performs the deferred hide`() {
        var policy = WindowsPopupActivationPolicy()

        #expect(policy.trayActivated(isPopupVisible: false) == .showFromTray)
        #expect(
            policy.postTrayActivationTimerFired(isPopupVisible: true)
                == .cancelDeferredHideAndReactivate)
        #expect(policy.deactivated(automaticallyHides: true) == .scheduleDeferredHide)
        #expect(policy.deferredHideTimerFired(isPopupVisible: true) == .hide)
    }

    @Test
    func `duplicate tray activation is ignored until the show handshake completes`() {
        var policy = WindowsPopupActivationPolicy()

        #expect(policy.trayActivated(isPopupVisible: false) == .showFromTray)
        #expect(policy.trayActivated(isPopupVisible: true) == .ignoreDuplicateTrayActivation)
        #expect(
            policy.postTrayActivationTimerFired(isPopupVisible: true)
                == .cancelDeferredHideAndReactivate)
        #expect(policy.trayActivated(isPopupVisible: true) == .hide)
    }

    @Test
    func `hiding before delayed activation prevents the popup from reopening`() {
        var policy = WindowsPopupActivationPolicy()

        #expect(policy.trayActivated(isPopupVisible: false) == .showFromTray)
        policy.popupHidden()
        #expect(policy.postTrayActivationTimerFired(isPopupVisible: false) == .none)
    }

    @Test
    func `one physical tray activation cannot toggle twice`() {
        var gate = WindowsTrayActivationGate()
        var policy = WindowsPopupActivationPolicy()

        let firstOpen = gate.shouldHandle(timestamp: 1000)
        #expect(firstOpen)
        #expect(policy.trayActivated(isPopupVisible: false) == .showFromTray)
        #expect(
            policy.postTrayActivationTimerFired(isPopupVisible: true)
                == .cancelDeferredHideAndReactivate)
        let duplicateOpen = gate.shouldHandle(timestamp: 1012)
        #expect(!duplicateOpen)

        let firstClose = gate.shouldHandle(timestamp: 2000)
        #expect(firstClose)
        #expect(policy.trayActivated(isPopupVisible: true) == .hide)
        policy.popupHidden()
        let duplicateClose = gate.shouldHandle(timestamp: 2009)
        #expect(!duplicateClose)
    }

    @Test
    func `tray activation coalescing survives timestamp wraparound`() {
        var gate = WindowsTrayActivationGate()

        let beforeWrap = gate.shouldHandle(timestamp: UInt32.max - 100)
        let afterWrapDuplicate = gate.shouldHandle(timestamp: 20)
        let afterWrapActivation = gate.shouldHandle(timestamp: 400)
        #expect(beforeWrap)
        #expect(!afterWrapDuplicate)
        #expect(afterWrapActivation)
    }
}
#endif
