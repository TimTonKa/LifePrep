import SwiftData
import Combine
import Foundation

@MainActor
final class GuideViewModel: ObservableObject {
    @Published var isUpdating: Bool = false
    @Published var lastUpdated: Date?
    @Published var updateError: String?
    @Published var updateMessage: String?

    var context: ModelContext

    init(context: ModelContext) {
        self.context = context
        lastUpdated = UserDefaults.standard.object(forKey: "guideLastUpdated") as? Date
    }

    func seedIfNeeded() {
        let descriptor = FetchDescriptor<GuideCategory>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        if let guide = ContentUpdateService.loadSeedData() {
            ContentUpdateService.applyUpdate(guide, context: context)
            let now = Date()
            UserDefaults.standard.set(now, forKey: "guideLastUpdated")
            lastUpdated = now
        }
    }

    /// 啟動時靜默更新：上次更新超過 24 小時才觸發，不顯示錯誤訊息
    func fetchUpdateIfStale() {
        let oneDayAgo = Date().addingTimeInterval(-86400)
        let isStale = lastUpdated.map { $0 < oneDayAgo } ?? true
        guard isStale else { return }
        Task {
            guard let guide = try? await ContentUpdateService.fetchRemoteUpdate() else { return }
            ContentUpdateService.applyUpdate(guide, context: context)
            let now = Date()
            UserDefaults.standard.set(now, forKey: "guideLastUpdated")
            self.lastUpdated = now
        }
    }

    func fetchUpdate() {
        guard !isUpdating else { return }
        isUpdating = true
        updateError = nil
        updateMessage = nil

        Task {
            do {
                let guide = try await ContentUpdateService.fetchRemoteUpdate()
                ContentUpdateService.applyUpdate(guide, context: context)
                let now = Date()
                UserDefaults.standard.set(now, forKey: "guideLastUpdated")
                self.lastUpdated = now
                self.updateMessage = "已更新至最新版本（\(guide.version)）"
            } catch {
                self.updateError = "更新失敗：\(error.localizedDescription)"
            }
            self.isUpdating = false
        }
    }

    func categories() -> [GuideCategory] {
        let descriptor = FetchDescriptor<GuideCategory>(
            sortBy: [SortDescriptor(\GuideCategory.sortOrder)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
