import XCTest
@testable import RemoteKeyboard

final class MultipeerManagerTests: XCTestCase {

    // MARK: - 초기 상태

    func testInitialStateIsDisconnected() {
        let manager = MultipeerManager(role: .sender)
        if case .disconnected = manager.connectionState {
            // 정상
        } else {
            XCTFail("초기 상태는 disconnected여야 합니다. 실제: \(manager.connectionState)")
        }
    }

    func testInitialConnectedPeersIsEmpty() {
        let manager = MultipeerManager(role: .sender)
        XCTAssertTrue(manager.connectedPeers.isEmpty)
    }

    func testInitialErrorMessageIsNil() {
        let manager = MultipeerManager(role: .sender)
        XCTAssertNil(manager.errorMessage)
    }

    // MARK: - 역할 초기화

    func testSenderRoleInit() {
        let sender = MultipeerManager(role: .sender)
        XCTAssertNotNil(sender)
    }

    func testReceiverRoleInit() {
        let receiver = MultipeerManager(role: .receiver)
        XCTAssertNotNil(receiver)
    }

    // MARK: - send() - 피어 없을 때 실패

    func testSendReturnsFalseWhenNoPeers() {
        let manager = MultipeerManager(role: .sender)
        let result = manager.send(type: .insertText, payload: Data("test".utf8))
        XCTAssertFalse(result, "연결된 피어가 없으면 send는 false를 반환해야 합니다")
    }

    func testSendTextDoesNotCrashWhenDisconnected() {
        let manager = MultipeerManager(role: .sender)
        manager.sendText("hello")  // 크래시 없이 실행되어야 함
    }

    func testSendDeleteBackwardDoesNotCrashWhenDisconnected() {
        let manager = MultipeerManager(role: .sender)
        manager.sendDeleteBackward()
        manager.sendDeleteBackward(count: 5)
    }

    func testCursorCommandsDoNotCrashWhenDisconnected() {
        let manager = MultipeerManager(role: .sender)
        manager.sendCursorLeft()
        manager.sendCursorRight()
        manager.sendCursorUp()
        manager.sendCursorDown()
        manager.sendSelectAll()
        manager.sendCopy()
        manager.sendPaste()
    }

    // MARK: - 에러 관리

    func testClearError() {
        let manager = MultipeerManager(role: .sender)
        manager.clearError()
        XCTAssertNil(manager.errorMessage)
    }

    // MARK: - stop()

    func testStopDoesNotCrash() {
        let manager = MultipeerManager(role: .sender)
        manager.stop()  // 시작 전 stop이어도 크래시 없어야 함
    }

    func testStartAndStop() {
        let manager = MultipeerManager(role: .sender)
        manager.start()
        manager.stop()
    }

    // MARK: - retry()

    func testRetryDoesNotCrash() {
        let manager = MultipeerManager(role: .sender)
        manager.retry()
        manager.stop()
    }
}
