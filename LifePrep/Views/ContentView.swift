import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @Environment(\.modelContext) private var modelContext

    @StateObject private var guideVM: GuideViewModel
    @StateObject private var chatVM = ChatViewModel()
    @StateObject private var btVM: BluetoothViewModel
    @StateObject private var callVM = VoiceCallViewModel()

    @State private var selectedTab = 0

    init() {
        // ViewModels that need modelContext are initialized in onAppear
        _guideVM = StateObject(wrappedValue: GuideViewModel(context: ModelContext(try! ModelContainer(for: GuideCategory.self, GuideItem.self, LocalMessage.self))))
        _btVM = StateObject(wrappedValue: BluetoothViewModel(displayName: UIDevice.current.name, context: ModelContext(try! ModelContainer(for: GuideCategory.self, GuideItem.self, LocalMessage.self))))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            GuideHomeView()
                .environmentObject(guideVM)
                .tabItem {
                    Label("生存指南", systemImage: "book.fill")
                }
                .tag(0)

            ChatListView()
                .environmentObject(chatVM)
                .environmentObject(callVM)
                .tabItem {
                    Label("線上通訊", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(1)
                .badge(networkMonitor.isConnected ? nil : "離線")

            BluetoothChatView()
                .environmentObject(btVM)
                .tabItem {
                    Label("藍牙通訊", systemImage: "bluetooth")
                }
                .tag(2)

            SettingsView()
                .environmentObject(authVM)
                .environmentObject(guideVM)
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(.green)
        .overlay(alignment: .top) {
            if !networkMonitor.isConnected {
                networkBanner
            }
        }
    }

    private var networkBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "wifi.slash")
            Text("無網路連線 — 藍牙通訊仍可使用")
                .font(.caption.bold())
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.9))
        .clipShape(Capsule())
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(), value: networkMonitor.isConnected)
    }
}
