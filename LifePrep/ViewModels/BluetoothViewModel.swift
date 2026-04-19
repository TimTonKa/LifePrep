import MultipeerConnectivity
import SwiftData
import Combine

@MainActor
final class BluetoothViewModel: ObservableObject {
    @Published var messages: [PeerMessage] = []
    @Published var connectedPeers: [MCPeerID] = []
    @Published var discoveredPeers: [MCPeerID] = []
    @Published var isConnecting: Bool = false
    @Published var errorMessage: String?
    @Published var isInCall: Bool = false

    let multipeerService: MultipeerService
    private let audioService = AudioStreamingService()
    private var cancellables = Set<AnyCancellable>()
    private let context: ModelContext
    private let roomId: String = "bluetooth-local"

    init(displayName: String, context: ModelContext) {
        self.context = context
        self.multipeerService = MultipeerService(displayName: displayName)

        multipeerService.$connectedPeers
            .receive(on: DispatchQueue.main)
            .assign(to: &$connectedPeers)

        multipeerService.$discoveredPeers
            .receive(on: DispatchQueue.main)
            .assign(to: &$discoveredPeers)

        multipeerService.messageSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.handleIncomingMessage(message)
            }
            .store(in: &cancellables)

        multipeerService.audioDataSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (data, _) in
                self?.audioService.playReceivedAudio(data)
            }
            .store(in: &cancellables)

        audioService.onAudioCaptured = { [weak self] data in
            self?.multipeerService.sendAudioData(data)
        }

        loadLocalMessages()
    }

    func start() { multipeerService.start() }
    func stop() { multipeerService.stop() }

    func invite(_ peer: MCPeerID) {
        isConnecting = true
        multipeerService.invite(peer)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.isConnecting = false
        }
    }

    func sendText(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let message = PeerMessage(
            id: UUID().uuidString,
            senderId: multipeerService.myDisplayName,
            senderName: multipeerService.myDisplayName,
            text: text,
            imageData: nil,
            timestamp: Date(),
            type: .text
        )
        multipeerService.sendMessage(message)
        messages.append(message)
        saveMessage(message)
    }

    func sendImage(_ data: Data) {
        let message = PeerMessage(
            id: UUID().uuidString,
            senderId: multipeerService.myDisplayName,
            senderName: multipeerService.myDisplayName,
            text: "📷 圖片",
            imageData: data,
            timestamp: Date(),
            type: .image
        )
        multipeerService.sendMessage(message)
        messages.append(message)
        saveMessage(message)
    }

    func startVoiceCall() {
        guard !connectedPeers.isEmpty else { return }
        isInCall = true
        audioService.startCapture()
        let msg = PeerMessage(id: UUID().uuidString, senderId: multipeerService.myDisplayName,
                              senderName: multipeerService.myDisplayName, text: "",
                              timestamp: Date(), type: .voiceStart)
        multipeerService.sendMessage(msg)
    }

    func endVoiceCall() {
        isInCall = false
        audioService.stopCapture()
        let msg = PeerMessage(id: UUID().uuidString, senderId: multipeerService.myDisplayName,
                              senderName: multipeerService.myDisplayName, text: "",
                              timestamp: Date(), type: .voiceStop)
        multipeerService.sendMessage(msg)
    }

    private func handleIncomingMessage(_ message: PeerMessage) {
        messages.append(message)
        if message.type == .voiceStart && !isInCall {
            isInCall = true
            audioService.startCapture()
        } else if message.type == .voiceStop {
            isInCall = false
            audioService.stopCapture()
        }
        saveMessage(message)
    }

    private func saveMessage(_ message: PeerMessage) {
        let local = LocalMessage(
            id: message.id, roomId: roomId,
            senderId: message.senderId, senderName: message.senderName,
            text: message.text, imageData: message.imageData,
            timestamp: message.timestamp, isDelivered: true, source: .bluetooth
        )
        context.insert(local)
        try? context.save()
    }

    private func loadLocalMessages() {
        let roomId = self.roomId
        let descriptor = FetchDescriptor<LocalMessage>(
            predicate: #Predicate { $0.roomId == roomId },
            sortBy: [SortDescriptor(\LocalMessage.timestamp)]
        )
        let local = (try? context.fetch(descriptor)) ?? []
        messages = local.map {
            PeerMessage(id: $0.id, senderId: $0.senderId, senderName: $0.senderName,
                        text: $0.text, imageData: $0.imageData, timestamp: $0.timestamp,
                        type: $0.imageData != nil ? .image : .text)
        }
    }
}
