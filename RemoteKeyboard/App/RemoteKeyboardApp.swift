import SwiftUI

@main
struct RemoteKeyboardApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .onAppear {
                    AdManager.shared.initialize()
                }
        }
    }
}

struct RootView: View {
    var body: some View {
        #if targetEnvironment(macCatalyst)
        Text(String(localized: "mac.unsupported"))
        #else
        if UIDevice.current.userInterfaceIdiom == .phone {
            IPhoneSenderView()
        } else {
            IPadReceiverView()
        }
        #endif
    }
}
