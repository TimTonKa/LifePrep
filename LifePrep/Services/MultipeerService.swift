import MultipeerConnectivity
import Combine
import UIKit

final class MultipeerService: NSObject, ObservableObject {
    static let serviceType = "lifeprep"

    private let myPeerID: MCPeerID
    private var session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser
    private var browser: MCNearbyServiceBrowser

    @Published var connectedPeers: [MCPeerID] = []
    @Published var receivedMessages: [PeerMessage] = []
    @Published var discoveredPeers: [MCPeerID] = []
    @Published var isAdvertising: Bool = false
    @Published var connectionError: String?

    let messageSubject = PassthroughSubject<PeerMessage, Never>()
    let audioDataSubject = PassthroughSubject<(Data, MCPeerID), Never>()

    private let displayName: String

    init(displayName: String) {
        self.displayName = displayName
        self.myPeerID = MCPeerID(displayName: displayName)
        self.session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        self.advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: Self.serviceType)
        self.browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: Self.serviceType)
        super.init()
        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
    }

    func start() {
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
        isAdvertising = true
    }

    func stop() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        session.disconnect()
        isAdvertising = false
    }

    func invite(_ peer: MCPeerID) {
        browser.invitePeer(peer, to: session, withContext: nil, timeout: 10)
    }

    func sendMessage(_ message: PeerMessage, to peers: [MCPeerID]? = nil) {
        let targets = peers ?? session.connectedPeers
        guard !targets.isEmpty, let data = try? JSONEncoder().encode(message) else { return }
        try? session.send(data, toPeers: targets, with: .reliable)
    }

    func sendAudioData(_ data: Data) {
        guard !session.connectedPeers.isEmpty else { return }
        let message = PeerMessage(id: UUID().uuidString, senderId: myPeerID.displayName,
                                  senderName: displayName, text: "", imageData: data,
                                  timestamp: Date(), type: .voiceAudio)
        guard let encoded = try? JSONEncoder().encode(message) else { return }
        try? session.send(encoded, toPeers: session.connectedPeers, with: .unreliable)
    }

    var myDisplayName: String { myPeerID.displayName }
}

// MARK: - MCSessionDelegate

extension MultipeerService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.connectedPeers = session.connectedPeers
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let message = try? JSONDecoder().decode(PeerMessage.self, from: data) else { return }
        DispatchQueue.main.async {
            if message.type == .voiceAudio {
                if let audioData = message.imageData {
                    self.audioDataSubject.send((audioData, peerID))
                }
            } else {
                self.receivedMessages.append(message)
                self.messageSubject.send(message)
            }
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension MultipeerService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        DispatchQueue.main.async { self.connectionError = error.localizedDescription }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension MultipeerService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        DispatchQueue.main.async {
            if !self.discoveredPeers.contains(peerID) {
                self.discoveredPeers.append(peerID)
            }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.discoveredPeers.removeAll { $0 == peerID }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        DispatchQueue.main.async { self.connectionError = error.localizedDescription }
    }
}
