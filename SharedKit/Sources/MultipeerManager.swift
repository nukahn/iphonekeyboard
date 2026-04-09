import Foundation
import MultipeerConnectivity
import UIKit

enum MCRole {
    case sender    // iPhone: advertises
    case receiver  // iPad: browses
}

enum ConnectionState {
    case disconnected
    case searching
    case connecting
    case connected(peerName: String)
}

/// Handles all Multipeer Connectivity logic.
/// iPhone uses .sender role (advertises), iPad uses .receiver role (browses + auto-invites).
final class MultipeerManager: NSObject, ObservableObject {

    @Published var connectionState: ConnectionState = .disconnected
    @Published var connectedPeers: [MCPeerID] = []
    @Published var errorMessage: String?

    // Called on the receiver (iPad) when a message arrives
    var onDataReceived: ((Data) -> Void)?

    private let role: MCRole
    private let myPeerID: MCPeerID
    private let session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    private var reconnectTimer: Timer?
    private(set) var reconnectDelay: TimeInterval = 1.0
    static let maxReconnectDelay: TimeInterval = 30.0
    static let initialReconnectDelay: TimeInterval = 1.0

    init(role: MCRole, displayName: String = UIDevice.current.name) {
        self.role = role
        self.myPeerID = MCPeerID(displayName: displayName)
        self.session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        super.init()
        self.session.delegate = self
    }

    // MARK: - Start / Stop

    func start() {
        switch role {
        case .sender:   startAdvertising()
        case .receiver: startBrowsing()
        }
    }

    func stop() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session.disconnect()
        cancelReconnect()
    }

    private func startAdvertising() {
        advertiser = MCNearbyServiceAdvertiser(
            peer: myPeerID,
            discoveryInfo: nil,
            serviceType: SharedConstants.serviceType
        )
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        DispatchQueue.main.async { self.connectionState = .searching }
    }

    private func startBrowsing() {
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: SharedConstants.serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        DispatchQueue.main.async { self.connectionState = .searching }
    }

    // MARK: - Send

    @discardableResult
    func send(type: MessageType, payload: Data = Data()) -> Bool {
        guard !session.connectedPeers.isEmpty else { return false }
        var message = Data([type.rawValue])
        message.append(payload)
        do {
            try session.send(message, toPeers: session.connectedPeers, with: .reliable)
            return true
        } catch {
            DispatchQueue.main.async { self.errorMessage = "전송 실패: \(error.localizedDescription)" }
            return false
        }
    }

    func sendText(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        send(type: .insertText, payload: data)
    }

    func sendDeleteBackward(count: Int = 1) {
        if count == 1 {
            send(type: .deleteOne)
        } else {
            guard let data = "\(count)".data(using: .utf8) else { return }
            send(type: .deleteN, payload: data)
        }
    }

    func sendReturn() { send(type: .returnKey) }

    func sendCursorLeft()  { send(type: .cursorLeft) }
    func sendCursorRight() { send(type: .cursorRight) }
    func sendCursorUp()    { send(type: .cursorUp) }
    func sendCursorDown()  { send(type: .cursorDown) }
    func sendSelectAll()   { send(type: .selectAll) }
    func sendCopy()        { send(type: .copy) }
    func sendPaste()       { send(type: .paste) }

    func retry() {
        stop()
        reconnectDelay = MultipeerManager.initialReconnectDelay
        start()
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Reconnect

    private func scheduleReconnect() {
        cancelReconnect()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: reconnectDelay, repeats: false) { [weak self] _ in
            self?.start()
        }
        reconnectDelay = min(reconnectDelay * 2, MultipeerManager.maxReconnectDelay)
    }

    private func cancelReconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
}

// MARK: - MCSessionDelegate

extension MultipeerManager: MCSessionDelegate {

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.reconnectDelay = MultipeerManager.initialReconnectDelay
                self.cancelReconnect()
                self.connectedPeers = session.connectedPeers
                self.connectionState = .connected(peerName: peerID.displayName)
            case .connecting:
                self.connectionState = .connecting
            case .notConnected:
                self.connectedPeers = session.connectedPeers
                if session.connectedPeers.isEmpty {
                    self.connectionState = .disconnected
                    self.scheduleReconnect()
                }
            @unknown default:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        onDataReceived?(data)
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate (iPhone)

extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
        DispatchQueue.main.async { self.connectionState = .connecting }
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        DispatchQueue.main.async {
            self.connectionState = .disconnected
            self.errorMessage = "광고 시작 실패: \(error.localizedDescription)"
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate (iPad)

extension MultipeerManager: MCNearbyServiceBrowserDelegate {

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
        DispatchQueue.main.async { self.connectionState = .connecting }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        DispatchQueue.main.async {
            self.connectionState = .disconnected
            self.errorMessage = "검색 시작 실패: \(error.localizedDescription)"
        }
    }
}
