import UIKit

class KeyboardViewController: UIInputViewController {

    // MARK: - UI

    private var statusLabel: UILabel!
    private var nextKeyboardButton: UIButton!

    // MARK: - State

    private var pollingTimer: Timer?
    private var lastProcessedTimestamp: Double = 0

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        registerDarwinObserver()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startPollingTimer()
        updateStatusLabel()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPollingTimer()
    }

    deinit {
        DarwinNotificationCenter.shared.removeObservers(for: SharedConstants.darwinNotificationName)
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = UIColor.systemGroupedBackground

        // Next Keyboard 버튼 (Apple 가이드라인 필수)
        nextKeyboardButton = UIButton(type: .system)
        nextKeyboardButton.setTitle("🌐", for: .normal)
        nextKeyboardButton.titleLabel?.font = .systemFont(ofSize: 20)
        nextKeyboardButton.addTarget(self, action: #selector(advanceToNextInputMode), for: .touchUpInside)
        nextKeyboardButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nextKeyboardButton)

        // 상태 라벨
        statusLabel = UILabel()
        statusLabel.font = .systemFont(ofSize: 13)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 2
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            nextKeyboardButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nextKeyboardButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            nextKeyboardButton.widthAnchor.constraint(equalToConstant: 44),
            nextKeyboardButton.heightAnchor.constraint(equalToConstant: 44),

            statusLabel.leadingAnchor.constraint(equalTo: nextKeyboardButton.trailingAnchor, constant: 8),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            view.heightAnchor.constraint(equalToConstant: 80),
        ])
    }

    private func updateStatusLabel(error: String? = nil) {
        if let error = error {
            statusLabel.text = String(format: NSLocalizedString("keyboard.error", bundle: Bundle.main, comment: ""), error)
            statusLabel.textColor = .systemOrange
        } else {
            statusLabel.text = NSLocalizedString("keyboard.status", bundle: Bundle.main, comment: "")
            statusLabel.textColor = .secondaryLabel
        }
    }

    // MARK: - Darwin 알림 (기본, 저지연)

    private func registerDarwinObserver() {
        DarwinNotificationCenter.shared.observe(SharedConstants.darwinNotificationName) { [weak self] in
            self?.processInput()
        }
    }

    // MARK: - 폴링 타이머 (백업)

    private func startPollingTimer() {
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.processInput()
        }
    }

    private func stopPollingTimer() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    // MARK: - 입력 처리

    private func processInput() {
        guard let (data, timestamp) = SharedStorage.shared.read(),
              timestamp > lastProcessedTimestamp else { return }
        lastProcessedTimestamp = timestamp

        guard !data.isEmpty else { return }
        let prefix = data[0]

        switch MessageType(rawValue: prefix) {
        case .insertText:
            let text = String(data: data.dropFirst(), encoding: .utf8) ?? ""
            if !text.isEmpty {
                textDocumentProxy.insertText(text)
            }
        case .deleteOne:
            textDocumentProxy.deleteBackward()
        case .deleteN:
            let countStr = String(data: data.dropFirst(), encoding: .utf8) ?? "1"
            let count = Int(countStr) ?? 1
            for _ in 0..<count { textDocumentProxy.deleteBackward() }
        case .returnKey:
            textDocumentProxy.insertText("\n")
        case .cursorLeft:
            textDocumentProxy.adjustTextPosition(byCharacterOffset: -1)
        case .cursorRight:
            textDocumentProxy.adjustTextPosition(byCharacterOffset: 1)
        case .cursorUp:
            // textDocumentProxy는 줄 단위 이동 API가 없으므로 줄 길이 추정으로 근사
            let before = textDocumentProxy.documentContextBeforeInput ?? ""
            let lineLength = before.reversed().prefix(while: { $0 != "\n" }).count
            textDocumentProxy.adjustTextPosition(byCharacterOffset: -(lineLength + 1))
        case .cursorDown:
            let after = textDocumentProxy.documentContextAfterInput ?? ""
            let lineLength = after.prefix(while: { $0 != "\n" }).count
            textDocumentProxy.adjustTextPosition(byCharacterOffset: lineLength + 1)
        case .selectAll:
            // textDocumentProxy는 선택 API 미지원 → 전체 텍스트를 클립보드로 복사
            let before = textDocumentProxy.documentContextBeforeInput ?? ""
            let after = textDocumentProxy.documentContextAfterInput ?? ""
            UIPasteboard.general.string = before + after
        case .copy:
            // 커서 주변 컨텍스트 복사 (선택 영역 API 없음)
            let before = textDocumentProxy.documentContextBeforeInput ?? ""
            let after = textDocumentProxy.documentContextAfterInput ?? ""
            UIPasteboard.general.string = before + after
        case .paste:
            if let text = UIPasteboard.general.string {
                textDocumentProxy.insertText(text)
            }
        case nil:
            break
        }

        SharedStorage.shared.clear()
    }
}
