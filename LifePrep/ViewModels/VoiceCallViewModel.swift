import FirebaseFirestore
import FirebaseAuth
import Combine

enum CallState {
    case idle, calling, ringing, connected, ended
}

@MainActor
final class VoiceCallViewModel: ObservableObject {
    @Published var callState: CallState = .idle
    @Published var callId: String?
    @Published var remoteUserName: String = ""
    @Published var callDuration: TimeInterval = 0

    private var callListener: ListenerRegistration?
    private var durationTimer: Timer?
    private let signalingService = WebRTCSignalingService.shared

    var currentUserId: String { Auth.auth().currentUser?.uid ?? "" }

    func startCall(roomId: String, remoteUserName: String) {
        self.remoteUserName = remoteUserName
        callState = .calling
        Task {
            do {
                let id = try await signalingService.createCall(roomId: roomId, callerId: currentUserId)
                self.callId = id
                self.observeCallState(callId: id)
            } catch {
                self.callState = .idle
            }
        }
    }

    func acceptCall(callId: String, remoteUserName: String) {
        self.callId = callId
        self.remoteUserName = remoteUserName
        callState = .connected
        startDurationTimer()
        observeCallState(callId: callId)
    }

    func endCall() {
        guard let callId else { return }
        Task {
            try? await signalingService.endCall(callId: callId)
        }
        callState = .ended
        cleanup()
    }

    private func observeCallState(callId: String) {
        callListener?.remove()
        callListener = signalingService.observeCall(callId: callId) { [weak self] data in
            guard let status = data["status"] as? String else { return }
            DispatchQueue.main.async {
                switch status {
                case "connected": self?.callState = .connected; self?.startDurationTimer()
                case "ended": self?.callState = .ended; self?.cleanup()
                default: break
                }
            }
        }
    }

    private func startDurationTimer() {
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.callDuration += 1
        }
    }

    private func cleanup() {
        callListener?.remove()
        callListener = nil
        durationTimer?.invalidate()
        durationTimer = nil
        callDuration = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.callState = .idle
            self.callId = nil
        }
    }

    var formattedDuration: String {
        let minutes = Int(callDuration) / 60
        let seconds = Int(callDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
