import SwiftUI

struct IPadReceiverView: View {
    @StateObject private var mc = MultipeerManager(role: .receiver)
    @State private var receivedLog: [String] = []
    @State private var showOnboarding = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 배너 광고
                BannerAdView(adUnitID: AdManager.shared.bannerAdUnitID)
                    .frame(height: 50)

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

                HStack(spacing: 16) {
                    Button {
                        showOnboarding = true
                    } label: {
                        Label(String(localized: "btn.keyboard.setup"), systemImage: "keyboard")
                    }

                    if case .disconnected = mc.connectionState {
                        Button {
                            mc.retry()
                        } label: {
                            Label(String(localized: "btn.reconnect"), systemImage: "arrow.clockwise")
                        }
                        .tint(.orange)
                    }
                }
                .padding()
            }
            .navigationTitle(String(localized: "nav.title.ipad"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button(String(localized: "btn.clear.log")) { receivedLog.removeAll() })
            .sheet(isPresented: $showOnboarding) {
                OnboardingView()
            }
            .alert(String(localized: "error.connection.title"), isPresented: Binding(
                get: { mc.errorMessage != nil },
                set: { if !$0 { mc.clearError() } }
            )) {
                Button(String(localized: "error.btn.confirm")) { mc.clearError() }
                Button(String(localized: "error.btn.retry")) { mc.retry() }
            } message: {
                Text(mc.errorMessage ?? "")
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
            SharedStorage.shared.save(messageData: data)
            DarwinNotificationCenter.shared.post(SharedConstants.darwinNotificationName)
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
            return String(format: String(localized: "log.insert"), text)
        case .deleteOne:
            return String(localized: "log.delete.one")
        case .deleteN:
            let n = String(data: data.dropFirst(), encoding: .utf8) ?? "?"
            return String(format: String(localized: "log.delete.n"), n)
        case .returnKey:
            return String(localized: "log.return")
        case .cursorLeft:
            return String(localized: "log.cursor.left")
        case .cursorRight:
            return String(localized: "log.cursor.right")
        case .cursorUp:
            return String(localized: "log.cursor.up")
        case .cursorDown:
            return String(localized: "log.cursor.down")
        case .selectAll:
            return String(localized: "log.select.all")
        case .copy:
            return String(localized: "log.copy")
        case .paste:
            return String(localized: "log.paste")
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
        case .connected(let name): return String(format: String(localized: "status.connected"), name)
        case .connecting: return String(localized: "status.connecting")
        case .searching: return String(localized: "status.searching.iphone")
        case .disconnected: return String(localized: "status.disconnected")
        }
    }

    private var headerSubtitle: String {
        switch mc.connectionState {
        case .connected: return String(localized: "connection.subtitle.connected")
        case .connecting: return String(localized: "connection.subtitle.connecting")
        case .searching: return String(localized: "connection.subtitle.searching")
        case .disconnected: return String(localized: "connection.subtitle.disconnected")
        }
    }
}

// MARK: - 온보딩: 키보드 설정 안내

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss

    private var steps: [(String, String, String)] {
        [
            ("1", String(localized: "onboarding.step1.title"), String(localized: "onboarding.step1.desc")),
            ("2", String(localized: "onboarding.step2.title"), String(localized: "onboarding.step2.desc")),
            ("3", String(localized: "onboarding.step3.title"), String(localized: "onboarding.step3.desc")),
            ("4", String(localized: "onboarding.step4.title"), String(localized: "onboarding.step4.desc")),
            ("5", String(localized: "onboarding.step5.title"), String(localized: "onboarding.step5.desc")),
        ]
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(String(localized: "onboarding.intro"))
                        .padding(.vertical, 4)
                }

                Section(String(localized: "onboarding.section.steps")) {
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
                        Label(String(localized: "onboarding.btn.settings"), systemImage: "gear")
                    }
                }
            }
            .navigationTitle(String(localized: "onboarding.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "onboarding.done")) { dismiss() }
                }
            }
        }
    }
}

#Preview {
    IPadReceiverView()
}
