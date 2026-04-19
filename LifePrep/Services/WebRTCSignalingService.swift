import FirebaseFirestore
import FirebaseAuth

/// WebRTC signaling via Firestore.
/// To enable actual voice/video, integrate a WebRTC library:
///   - CocoaPods: pod 'GoogleWebRTC'
///   - Or use Agora SDK: https://www.agora.io
/// This service handles only the signaling (SDP offer/answer + ICE candidates).
final class WebRTCSignalingService {
    static let shared = WebRTCSignalingService()
    private let db = Firestore.firestore()

    func createCall(roomId: String, callerId: String) async throws -> String {
        let callId = UUID().uuidString
        try await db.collection("calls").document(callId).setData([
            "roomId": roomId,
            "callerId": callerId,
            "status": "ringing",
            "createdAt": Timestamp(date: Date())
        ])
        return callId
    }

    func sendOffer(callId: String, sdp: String) async throws {
        try await db.collection("calls").document(callId).updateData([
            "offer": sdp
        ])
    }

    func sendAnswer(callId: String, sdp: String) async throws {
        try await db.collection("calls").document(callId).updateData([
            "answer": sdp,
            "status": "connected"
        ])
    }

    func addIceCandidate(callId: String, userId: String, candidate: [String: Any]) async throws {
        try await db.collection("calls").document(callId)
            .collection("iceCandidates").document(userId)
            .collection("candidates").addDocument(data: candidate)
    }

    func endCall(callId: String) async throws {
        try await db.collection("calls").document(callId).updateData([
            "status": "ended",
            "endedAt": Timestamp(date: Date())
        ])
    }

    func observeCall(callId: String, onUpdate: @escaping ([String: Any]) -> Void) -> ListenerRegistration {
        db.collection("calls").document(callId).addSnapshotListener { snapshot, _ in
            if let data = snapshot?.data() {
                onUpdate(data)
            }
        }
    }
}
