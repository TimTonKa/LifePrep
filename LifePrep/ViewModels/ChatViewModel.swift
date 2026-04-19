import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var rooms: [ChatRoom] = []
    @Published var messages: [FirebaseMessage] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var roomsListener: ListenerRegistration?
    private var messagesListener: ListenerRegistration?
    private let service = FirebaseChatService.shared

    var currentUserId: String { Auth.auth().currentUser?.uid ?? "" }
    var currentUserName: String {
        Auth.auth().currentUser?.displayName ?? Auth.auth().currentUser?.email ?? "使用者"
    }

    func startObservingRooms() {
        roomsListener?.remove()
        roomsListener = service.observeRooms(userId: currentUserId) { [weak self] rooms in
            self?.rooms = rooms
        }
    }

    func stopObservingRooms() {
        roomsListener?.remove()
        roomsListener = nil
    }

    func startObservingMessages(roomId: String) {
        messagesListener?.remove()
        messagesListener = service.observeMessages(roomId: roomId) { [weak self] messages in
            self?.messages = messages
        }
    }

    func stopObservingMessages() {
        messagesListener?.remove()
        messagesListener = nil
        messages = []
    }

    func sendMessage(roomId: String, text: String) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        Task {
            do {
                try await service.sendMessage(roomId: roomId, text: text,
                                              senderId: currentUserId, senderName: currentUserName)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func sendImage(roomId: String, imageData: Data) {
        Task {
            do {
                try await service.sendImage(roomId: roomId, imageData: imageData,
                                            senderId: currentUserId, senderName: currentUserName)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func createDirectRoom(withUserId: String, withUserName: String) {
        Task {
            do {
                let room = try await service.createRoom(
                    name: withUserName,
                    memberIds: [currentUserId, withUserId],
                    memberNames: [currentUserId: currentUserName, withUserId: withUserName],
                    isGroup: false
                )
                self.rooms.insert(room, at: 0)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func createGroupRoom(name: String, memberIds: [String], memberNames: [String: String]) {
        Task {
            do {
                var allIds = memberIds
                var allNames = memberNames
                allIds.append(currentUserId)
                allNames[currentUserId] = currentUserName
                let room = try await service.createRoom(
                    name: name,
                    memberIds: allIds,
                    memberNames: allNames,
                    isGroup: true
                )
                self.rooms.insert(room, at: 0)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
