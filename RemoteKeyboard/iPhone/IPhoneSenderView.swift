import SwiftUI

struct IPhoneSenderView: View {
    @StateObject private var mc = MultipeerManager(role: .sender)
    @State private var inputText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 배너 광고
                BannerAdView(adUnitID: AdManager.shared.bannerAdUnitID)
                    .frame(height: 50)

                VStack(spacing: 16) {
                    // 연결 상태 배너
                    connectionBanner

                    // 실시간 스트리밍 텍스트 입력 영역
                    StreamingTextView(
                        text: $inputText,
                        isEnabled: isConnected,
                        placeholder: String(localized: "input.placeholder"),
                        onDelta: handleDelta
                    )
                    .frame(minHeight: 120, maxHeight: 220)

                    // 특수키 버튼 행
                    specialKeyRow

                    // 커서 이동 버튼 행
                    cursorKeyRow
                }
                .padding()

                Spacer()

                // 사용 안내
                if !isConnected {
                    Text(String(localized: "hint.open.app"))
                        .multilineTextAlignment(.center)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.bottom)
                }
            }
            .navigationTitle(String(localized: "nav.title.iphone"))
            .navigationBarTitleDisplayMode(.inline)
            .alert(String(localized: "error.title"), isPresented: Binding(
                get: { mc.errorMessage != nil },
                set: { if !$0 { mc.clearError() } }
            )) {
                Button(String(localized: "error.btn.confirm")) { mc.clearError() }
                Button(String(localized: "error.btn.retry")) { mc.retry() }
            } message: {
                Text(mc.errorMessage ?? "")
            }
        }
        .onAppear { mc.start() }
        .onDisappear { mc.stop() }
    }

    // MARK: - Delta 처리

    private func handleDelta(_ delta: StreamingTextView.TextDelta) {
        guard isConnected else { return }
        switch delta {
        case .insert(let text):
            mc.sendText(text)
        case .deleteBackward(let count):
            mc.sendDeleteBackward(count: count)
        case .replace(let deleteCount, let insertText):
            mc.sendDeleteBackward(count: deleteCount)
            if !insertText.isEmpty {
                mc.sendText(insertText)
            }
        }
    }

    // MARK: - 연결 상태

    private var isConnected: Bool {
        if case .connected = mc.connectionState { return true }
        return false
    }

    // MARK: - 특수키 버튼 행

    private var specialKeyRow: some View {
        HStack(spacing: 12) {
            SpecialKeyButton(title: String(localized: "key.delete")) {
                mc.sendDeleteBackward()
            }
            .disabled(!isConnected)

            SpecialKeyButton(title: String(localized: "key.enter")) {
                mc.sendReturn()
            }
            .disabled(!isConnected)

            Spacer()

            if !isConnected {
                Button(action: { mc.retry() }) {
                    Label(String(localized: "key.retry"), systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - 커서 이동 버튼 행

    private var cursorKeyRow: some View {
        HStack(spacing: 8) {
            SpecialKeyButton(title: String(localized: "key.cursor.left")) { mc.sendCursorLeft() }.disabled(!isConnected)
            SpecialKeyButton(title: String(localized: "key.cursor.right")) { mc.sendCursorRight() }.disabled(!isConnected)
            SpecialKeyButton(title: String(localized: "key.cursor.up")) { mc.sendCursorUp() }.disabled(!isConnected)
            SpecialKeyButton(title: String(localized: "key.cursor.down")) { mc.sendCursorDown() }.disabled(!isConnected)

            Spacer()

            SpecialKeyButton(title: String(localized: "key.select.all")) { mc.sendSelectAll() }.disabled(!isConnected)
            SpecialKeyButton(title: String(localized: "key.copy")) { mc.sendCopy() }.disabled(!isConnected)
            SpecialKeyButton(title: String(localized: "key.paste")) { mc.sendPaste() }.disabled(!isConnected)
        }
    }

    // MARK: - 연결 상태 배너

    private var connectionBanner: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(bannerColor)
                .frame(width: 10, height: 10)
            Text(bannerText)
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(bannerColor.opacity(0.12), in: Capsule())
    }

    private var bannerColor: Color {
        switch mc.connectionState {
        case .connected: return .green
        case .connecting: return .orange
        case .searching: return .blue
        case .disconnected: return .gray
        }
    }

    private var bannerText: String {
        switch mc.connectionState {
        case .connected(let name): return String(format: String(localized: "status.connected"), name)
        case .connecting: return String(localized: "status.connecting")
        case .searching: return String(localized: "status.searching.ipad")
        case .disconnected: return String(localized: "status.disconnected")
        }
    }
}

struct SpecialKeyButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(minWidth: 44)
        }
        .buttonStyle(.bordered)
    }
}

#Preview {
    IPhoneSenderView()
}
