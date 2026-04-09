import XCTest
@testable import RemoteKeyboard

/// StreamingTextView.computeDelta — UIKit 없이 테스트하는 순수 로직 검증.
final class StreamingDeltaTests: XCTestCase {

    // MARK: - 순수 삽입 (range.length == 0)

    func testInsertSingleChar() {
        let delta = StreamingTextView.computeDelta(range: NSRange(location: 0, length: 0), replacementText: "a")
        guard case .insert(let text) = delta else { return XCTFail("insert 예상") }
        XCTAssertEqual(text, "a")
    }

    func testInsertMultipleChars() {
        let delta = StreamingTextView.computeDelta(range: NSRange(location: 5, length: 0), replacementText: "hello")
        guard case .insert(let text) = delta else { return XCTFail("insert 예상") }
        XCTAssertEqual(text, "hello")
    }

    func testInsertKoreanChar() {
        let delta = StreamingTextView.computeDelta(range: NSRange(location: 0, length: 0), replacementText: "가")
        guard case .insert(let text) = delta else { return XCTFail("insert 예상") }
        XCTAssertEqual(text, "가")
    }

    func testInsertEmoji() {
        let delta = StreamingTextView.computeDelta(range: NSRange(location: 0, length: 0), replacementText: "😀")
        guard case .insert(let text) = delta else { return XCTFail("insert 예상") }
        XCTAssertEqual(text, "😀")
    }

    func testInsertNewline() {
        let delta = StreamingTextView.computeDelta(range: NSRange(location: 3, length: 0), replacementText: "\n")
        guard case .insert(let text) = delta else { return XCTFail("insert 예상") }
        XCTAssertEqual(text, "\n")
    }

    // MARK: - 순수 삭제 (replacementText == "")

    func testDeleteOnChar() {
        let delta = StreamingTextView.computeDelta(range: NSRange(location: 4, length: 1), replacementText: "")
        guard case .deleteBackward(let count) = delta else { return XCTFail("deleteBackward 예상") }
        XCTAssertEqual(count, 1)
    }

    func testDeleteMultipleChars() {
        let delta = StreamingTextView.computeDelta(range: NSRange(location: 0, length: 5), replacementText: "")
        guard case .deleteBackward(let count) = delta else { return XCTFail("deleteBackward 예상") }
        XCTAssertEqual(count, 5)
    }

    func testDeleteKoreanComposingChar() {
        // 한글 조합 중 이전 자모 삭제
        let delta = StreamingTextView.computeDelta(range: NSRange(location: 2, length: 1), replacementText: "")
        guard case .deleteBackward(let count) = delta else { return XCTFail("deleteBackward 예상") }
        XCTAssertEqual(count, 1)
    }

    // MARK: - 한글 조합 교체 (range.length > 0, replacementText != "")
    // iOS 한글 IME: 조합 중 ㅎ → 하 → 한 는 이전 문자를 교체한다

    func testKoreanCompositionReplace() {
        // "ㅎ"(1자)를 "하"로 교체
        let delta = StreamingTextView.computeDelta(range: NSRange(location: 0, length: 1), replacementText: "하")
        guard case .replace(let del, let ins) = delta else { return XCTFail("replace 예상") }
        XCTAssertEqual(del, 1)
        XCTAssertEqual(ins, "하")
    }

    func testKoreanCompositionReplaceMultiByte() {
        // "하"(1자)를 "한"으로 교체
        let delta = StreamingTextView.computeDelta(range: NSRange(location: 0, length: 1), replacementText: "한")
        guard case .replace(let del, let ins) = delta else { return XCTFail("replace 예상") }
        XCTAssertEqual(del, 1)
        XCTAssertEqual(ins, "한")
    }

    func testReplaceWithPaste() {
        // 선택 영역(3자)을 붙여넣기로 교체
        let delta = StreamingTextView.computeDelta(range: NSRange(location: 2, length: 3), replacementText: "world")
        guard case .replace(let del, let ins) = delta else { return XCTFail("replace 예상") }
        XCTAssertEqual(del, 3)
        XCTAssertEqual(ins, "world")
    }

    // MARK: - 빈 문자열 삽입 → nil (전송 없음)

    func testEmptyInsertReturnsNil() {
        let delta = StreamingTextView.computeDelta(range: NSRange(location: 0, length: 0), replacementText: "")
        XCTAssertNil(delta, "빈 문자열 삽입은 nil을 반환해야 합니다")
    }

    // MARK: - 경계값

    func testDeleteCountMatchesRangeLength() {
        for length in [1, 2, 5, 10, 100] {
            let delta = StreamingTextView.computeDelta(range: NSRange(location: 0, length: length), replacementText: "")
            guard case .deleteBackward(let count) = delta else {
                return XCTFail("length=\(length): deleteBackward 예상")
            }
            XCTAssertEqual(count, length, "deleteBackward count는 range.length와 같아야 합니다")
        }
    }

    func testLargeInsert() {
        let longText = String(repeating: "가", count: 1000)
        let delta = StreamingTextView.computeDelta(range: NSRange(location: 0, length: 0), replacementText: longText)
        guard case .insert(let text) = delta else { return XCTFail("insert 예상") }
        XCTAssertEqual(text.count, 1000)
    }

    func testMixedUnicodeInsert() {
        let text = "Hello 안녕 🌍"
        let delta = StreamingTextView.computeDelta(range: NSRange(location: 0, length: 0), replacementText: text)
        guard case .insert(let result) = delta else { return XCTFail("insert 예상") }
        XCTAssertEqual(result, text)
    }
}
