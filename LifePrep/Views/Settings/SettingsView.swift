import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var guideVM: GuideViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showLogoutAlert = false
    @State private var showClearAlert = false
    @State private var showDeleteAlert = false
    @State private var showDeleteToast = false

    var body: some View {
        NavigationStack {
            List {
                profileSection
                guideSection
                communicationSection
                aboutSection
                dangerZone
            }
            .navigationTitle("設定")
            .listStyle(.insetGrouped)
            .alert("確認登出", isPresented: $showLogoutAlert) {
                Button("登出", role: .destructive) { authVM.logout() }
                Button("取消", role: .cancel) {}
            }
            .alert("清除本地資料", isPresented: $showClearAlert) {
                Button("清除", role: .destructive) { clearLocalData() }
                Button("取消", role: .cancel) {}
            } message: {
                Text("將刪除所有本地儲存的生存指南與藍牙訊息紀錄。此操作無法復原。")
            }
            .alert("刪除帳號", isPresented: $showDeleteAlert) {
                Button("永久刪除", role: .destructive) { authVM.deleteAccount() }
                Button("取消", role: .cancel) {}
            } message: {
                Text("帳號與所有雲端資料將永久刪除，此操作無法復原。\n\n你可以用相同的電子郵件重新註冊。")
            }
            .onChange(of: authVM.deleteAccountError) { _, error in
                guard error != nil else { return }
                withAnimation { showDeleteToast = true }
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    withAnimation { showDeleteToast = false }
                }
            }
            .overlay(alignment: .bottom) {
                if showDeleteToast, let msg = authVM.deleteAccountError {
                    Text(msg)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.82), in: Capsule())
                        .padding(.bottom, 36)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    private var profileSection: some View {
        Section("帳號") {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 50, height: 50)
                    Text(String(authVM.displayName.prefix(1)).uppercased())
                        .font(.title2.bold())
                        .foregroundStyle(.green)
                }
                VStack(alignment: .leading) {
                    Text(authVM.displayName)
                        .font(.headline)
                    Text(authVM.currentUser?.email ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)

            Text("我的 UID：\(authVM.userId)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            Button("登出", role: .destructive) { showLogoutAlert = true }
        }
    }

    private var guideSection: some View {
        Section("生存指南") {
            HStack {
                Label("最後更新", systemImage: "clock")
                Spacer()
                if let date = guideVM.lastUpdated {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("從未更新").foregroundStyle(.secondary).font(.caption)
                }
            }

            Button {
                guideVM.fetchUpdate()
            } label: {
                HStack {
                    Label("立即更新指南", systemImage: "arrow.clockwise")
                    Spacer()
                    if guideVM.isUpdating { ProgressView().scaleEffect(0.7) }
                }
            }
            .disabled(guideVM.isUpdating)

            if let msg = guideVM.updateMessage {
                Text(msg).font(.caption).foregroundStyle(.green)
            }
            if let err = guideVM.updateError {
                Text(err).font(.caption).foregroundStyle(.red)
            }
        }
    }

    private var communicationSection: some View {
        Section("通訊") {
            HStack {
                Label("藍牙通訊名稱", systemImage: "bluetooth")
                Spacer()
                Text(UIDevice.current.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("若要更改名稱，請在 iOS 設定 → 一般 → 關於本機 中修改裝置名稱")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var aboutSection: some View {
        Section("關於") {
            HStack {
                Label("版本", systemImage: "info.circle")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(.secondary)
            }
            Link(destination: URL(string: "https://github.com/TimTonKa/LifePrep")!) {
                Label("GitHub 原始碼", systemImage: "chevron.left.forwardslash.chevron.right")
            }
        }
    }

    private var dangerZone: some View {
        Section {
            Button("清除所有本地資料", role: .destructive) { showClearAlert = true }
            Button {
                showDeleteAlert = true
            } label: {
                HStack {
                    Text("刪除帳號")
                    Spacer()
                    if authVM.isDeletingAccount {
                        ProgressView().scaleEffect(0.8)
                    }
                }
            }
            .foregroundStyle(.red)
            .disabled(authVM.isDeletingAccount)
        } footer: {
            Text("清除本地資料後，App 重啟時將自動重新載入內建的基本資料。刪除帳號將永久移除帳號與所有雲端資料，但可以用相同 Email 重新註冊。")
        }
    }

    private func clearLocalData() {
        try? modelContext.delete(model: GuideCategory.self)
        try? modelContext.delete(model: GuideItem.self)
        try? modelContext.delete(model: LocalMessage.self)
        try? modelContext.save()
        UserDefaults.standard.removeObject(forKey: "guideLastUpdated")
        guideVM.lastUpdated = nil
    }
}
