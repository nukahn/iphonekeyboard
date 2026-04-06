import SwiftUI

struct IPhoneSenderView: View {
    @StateObject private var mc = MultipeerManager(role: .sender)
    @State private var inputText = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 연결 상태 배너
                connectionBanner

                Spacer()

                // 텍스트 입력 영역
                VStack(spacing: 12) {
                    TextField("여기에 입력하세요...", text: $inputText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(5...10)
                        .focused($isTextFieldFocused)
                        .disabled(!isConnected)

                    // 특수키 버튼 행
                    HStack(spacing: 12) {
                        SpecialKeyButton(title: "⌫ 삭제") {
                            mc.sendDeleteBackward()
                            if !inputText.isEmpty {
                                inputText.removeLast()
                            }
                        }
                        .disabled(!isConnected)

                        SpecialKeyButton(title: "↵ 엔터") {
                            mc.sendReturn()
                        }
                        .disabled(!isConnected)

                        Spacer()

                        Button(action: sendText) {
                            Label("전송", systemImage: "paperplane.fill")
                                .frame(minWidth: 80)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!isConnected || inputText.isEmpty)
                    }
                }
                .padding(.horizontal)

                Spacer()

                // 사용 안내
                if !isConnected {
                    Text("iPad에서 RemoteKeyboard 앱을 실행하면\n자동으로 연결됩니다.")
                        .multilineTextAlignment(.center)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .navigationTitle("RemoteKeyboard")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            mc.start()
            isTextFieldFocused = true
        }
        .onDisappear { mc.stop() }
    }

    private var isConnected: Bool {
        if case .connected = mc.connectionState { return true }
        return false
    }

    private func sendText() {
        guard !inputText.isEmpty else { return }
        mc.sendText(inputText)
        inputText = ""
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
        case .connected(let name): return "\(name)에 연결됨"
        case .connecting: return "연결 중..."
        case .searching: return "iPad 검색 중..."
        case .disconnected: return "연결 안됨"
        }
    }
}

struct SpecialKeyButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(minWidth: 70)
        }
        .buttonStyle(.bordered)
    }
}

#Preview {
    IPhoneSenderView()
}
