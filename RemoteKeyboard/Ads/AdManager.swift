import Foundation
import GoogleMobileAds
import AppTrackingTransparency

@MainActor
final class AdManager {
    static let shared = AdManager()

    let bannerAdUnitID = "ca-app-pub-5484293743122557/7806355942"

    private var isInitialized = false

    private init() {}

    func initialize() {
        guard !isInitialized else { return }
        isInitialized = true
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        requestTrackingAuthorization()
    }

    private func requestTrackingAuthorization() {
        // iOS 14.5+ ATT 권한 요청 (1초 딜레이: Apple 권장)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }
    }
}
