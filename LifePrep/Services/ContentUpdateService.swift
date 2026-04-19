import Foundation
import SwiftData

final class ContentUpdateService {
    // Update this URL to point to your GitHub raw JSON file
    static let remoteURL = URL(string: "https://raw.githubusercontent.com/TimTonKa/LifePrep/main/content/survival_guide.json")!

    static func loadSeedData() -> SurvivalGuideJSON? {
        guard let url = Bundle.main.url(forResource: "survival_guide", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SurvivalGuideJSON.self, from: data)
    }

    static func fetchRemoteUpdate() async throws -> SurvivalGuideJSON {
        let (data, _) = try await URLSession.shared.data(from: remoteURL)
        return try JSONDecoder().decode(SurvivalGuideJSON.self, from: data)
    }

    @MainActor
    static func applyUpdate(_ guide: SurvivalGuideJSON, context: ModelContext) {
        for catJSON in guide.categories {
            let categoryId = catJSON.id
            let descriptor = FetchDescriptor<GuideCategory>(
                predicate: #Predicate { $0.id == categoryId }
            )
            let existing = try? context.fetch(descriptor)
            let category: GuideCategory

            if let found = existing?.first {
                found.titleZH = catJSON.titleZH
                found.icon = catJSON.icon
                found.colorHex = catJSON.colorHex
                found.sortOrder = catJSON.sortOrder
                found.updatedAt = Date()
                category = found
            } else {
                category = GuideCategory(
                    id: catJSON.id,
                    titleZH: catJSON.titleZH,
                    icon: catJSON.icon,
                    colorHex: catJSON.colorHex,
                    sortOrder: catJSON.sortOrder
                )
                context.insert(category)
            }

            for itemJSON in catJSON.items {
                let itemId = itemJSON.id
                let itemDescriptor = FetchDescriptor<GuideItem>(
                    predicate: #Predicate { $0.id == itemId }
                )
                let existingItems = try? context.fetch(itemDescriptor)

                if let found = existingItems?.first {
                    found.titleZH = itemJSON.titleZH
                    found.summary = itemJSON.summary
                    found.content = itemJSON.content
                    found.tags = itemJSON.tags
                    found.priority = itemJSON.priority
                    found.sortOrder = itemJSON.sortOrder
                    found.updatedAt = Date()
                } else {
                    let item = GuideItem(
                        id: itemJSON.id,
                        titleZH: itemJSON.titleZH,
                        summary: itemJSON.summary,
                        content: itemJSON.content,
                        tags: itemJSON.tags,
                        priority: itemJSON.priority,
                        sortOrder: itemJSON.sortOrder
                    )
                    item.category = category
                    context.insert(item)
                    category.items.append(item)
                }
            }
        }

        try? context.save()
    }
}
