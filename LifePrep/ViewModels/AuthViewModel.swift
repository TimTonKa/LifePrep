import FirebaseAuth
import Combine

final class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isDeletingAccount: Bool = false
    @Published var deleteAccountError: String?

    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isLoggedIn = user != nil
            }
        }
    }

    deinit {
        if let handle { Auth.auth().removeStateDidChangeListener(handle) }
    }

    var displayName: String {
        currentUser?.displayName ?? currentUser?.email?.components(separatedBy: "@").first ?? "使用者"
    }

    var userId: String { currentUser?.uid ?? "" }

    func register(email: String, password: String, name: String) {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let result = try await Auth.auth().createUser(withEmail: email, password: password)
                let changeRequest = result.user.createProfileChangeRequest()
                changeRequest.displayName = name
                try await changeRequest.commitChanges()
                await MainActor.run { self.isLoading = false }
            } catch {
                await MainActor.run {
                    self.errorMessage = localizedAuthError(error)
                    self.isLoading = false
                }
            }
        }
    }

    func login(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await Auth.auth().signIn(withEmail: email, password: password)
                await MainActor.run { self.isLoading = false }
            } catch {
                await MainActor.run {
                    self.errorMessage = localizedAuthError(error)
                    self.isLoading = false
                }
            }
        }
    }

    func logout() {
        try? Auth.auth().signOut()
    }

    func deleteAccount() {
        guard let user = Auth.auth().currentUser else { return }
        isDeletingAccount = true
        deleteAccountError = nil
        Task {
            do {
                try await FirebaseChatService.shared.deleteUserData(userId: user.uid)
                try await user.delete()
                await MainActor.run {
                    self.currentUser = nil
                    self.isLoggedIn = false
                    self.isDeletingAccount = false
                }
            } catch let error as NSError {
                let msg: String
                if AuthErrorCode(rawValue: error.code) == .requiresRecentLogin {
                    msg = "為了安全，請先登出後重新登入，再執行刪除帳號"
                } else {
                    msg = "刪除帳號失敗，請稍後再試"
                }
                await MainActor.run {
                    self.deleteAccountError = msg
                    self.isDeletingAccount = false
                }
            }
        }
    }

    private func localizedAuthError(_ error: Error) -> String {
        let code = (error as NSError).code
        switch AuthErrorCode(rawValue: code) {
        case .invalidEmail:       return "電子郵件格式不正確"
        case .weakPassword:       return "密碼至少需要 6 個字元"
        case .emailAlreadyInUse:  return "此電子郵件已被使用"
        case .userNotFound:       return "找不到此帳號"
        case .wrongPassword:      return "密碼錯誤"
        case .invalidCredential:  return "電子郵件或密碼錯誤"
        case .networkError:       return "網路連線錯誤，請稍後再試"
        case .tooManyRequests:    return "嘗試次數過多，請稍後再試"
        case .userDisabled:       return "此帳號已被停用"
        default:                  return error.localizedDescription
        }
    }
}
