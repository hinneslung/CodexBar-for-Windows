#if canImport(CodexBarWindows)
import Testing
@testable import CodexBarWindows

struct WindowsRefreshGateTests {
    @Test
    func `a timer tick during a slow refresh neither discards its result nor queues another`() {
        var gate = WindowsRefreshGate()

        let firstRequest = gate.request(.scheduled)
        let tickDuringRefresh = gate.request(.scheduled)
        let completion = gate.complete(resultIsCurrent: true)

        #expect(firstRequest)
        #expect(!tickDuringRefresh)
        #expect(completion == .init(publishes: true, restarts: false))
        #expect(!gate.isRunning)
    }

    @Test
    func `slow refreshes keep publishing when every refresh outlasts the timer interval`() {
        var gate = WindowsRefreshGate()

        for _ in 0..<3 {
            let started = gate.request(.scheduled)
            let tickDuringRefresh = gate.request(.scheduled)
            let completion = gate.complete(resultIsCurrent: true)
            #expect(started)
            #expect(!tickDuringRefresh)
            #expect(completion == .init(publishes: true, restarts: false))
        }
    }

    @Test
    func `a manual refresh during a refresh publishes the result and then restarts once`() {
        var gate = WindowsRefreshGate()

        let firstRequest = gate.request(.scheduled)
        let manualRequest = gate.request(.requested)
        let completion = gate.complete(resultIsCurrent: true)
        let restartedRequest = gate.request(.requested)
        let restartedCompletion = gate.complete(resultIsCurrent: true)

        #expect(firstRequest)
        #expect(!manualRequest)
        #expect(completion == .init(publishes: true, restarts: true))
        #expect(restartedRequest)
        #expect(restartedCompletion == .init(publishes: true, restarts: false))
    }

    @Test
    func `configuration refresh queued during an older refresh discards and restarts`() {
        var gate = WindowsRefreshGate()

        let firstRequest = gate.request()
        let queuedRequest = gate.request()
        let staleCompletion = gate.complete(resultIsCurrent: false)
        let restartedRequest = gate.request()
        let restartedCompletion = gate.complete(resultIsCurrent: true)

        #expect(firstRequest)
        #expect(!queuedRequest)
        #expect(staleCompletion == .init(publishes: false, restarts: true))
        #expect(restartedRequest)
        #expect(restartedCompletion == .init(publishes: true, restarts: false))
    }

    @Test
    func `multiple requests during one refresh coalesce into one restart`() {
        var gate = WindowsRefreshGate()

        let firstRequest = gate.request()
        let firstQueuedRequest = gate.request()
        let tick = gate.request(.scheduled)
        let secondQueuedRequest = gate.request()
        let firstCompletion = gate.complete(resultIsCurrent: true)
        let restartedRequest = gate.request()
        let restartedCompletion = gate.complete(resultIsCurrent: true)

        #expect(firstRequest)
        #expect(!firstQueuedRequest)
        #expect(!tick)
        #expect(!secondQueuedRequest)
        #expect(firstCompletion == .init(publishes: true, restarts: true))
        #expect(restartedRequest)
        #expect(restartedCompletion == .init(publishes: true, restarts: false))
    }
}
#endif
