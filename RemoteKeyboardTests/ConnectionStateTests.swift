import XCTest
@testable import RemoteKeyboard

final class ConnectionStateTests: XCTestCase {

    // MARK: - ConnectionState 동등성 헬퍼

    private func isDisconnected(_ state: ConnectionState) -> Bool {
        if case .disconnected = state { return true }
        return false
    }

    private func isSearching(_ state: ConnectionState) -> Bool {
        if case .searching = state { return true }
        return false
    }

    private func isConnecting(_ state: ConnectionState) -> Bool {
        if case .connecting = state { return true }
        return false
    }

    private func isConnected(_ state: ConnectionState) -> Bool {
        if case .connected = state { return true }
        return false
    }

    // MARK: - 초기 상태

    func testInitialStateDisconnected() {
        let manager = MultipeerManager(role: .sender)
        XCTAssertTrue(isDisconnected(manager.connectionState))
    }

    func testInitialReconnectDelayIsOne() {
        let manager = MultipeerManager(role: .sender)
        XCTAssertEqual(manager.reconnectDelay, MultipeerManager.initialReconnectDelay)
    }

    // MARK: - 상수 검증

    func testInitialDelayConstant() {
        XCTAssertEqual(MultipeerManager.initialReconnectDelay, 1.0)
    }

    func testMaxDelayConstant() {
        XCTAssertEqual(MultipeerManager.maxReconnectDelay, 30.0)
    }

    func testMaxDelayLargerThanInitial() {
        XCTAssertGreaterThan(MultipeerManager.maxReconnectDelay, MultipeerManager.initialReconnectDelay)
    }

    // MARK: - 지수 백오프 로직 검증 (순수 계산)

    func testExponentialBackoffSequence() {
        var delay = MultipeerManager.initialReconnectDelay
        let expected: [TimeInterval] = [1, 2, 4, 8, 16, 30, 30, 30]

        for expectedDelay in expected {
            XCTAssertEqual(delay, expectedDelay, accuracy: 0.001)
            delay = min(delay * 2, MultipeerManager.maxReconnectDelay)
        }
    }

    func testBackoffNeverExceedsMax() {
        var delay = MultipeerManager.initialReconnectDelay
        for _ in 0..<100 {
            delay = min(delay * 2, MultipeerManager.maxReconnectDelay)
            XCTAssertLessThanOrEqual(delay, MultipeerManager.maxReconnectDelay)
        }
    }

    func testBackoffAlwaysPositive() {
        var delay = MultipeerManager.initialReconnectDelay
        for _ in 0..<20 {
            XCTAssertGreaterThan(delay, 0)
            delay = min(delay * 2, MultipeerManager.maxReconnectDelay)
        }
    }

    // MARK: - retry() 후 딜레이 리셋

    func testRetryResetsDelay() {
        let manager = MultipeerManager(role: .sender)
        // retry는 내부적으로 reconnectDelay를 initialReconnectDelay로 리셋함
        manager.retry()
        XCTAssertEqual(manager.reconnectDelay, MultipeerManager.initialReconnectDelay)
        manager.stop()
    }

    // MARK: - 역할별 초기화

    func testSenderAndReceiverBothStartDisconnected() {
        let sender = MultipeerManager(role: .sender)
        let receiver = MultipeerManager(role: .receiver)
        XCTAssertTrue(isDisconnected(sender.connectionState))
        XCTAssertTrue(isDisconnected(receiver.connectionState))
    }

    // MARK: - 에러 상태 전이

    func testErrorMessageInitiallyNil() {
        let manager = MultipeerManager(role: .sender)
        XCTAssertNil(manager.errorMessage)
    }

    func testClearErrorSetsNil() {
        let manager = MultipeerManager(role: .sender)
        manager.clearError()
        XCTAssertNil(manager.errorMessage)
    }

    // MARK: - start/stop 안전성

    func testMultipleStopsAreSafe() {
        let manager = MultipeerManager(role: .sender)
        manager.stop()
        manager.stop()
        manager.stop()
    }

    func testStartThenStopImmediately() {
        let manager = MultipeerManager(role: .sender)
        manager.start()
        manager.stop()
        XCTAssertTrue(manager.connectedPeers.isEmpty)
    }

    // MARK: - 피어 없을 때 send 로직

    func testSendAllTypesReturnFalseWhenNoPeers() {
        let manager = MultipeerManager(role: .sender)
        let types: [MessageType] = [
            .insertText, .deleteOne, .deleteN, .returnKey,
            .cursorLeft, .cursorRight, .cursorUp, .cursorDown,
            .selectAll, .copy, .paste
        ]
        for type in types {
            XCTAssertFalse(
                manager.send(type: type),
                "\(type): 피어 없을 때 false 반환 기대"
            )
        }
    }
}
