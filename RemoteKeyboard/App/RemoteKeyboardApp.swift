import SwiftUI

@main
struct RemoteKeyboardApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    var body: some View {
        #if targetEnvironment(macCatalyst)
        Text("Mac은 지원하지 않습니다.")
        #else
        if UIDevice.current.userInterfaceIdiom == .phone {
            IPhoneSenderView()
        } else {
            IPadReceiverView()
        }
        #endif
    }
}
