import SwiftUI

struct IPadReceiverView: View {
    @StateObject private var mc = MultipeerManager(role: .receiver)
    @State private var receivedLog: [String] = []
    @State private var showOnboarding = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 연결 상태 헤더
                connectionHeader
                    .padding()

                Divider()

                // 수신 로그
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(receivedLog.enumerated()), id: \.offset) { index, line in
                                Text(line)
                                    .font(.system(.body, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .id(index)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: receivedLog.count) { count in
                        if count > 0 {
                            proxy.scrollTo(count - 1)
                        }
                    }
                }

                Divider()

                // 키보드 설정 안내 버튼
                Button {
                    showOnboarding = true
                } label: {
                    Label("키보드 설정 방법 보기", systemImage: "keyboard")
                }
                .padding()
            }
            .navigationTitle("RemoteKeyboard — iPad")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("로그 지우기") { receivedLog.removeAll() })
            .sheet(isPresented: $showOnboarding) {
                OnboardingView()
            }
        }
        .onAppear {
            mc.start()
            setupDataReceiver()
        }
        .onDisappear { mc.stop() }
    }

    // MARK: - 데이터 수신 → App Group 브릿지

    private func setupDataReceiver() {
        mc.onDataReceived = { data in
            // 1. App Group에 저장
            SharedStorage.shared.save(messageData: data)
            // 2. 키보드 익스텐션에 Darwin 알림 발송
            DarwinNotificationCenter.shared.post(SharedConstants.darwinNotificationName)
            // 3. 수신 로그 업데이트 (디버깅용)
            DispatchQueue.main.async {
                if let text = parseLogMessage(data) {
                    receivedLog.append(text)
                }
            }
        }
    }

    private func parseLogMessage(_ data: Data) -> String? {
        guard !data.isEmpty else { return nil }
        let prefix = data[0]
        switch MessageType(rawValue: prefix) {
        case .insertText:
            let text = String(data: data.dropFirst(), encoding: .utf8) ?? "?"
            return "삽입: \"\(text)\""
        case .deleteOne:
            return "← 삭제"
        case .deleteN:
            let n = String(data: data.dropFirst(), encoding: .utf8) ?? "?"
            return "← 삭제 ×\(n)"
        case .returnKey:
            return "↵ 줄바꿈"
        case nil:
            return nil
        }
    }

    // MARK: - 연결 상태 헤더

    private var connectionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Circle().fill(headerColor).frame(width: 12, height: 12)
                    Text(headerTitle).font(.headline)
                }
                Text(headerSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var headerColor: Color {
        switch mc.connectionState {
        case .connected: return .green
        case .connecting: return .orange
        case .searching: return .blue
        case .disconnected: return .gray
        }
    }

    private var headerTitle: String {
        switch mc.connectionState {
        case .connected(let name): return "\(name) 연결됨"
        case .connecting: return "연결 중..."
        case .searching: return "iPhone 검색 중..."
        case .disconnected: return "연결 안됨"
        }
    }

    private var headerSubtitle: String {
        switch mc.connectionState {
        case .connected: return "iPhone 키보드 입력이 이 iPad로 전달됩니다"
        case .connecting: return "잠시만 기다려주세요"
        case .searching: return "iPhone에서 RemoteKeyboard 앱을 실행하세요"
        case .disconnected: return "앱을 재시작하거나 잠시 기다려주세요"
        }
    }
}

// MARK: - 온보딩: 키보드 설정 안내

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss

    private let steps = [
        ("1", "설정 앱 열기", "iPad에서 설정(Settings) 앱을 엽니다."),
        ("2", "키보드 설정으로 이동", "일반 → 키보드 → 키보드 → 새 키보드 추가"),
        ("3", "RemoteKeyboard 선택", "목록에서 RemoteKeyboard를 찾아 탭하세요."),
        ("4", "전체 허용 활성화", "RemoteKeyboard → '전체 허용'을 켜세요.\n(App Group 접근에 필요합니다)"),
        ("5", "키보드 전환", "어떤 앱에서든 키보드의 지구본(🌐) 버튼을 눌러\nRemoteKeyboard로 전환하세요."),
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("iPhone을 iPad 키보드로 사용하려면 아래 단계를 따라 RemoteKeyboard를 시스템 키보드로 등록하세요.")
                        .padding(.vertical, 4)
                }

                Section("설정 단계") {
                    ForEach(steps, id: \.0) { step in
                        HStack(alignment: .top, spacing: 12) {
                            Text(step.0)
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                .background(.blue, in: Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(step.1).font(.headline)
                                Text(step.2).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("설정 앱 열기", systemImage: "gear")
                    }
                }
            }
            .navigationTitle("키보드 설정 안내")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    IPadReceiverView()
}
