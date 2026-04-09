import XCTest
@testable import RemoteKeyboard

final class MessageProtocolTests: XCTestCase {

    // MARK: - 프로토콜 파싱 헬퍼

    private func makeMessage(type: MessageType, payload: String = "") -> Data {
        var data = Data([type.rawValue])
        if !payload.isEmpty {
            data.append(payload.data(using: .utf8)!)
        }
        return data
    }

    private func parseType(_ data: Data) -> MessageType? {
        guard !data.isEmpty else { return nil }
        return MessageType(rawValue: data[0])
    }

    private func parseTextPayload(_ data: Data) -> String? {
        String(data: data.dropFirst(), encoding: .utf8)
    }

    // MARK: - 기본 파싱

    func testParseInsertText() {
        let msg = makeMessage(type: .insertText, payload: "hello")
        XCTAssertEqual(parseType(msg), .insertText)
        XCTAssertEqual(parseTextPayload(msg), "hello")
    }

    func testParseDeleteOne() {
        let msg = makeMessage(type: .deleteOne)
        XCTAssertEqual(parseType(msg), .deleteOne)
        XCTAssertEqual(msg.count, 1)
    }

    func testParseDeleteN() {
        let msg = makeMessage(type: .deleteN, payload: "7")
        XCTAssertEqual(parseType(msg), .deleteN)
        XCTAssertEqual(Int(parseTextPayload(msg) ?? ""), 7)
    }

    func testParseReturnKey() {
        let msg = makeMessage(type: .returnKey)
        XCTAssertEqual(parseType(msg), .returnKey)
    }

    func testParseCursorCommands() {
        let types: [MessageType] = [.cursorLeft, .cursorRight, .cursorUp, .cursorDown, .selectAll, .copy, .paste]
        for type in types {
            let msg = makeMessage(type: type)
            XCTAssertEqual(parseType(msg), type, "\(type) 파싱 실패")
        }
    }

    func testParseUnknownType() {
        let data = Data([0xFF])
        XCTAssertNil(parseType(data))
    }

    func testParseEmptyData() {
        XCTAssertNil(parseType(Data()))
    }

    // MARK: - 한글/유니코드

    func testKoreanTextRoundTrip() {
        let text = "안녕하세요 세계"
        let msg = makeMessage(type: .insertText, payload: text)
        XCTAssertEqual(parseTextPayload(msg), text)
    }

    func testHangulCompositionCharacters() {
        // 조합 중간 단계 문자 (자모)
        let jamo = "ㅎㅏㄴ"
        let msg = makeMessage(type: .insertText, payload: jamo)
        XCTAssertEqual(parseTextPayload(msg), jamo)
    }

    func testEmojiRoundTrip() {
        let text = "😀🎉🌟💻"
        let msg = makeMessage(type: .insertText, payload: text)
        XCTAssertEqual(parseTextPayload(msg), text)
    }

    func testMixedTextRoundTrip() {
        let text = "Hello 안녕 🌍 123"
        let msg = makeMessage(type: .insertText, payload: text)
        XCTAssertEqual(parseTextPayload(msg), text)
    }

    func testEmptyTextPayload() {
        let msg = makeMessage(type: .insertText, payload: "")
        XCTAssertEqual(parseType(msg), .insertText)
        XCTAssertEqual(parseTextPayload(msg), "")
    }

    func testLongTextPayload() {
        let text = String(repeating: "가나다라마", count: 1000)
        let msg = makeMessage(type: .insertText, payload: text)
        XCTAssertEqual(parseTextPayload(msg), text)
    }

    // MARK: - deleteN 경계값

    func testDeleteNWithOne() {
        let msg = makeMessage(type: .deleteN, payload: "1")
        XCTAssertEqual(Int(parseTextPayload(msg) ?? ""), 1)
    }

    func testDeleteNWithLargeCount() {
        let msg = makeMessage(type: .deleteN, payload: "9999")
        XCTAssertEqual(Int(parseTextPayload(msg) ?? ""), 9999)
    }

    // MARK: - 메시지 직렬화 안전성

    func testFirstByteAlwaysIsType() {
        let messages: [Data] = [
            makeMessage(type: .insertText, payload: "abc"),
            makeMessage(type: .deleteOne),
            makeMessage(type: .cursorLeft),
        ]
        for msg in messages {
            XCTAssertNotNil(parseType(msg), "메시지의 첫 바이트는 유효한 MessageType이어야 합니다")
        }
    }

    // MARK: - 알 수 없는 prefix → nil (무시)

    func testUnknownPrefixReturnsNil() {
        for byte: UInt8 in [0x00, 0x0C, 0x7F, 0xFF] {
            let data = Data([byte])
            XCTAssertNil(parseType(data), "알 수 없는 prefix 0x\(String(byte, radix: 16))는 nil이어야 합니다")
        }
    }

    func testUnknownPrefixDoesNotCrash() {
        // 알 수 없는 타입을 받아도 switch가 안전하게 nil 처리해야 함
        for byte: UInt8 in [0x00, 0x0C, 0xFF] {
            let data = Data([byte, 0x01, 0x02])
            XCTAssertNil(parseType(data))
        }
    }

    // MARK: - deleteN = 0 경계값

    func testDeleteNWithZero() {
        let msg = makeMessage(type: .deleteN, payload: "0")
        XCTAssertEqual(Int(parseTextPayload(msg) ?? "-1"), 0)
    }

    // MARK: - 빈 페이로드 파싱 안전성

    func testEmptyPayloadOnInsertType() {
        let msg = makeMessage(type: .insertText, payload: "")
        XCTAssertEqual(parseType(msg), .insertText)
        XCTAssertEqual(parseTextPayload(msg), "")
    }

    func testSingleByteMessageNoCrash() {
        let singleBytes: [MessageType] = [
            .deleteOne, .returnKey, .cursorLeft, .cursorRight,
            .cursorUp, .cursorDown, .selectAll, .copy, .paste
        ]
        for type in singleBytes {
            let msg = Data([type.rawValue])
            XCTAssertEqual(parseType(msg), type, "\(type) 단일 바이트 파싱 실패")
        }
    }
}
