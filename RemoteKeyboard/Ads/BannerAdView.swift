import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView()
        banner.adUnitID = adUnitID
        banner.delegate = context.coordinator
        return banner
    }

    func updateUIView(_ bannerView: GADBannerView, context: Context) {
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }

        let width = min(
            UIScreen.main.bounds.width,
            windowScene.coordinateSpace.bounds.width
        )
        bannerView.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width)
        bannerView.rootViewController = rootVC

        if bannerView.responseInfo == nil {
            bannerView.load(GADRequest())
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, GADBannerViewDelegate {
        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            bannerView.isHidden = true
        }

        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            bannerView.isHidden = false
        }
    }
}
