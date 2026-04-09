import XCTest
@testable import RemoteKeyboard

final class SharedConstantsTests: XCTestCase {

    // MARK: - App Group / Service 상수

    func testAppGroupID() {
        XCTAssertEqual(SharedConstants.appGroupID, "group.com.remotekeyboard")
    }

    func testServiceType() {
        XCTAssertEqual(SharedConstants.serviceType, "remotekb")
        XCTAssertLessThanOrEqual(SharedConstants.serviceType.count, 15,
            "Bonjour service type must be 15 chars or fewer")
        XCTAssertTrue(SharedConstants.serviceType.allSatisfy { $0.isLetter || $0 == "-" },
            "Service type must only contain letters and hyphens")
    }

    func testDarwinNotificationName() {
        XCTAssertFalse(SharedConstants.darwinNotificationName.isEmpty)
    }

    // MARK: - MessageType raw values 안정성

    func testMessageTypeRawValues() {
        XCTAssertEqual(MessageType.insertText.rawValue, 0x01)
        XCTAssertEqual(MessageType.deleteOne.rawValue,  0x02)
        XCTAssertEqual(MessageType.deleteN.rawValue,    0x03)
        XCTAssertEqual(MessageType.returnKey.rawValue,  0x04)
        XCTAssertEqual(MessageType.cursorLeft.rawValue, 0x05)
        XCTAssertEqual(MessageType.cursorRight.rawValue,0x06)
        XCTAssertEqual(MessageType.cursorUp.rawValue,   0x07)
        XCTAssertEqual(MessageType.cursorDown.rawValue, 0x08)
        XCTAssertEqual(MessageType.selectAll.rawValue,  0x09)
        XCTAssertEqual(MessageType.copy.rawValue,       0x0A)
        XCTAssertEqual(MessageType.paste.rawValue,      0x0B)
    }

    func testMessageTypeRawValuesAreUnique() {
        let allTypes: [MessageType] = [
            .insertText, .deleteOne, .deleteN, .returnKey,
            .cursorLeft, .cursorRight, .cursorUp, .cursorDown,
            .selectAll, .copy, .paste
        ]
        let rawValues = allTypes.map { $0.rawValue }
        XCTAssertEqual(rawValues.count, Set(rawValues).count, "모든 MessageType raw value는 고유해야 합니다")
    }

    func testMessageTypeInitFromRawValue() {
        XCTAssertEqual(MessageType(rawValue: 0x01), .insertText)
        XCTAssertEqual(MessageType(rawValue: 0x04), .returnKey)
        XCTAssertEqual(MessageType(rawValue: 0x0B), .paste)
        XCTAssertNil(MessageType(rawValue: 0x00))
        XCTAssertNil(MessageType(rawValue: 0xFF))
    }

    // MARK: - 메시지 인코딩 / 디코딩

    func testEncodeInsertText() {
        let text = "hello"
        var message = Data([MessageType.insertText.rawValue])
        message.append(text.data(using: .utf8)!)

        XCTAssertEqual(message[0], MessageType.insertText.rawValue)
        let decoded = String(data: message.dropFirst(), encoding: .utf8)
        XCTAssertEqual(decoded, "hello")
    }

    func testEncodeKoreanText() {
        let text = "안녕하세요"
        var message = Data([MessageType.insertText.rawValue])
        message.append(text.data(using: .utf8)!)

        let decoded = String(data: message.dropFirst(), encoding: .utf8)
        XCTAssertEqual(decoded, "안녕하세요")
    }

    func testEncodeEmoji() {
        let text = "👋🌍"
        var message = Data([MessageType.insertText.rawValue])
        message.append(text.data(using: .utf8)!)

        let decoded = String(data: message.dropFirst(), encoding: .utf8)
        XCTAssertEqual(decoded, "👋🌍")
    }

    func testEncodeDeleteOne() {
        let message = Data([MessageType.deleteOne.rawValue])
        XCTAssertEqual(message.count, 1)
        XCTAssertEqual(MessageType(rawValue: message[0]), .deleteOne)
    }

    func testEncodeDeleteN() {
        let count = 5
        var message = Data([MessageType.deleteN.rawValue])
        message.append("\(count)".data(using: .utf8)!)

        let countStr = String(data: message.dropFirst(), encoding: .utf8)
        XCTAssertEqual(Int(countStr ?? ""), count)
    }

    func testEncodeCursorCommands() {
        let types: [MessageType] = [.cursorLeft, .cursorRight, .cursorUp, .cursorDown, .selectAll, .copy, .paste]
        for type in types {
            let message = Data([type.rawValue])
            XCTAssertEqual(message.count, 1)
            XCTAssertEqual(MessageType(rawValue: message[0]), type)
        }
    }
}
