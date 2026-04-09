import XCTest
@testable import RemoteKeyboard

final class SharedStorageTests: XCTestCase {

    private var storage: SharedStorage!
    private let testSuite = "com.remotekeyboard.test.\(UUID().uuidString)"

    override func setUp() {
        super.setUp()
        storage = SharedStorage(suiteName: testSuite)
        storage.clear()
    }

    override func tearDown() {
        storage.clear()
        UserDefaults().removePersistentDomain(forName: testSuite)
        super.tearDown()
    }

    // MARK: - save / read

    func testSaveAndRead() {
        let data = Data([0x01, 0x61, 0x62]) // insertText "ab"
        storage.save(messageData: data)

        let result = storage.read()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.data, data)
    }

    func testReadReturnsNilWhenEmpty() {
        XCTAssertNil(storage.read())
    }

    func testTimestampIsPositive() {
        let data = Data([0x01])
        let before = Date().timeIntervalSince1970
        storage.save(messageData: data)
        let after = Date().timeIntervalSince1970

        let result = storage.read()
        XCTAssertNotNil(result)
        XCTAssertGreaterThanOrEqual(result!.timestamp, before)
        XCTAssertLessThanOrEqual(result!.timestamp, after)
    }

    func testTimestampIncreasesOnSuccessiveSaves() {
        let data = Data([0x01])
        storage.save(messageData: data)
        let first = storage.read()?.timestamp ?? 0

        Thread.sleep(forTimeInterval: 0.01)
        storage.save(messageData: data)
        let second = storage.read()?.timestamp ?? 0

        XCTAssertGreaterThanOrEqual(second, first)
    }

    // MARK: - clear

    func testClearRemovesData() {
        storage.save(messageData: Data([0x01]))
        storage.clear()
        XCTAssertNil(storage.read())
    }

    func testClearAfterClearIsNoop() {
        storage.clear()
        storage.clear()
        XCTAssertNil(storage.read())
    }

    // MARK: - 메시지 타입 저장

    func testSaveInsertTextMessage() {
        let text = "hello"
        var message = Data([MessageType.insertText.rawValue])
        message.append(text.data(using: .utf8)!)
        storage.save(messageData: message)

        let result = storage.read()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.data[0], MessageType.insertText.rawValue)
        let decoded = String(data: result!.data.dropFirst(), encoding: .utf8)
        XCTAssertEqual(decoded, text)
    }

    func testSaveKoreanMessage() {
        let text = "안녕"
        var message = Data([MessageType.insertText.rawValue])
        message.append(text.data(using: .utf8)!)
        storage.save(messageData: message)

        let result = storage.read()
        let decoded = String(data: result!.data.dropFirst(), encoding: .utf8)
        XCTAssertEqual(decoded, text)
    }

    func testSaveLargeMessage() {
        let largeText = String(repeating: "a", count: 10_000)
        var message = Data([MessageType.insertText.rawValue])
        message.append(largeText.data(using: .utf8)!)
        storage.save(messageData: message)

        let result = storage.read()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.data.count, message.count)
    }

    // MARK: - save → read → clear → read 전체 순서

    func testFullLifecycle() {
        XCTAssertNil(storage.read(), "초기: nil")

        let data = Data([MessageType.insertText.rawValue]) + "test".data(using: .utf8)!
        storage.save(messageData: data)
        XCTAssertNotNil(storage.read(), "save 후: 데이터 있음")

        storage.clear()
        XCTAssertNil(storage.read(), "clear 후: nil")
    }

    func testOverwritePreviousMessage() {
        let first = Data([MessageType.insertText.rawValue]) + "first".data(using: .utf8)!
        let second = Data([MessageType.returnKey.rawValue])
        storage.save(messageData: first)
        storage.save(messageData: second)

        let result = storage.read()
        XCTAssertEqual(result?.data, second, "두 번째 save가 첫 번째를 덮어써야 합니다")
    }

    // MARK: - 단일 바이트 메시지 (페이로드 없는 타입)

    func testSaveSingleByteMessage() {
        let message = Data([MessageType.cursorLeft.rawValue])
        storage.save(messageData: message)
        let result = storage.read()
        XCTAssertEqual(result?.data, message)
    }
}
