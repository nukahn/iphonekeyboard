import SwiftUI
import UIKit

/// UITextView 기반 실시간 스트리밍 입력 컴포넌트.
/// shouldChangeTextIn 델리게이트로 한글 조합 포함 모든 변경을 정확히 캡처한다.
struct StreamingTextView: UIViewRepresentable {
    @Binding var text: String
    var isEnabled: Bool
    var placeholder: String
    var onDelta: (TextDelta) -> Void

    enum TextDelta {
        case insert(String)
        case deleteBackward(Int)
        case replace(delete: Int, insert: String)
    }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        tv.font = .preferredFont(forTextStyle: .body)
        tv.layer.cornerRadius = 8
        tv.layer.borderWidth = 1
        tv.layer.borderColor = UIColor.systemGray4.cgColor
        tv.backgroundColor = .systemBackground
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6)
        tv.isScrollEnabled = true
        context.coordinator.updatePlaceholder(tv, text: text, placeholder: placeholder)
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        tv.isEditable = isEnabled
        tv.alpha = isEnabled ? 1.0 : 0.5
        if !tv.isFirstResponder && tv.text != text {
            tv.text = text
            context.coordinator.updatePlaceholder(tv, text: text, placeholder: placeholder)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    /// UIKit 없이 테스트 가능한 순수 델타 계산 함수.
    /// shouldChangeTextIn 델리게이트의 range/replacementText를 그대로 전달한다.
    static func computeDelta(range: NSRange, replacementText: String) -> TextDelta? {
        if range.length > 0 && replacementText.isEmpty {
            return .deleteBackward(range.length)
        } else if range.length > 0 && !replacementText.isEmpty {
            return .replace(delete: range.length, insert: replacementText)
        } else if !replacementText.isEmpty {
            return .insert(replacementText)
        }
        return nil  // 빈 문자열 삽입 — 전송 없음
    }

    @MainActor
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: StreamingTextView
        private var placeholderLabel: UILabel?

        init(_ parent: StreamingTextView) {
            self.parent = parent
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if let delta = StreamingTextView.computeDelta(range: range, replacementText: text) {
                parent.onDelta(delta)
            }
            return true
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text ?? ""
            updatePlaceholder(textView, text: textView.text ?? "", placeholder: parent.placeholder)
        }

        func updatePlaceholder(_ textView: UITextView, text: String, placeholder: String) {
            if placeholderLabel == nil {
                let label = UILabel()
                label.font = .preferredFont(forTextStyle: .body)
                label.textColor = .placeholderText
                label.numberOfLines = 0
                label.translatesAutoresizingMaskIntoConstraints = false
                textView.addSubview(label)
                NSLayoutConstraint.activate([
                    label.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 12),
                    label.topAnchor.constraint(equalTo: textView.topAnchor, constant: 8),
                    label.trailingAnchor.constraint(equalTo: textView.trailingAnchor, constant: -8),
                ])
                placeholderLabel = label
            }
            placeholderLabel?.text = placeholder
            placeholderLabel?.isHidden = !text.isEmpty
        }
    }
}
