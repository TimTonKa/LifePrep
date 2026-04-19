import SwiftData
import Foundation

// MARK: - SwiftData model for offline (Bluetooth) messages

@Model
final class LocalMessage {
    @Attribute(.unique) var id: String
    var roomId: String
    var senderId: String
    var senderName: String
    var text: String
    var imageData: Data?
    var timestamp: Date
    var isDelivered: Bool
    var source: MessageSource

    init(id: String = UUID().uuidString, roomId: String, senderId: String, senderName: String,
         text: String, imageData: Data? = nil, timestamp: Date = Date(),
         isDelivered: Bool = false, source: MessageSource = .bluetooth) {
        self.id = id
        self.roomId = roomId
        self.senderId = senderId
        self.senderName = senderName
        self.text = text
        self.imageData = imageData
        self.timestamp = timestamp
        self.isDelivered = isDelivered
        self.source = source
    }
}

enum MessageSource: String, Codable {
    case bluetooth
    case firebase
}

// MARK: - In-memory model for Firebase messages

struct FirebaseMessage: Identifiable, Codable, Equatable {
    var id: String
    var roomId: String
    var senderId: String
    var senderName: String
    var text: String
    var imageURL: String?
    var timestamp: Date
    var messageType: FirebaseMessageType

    enum FirebaseMessageType: String, Codable {
        case text
        case image
        case callStarted
        case callEnded
    }
}

struct ChatRoom: Identifiable, Codable {
    var id: String
    var name: String
    var memberIds: [String]
    var memberNames: [String: String]
    var lastMessage: String
    var lastMessageTime: Date
    var isGroup: Bool
    var createdBy: String
}

// MARK: - Bluetooth peer message (sent over MultipeerConnectivity)

struct PeerMessage: Codable {
    var id: String
    var senderId: String
    var senderName: String
    var text: String
    var imageData: Data?
    var timestamp: Date
    var type: PeerMessageType

    enum PeerMessageType: String, Codable {
        case text
        case image
        case voiceStart
        case voiceStop
        case voiceAudio
    }
}
