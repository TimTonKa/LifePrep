import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import Combine

final class FirebaseChatService {
    static let shared = FirebaseChatService()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    // MARK: - Rooms

    func createRoom(name: String, memberIds: [String], memberNames: [String: String], isGroup: Bool) async throws -> ChatRoom {
        let currentUser = Auth.auth().currentUser
        let room = ChatRoom(
            id: UUID().uuidString,
            name: name,
            memberIds: memberIds,
            memberNames: memberNames,
            lastMessage: "",
            lastMessageTime: Date(),
            isGroup: isGroup,
            createdBy: currentUser?.uid ?? ""
        )
        try await db.collection("chatRooms").document(room.id).setData(room.asDictionary())
        return room
    }

    func fetchRooms(userId: String) async throws -> [ChatRoom] {
        let snapshot = try await db.collection("chatRooms")
            .whereField("memberIds", arrayContains: userId)
            .order(by: "lastMessageTime", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { ChatRoom(from: $0.data()) }
    }

    func observeRooms(userId: String, onUpdate: @escaping ([ChatRoom]) -> Void) -> ListenerRegistration {
        db.collection("chatRooms")
            .whereField("memberIds", arrayContains: userId)
            .order(by: "lastMessageTime", descending: true)
            .addSnapshotListener { snapshot, _ in
                let rooms = snapshot?.documents.compactMap { ChatRoom(from: $0.data()) } ?? []
                onUpdate(rooms)
            }
    }

    // MARK: - Messages

    func sendMessage(roomId: String, text: String, senderId: String, senderName: String) async throws {
        let message = FirebaseMessage(
            id: UUID().uuidString,
            roomId: roomId,
            senderId: senderId,
            senderName: senderName,
            text: text,
            imageURL: nil,
            timestamp: Date(),
            messageType: .text
        )
        try await db.collection("chatRooms").document(roomId)
            .collection("messages").document(message.id)
            .setData(message.asDictionary())

        try await db.collection("chatRooms").document(roomId).updateData([
            "lastMessage": text,
            "lastMessageTime": Timestamp(date: Date())
        ])
    }

    func sendImage(roomId: String, imageData: Data, senderId: String, senderName: String) async throws {
        let imageId = UUID().uuidString
        let ref = storage.reference().child("chat_images/\(roomId)/\(imageId).jpg")
        _ = try await ref.putDataAsync(imageData)
        let url = try await ref.downloadURL()

        let message = FirebaseMessage(
            id: imageId,
            roomId: roomId,
            senderId: senderId,
            senderName: senderName,
            text: "📷 圖片",
            imageURL: url.absoluteString,
            timestamp: Date(),
            messageType: .image
        )
        try await db.collection("chatRooms").document(roomId)
            .collection("messages").document(message.id)
            .setData(message.asDictionary())
    }

    func observeMessages(roomId: String, onUpdate: @escaping ([FirebaseMessage]) -> Void) -> ListenerRegistration {
        db.collection("chatRooms").document(roomId).collection("messages")
            .order(by: "timestamp", descending: false)
            .limit(toLast: 100)
            .addSnapshotListener { snapshot, _ in
                let messages = snapshot?.documents.compactMap { FirebaseMessage(from: $0.data()) } ?? []
                onUpdate(messages)
            }
    }

    // MARK: - Account Deletion

    func deleteUserData(userId: String) async throws {
        let roomsSnapshot = try await db.collection("chatRooms")
            .whereField("memberIds", arrayContains: userId)
            .getDocuments()

        for doc in roomsSnapshot.documents {
            var memberIds = doc.data()["memberIds"] as? [String] ?? []
            var memberNames = doc.data()["memberNames"] as? [String: String] ?? [:]
            memberIds.removeAll { $0 == userId }
            memberNames.removeValue(forKey: userId)

            if memberIds.isEmpty {
                let msgs = try await doc.reference.collection("messages").getDocuments()
                for msg in msgs.documents { try await msg.reference.delete() }
                try await doc.reference.delete()
            } else {
                try await doc.reference.updateData([
                    "memberIds": memberIds,
                    "memberNames": memberNames
                ])
            }
        }

        let callsSnapshot = try await db.collection("calls")
            .whereField("callerId", isEqualTo: userId)
            .getDocuments()
        for callDoc in callsSnapshot.documents {
            try await callDoc.reference.delete()
        }
    }
}

// MARK: - Firestore serialization helpers

extension ChatRoom {
    func asDictionary() -> [String: Any] {
        [
            "id": id,
            "name": name,
            "memberIds": memberIds,
            "memberNames": memberNames,
            "lastMessage": lastMessage,
            "lastMessageTime": Timestamp(date: lastMessageTime),
            "isGroup": isGroup,
            "createdBy": createdBy
        ]
    }

    init?(from dict: [String: Any]) {
        guard let id = dict["id"] as? String,
              let name = dict["name"] as? String,
              let memberIds = dict["memberIds"] as? [String],
              let memberNames = dict["memberNames"] as? [String: String],
              let isGroup = dict["isGroup"] as? Bool,
              let createdBy = dict["createdBy"] as? String else { return nil }
        let lastMessage = dict["lastMessage"] as? String ?? ""
        let ts = dict["lastMessageTime"] as? Timestamp
        self.init(id: id, name: name, memberIds: memberIds, memberNames: memberNames,
                  lastMessage: lastMessage, lastMessageTime: ts?.dateValue() ?? Date(),
                  isGroup: isGroup, createdBy: createdBy)
    }
}

extension FirebaseMessage {
    func asDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "roomId": roomId,
            "senderId": senderId,
            "senderName": senderName,
            "text": text,
            "timestamp": Timestamp(date: timestamp),
            "messageType": messageType.rawValue
        ]
        if let imageURL { dict["imageURL"] = imageURL }
        return dict
    }

    init?(from dict: [String: Any]) {
        guard let id = dict["id"] as? String,
              let roomId = dict["roomId"] as? String,
              let senderId = dict["senderId"] as? String,
              let senderName = dict["senderName"] as? String,
              let text = dict["text"] as? String,
              let ts = dict["timestamp"] as? Timestamp,
              let typeRaw = dict["messageType"] as? String,
              let type = FirebaseMessageType(rawValue: typeRaw) else { return nil }
        self.init(id: id, roomId: roomId, senderId: senderId, senderName: senderName,
                  text: text, imageURL: dict["imageURL"] as? String,
                  timestamp: ts.dateValue(), messageType: type)
    }
}
