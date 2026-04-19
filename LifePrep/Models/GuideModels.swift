import SwiftData
import Foundation

@Model
final class GuideCategory {
    @Attribute(.unique) var id: String
    var titleZH: String
    var icon: String
    var colorHex: String
    var sortOrder: Int
    var updatedAt: Date
    @Relationship(deleteRule: .cascade) var items: [GuideItem] = []

    init(id: String, titleZH: String, icon: String, colorHex: String, sortOrder: Int) {
        self.id = id
        self.titleZH = titleZH
        self.icon = icon
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.updatedAt = Date()
    }
}

@Model
final class GuideItem {
    @Attribute(.unique) var id: String
    var titleZH: String
    var summary: String
    var content: String
    var tags: [String]
    var priority: Int
    var sortOrder: Int
    var updatedAt: Date
    var category: GuideCategory?

    init(id: String, titleZH: String, summary: String, content: String,
         tags: [String] = [], priority: Int = 3, sortOrder: Int = 0) {
        self.id = id
        self.titleZH = titleZH
        self.summary = summary
        self.content = content
        self.tags = tags
        self.priority = priority
        self.sortOrder = sortOrder
        self.updatedAt = Date()
    }
}

// MARK: - JSON Decodable counterparts

struct GuideCategoryJSON: Decodable {
    let id: String
    let titleZH: String
    let icon: String
    let colorHex: String
    let sortOrder: Int
    let items: [GuideItemJSON]
}

struct GuideItemJSON: Decodable {
    let id: String
    let titleZH: String
    let summary: String
    let content: String
    let tags: [String]
    let priority: Int
    let sortOrder: Int
}

struct SurvivalGuideJSON: Decodable {
    let version: String
    let updatedAt: String
    let categories: [GuideCategoryJSON]
}
