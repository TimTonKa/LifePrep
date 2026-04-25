import SwiftUI
import SwiftData
import FirebaseCore

@main
struct LifePrepApp: App {
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var networkMonitor = NetworkMonitor()

    init() {
        FirebaseApp.configure()
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([GuideCategory.self, GuideItem.self, LocalMessage.self, Shelter.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ZStack {
                if authVM.isCheckingAuth {
                    SplashView()
                        .transition(.opacity)
                } else if authVM.isLoggedIn {
                    ContentViewWrapper()
                        .transition(.opacity)
                } else {
                    AuthView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: authVM.isCheckingAuth)
            .animation(.easeInOut(duration: 0.4), value: authVM.isLoggedIn)
            .environmentObject(authVM)
            .environmentObject(networkMonitor)
        }
        .modelContainer(sharedModelContainer)
    }
}

struct ContentViewWrapper: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var networkMonitor: NetworkMonitor

    @StateObject private var guideVM: GuideViewModel
    @StateObject private var chatVM = ChatViewModel()
    @StateObject private var btVM: BluetoothViewModel
    @StateObject private var callVM = VoiceCallViewModel()

    init() {
        // Temporary containers — replaced by environment's container after init
        let tmpContainer = try! ModelContainer(for: GuideCategory.self, GuideItem.self, LocalMessage.self, Shelter.self)
        _guideVM = StateObject(wrappedValue: GuideViewModel(context: tmpContainer.mainContext))
        _btVM = StateObject(wrappedValue: BluetoothViewModel(
            displayName: UIDevice.current.name,
            context: tmpContainer.mainContext
        ))
    }

    var body: some View {
        InnerContentView(guideVM: guideVM, chatVM: chatVM, btVM: btVM, callVM: callVM)
            .onAppear {
                // Switch from the temporary init-time context to the shared app-lifetime context
                guideVM.context = modelContext
                btVM.context = modelContext
                guideVM.seedIfNeeded()
                guideVM.fetchUpdateIfStale() // 背景靜默更新，超過 24 小時才觸發
            }
    }
}

struct InnerContentView: View {
    @ObservedObject var guideVM: GuideViewModel
    @ObservedObject var chatVM: ChatViewModel
    @ObservedObject var btVM: BluetoothViewModel
    @ObservedObject var callVM: VoiceCallViewModel
    @EnvironmentObject var networkMonitor: NetworkMonitor

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            GuideHomeView()
                .environmentObject(guideVM)
                .tabItem { Label("生存指南", systemImage: "book.fill") }
                .tag(0)

            ChatListView()
                .environmentObject(chatVM)
                .environmentObject(callVM)
                .tabItem { Label("線上通訊", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(1)

            BluetoothChatView()
                .environmentObject(btVM)
                .tabItem { Label("藍牙通訊", systemImage: "antenna.radiowaves.left.and.right") }
                .tag(2)

            SettingsView()
                .environmentObject(guideVM)
                .tabItem { Label("設定", systemImage: "gearshape.fill") }
                .tag(3)
        }
        .tint(.green)
        .overlay(alignment: .top) {
            if !networkMonitor.isConnected {
                HStack(spacing: 6) {
                    Image(systemName: "wifi.slash")
                    Text("無網路 — 藍牙通訊仍可使用")
                        .font(.caption.bold())
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(Color.orange.opacity(0.9))
                .clipShape(Capsule())
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: networkMonitor.isConnected)
            }
        }
    }
}
