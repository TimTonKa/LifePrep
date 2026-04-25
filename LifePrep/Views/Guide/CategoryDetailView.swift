import SwiftUI

struct CategoryDetailView: View {
    let category: GuideCategory
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""

    var sortedItems: [GuideItem] {
        let items = category.items.sorted { $0.sortOrder < $1.sortOrder }
        guard !searchText.isEmpty else { return items }
        return items.filter { $0.titleZH.localizedCaseInsensitiveContains(searchText) }
    }

    // 判斷是否為「緊急撤離」類別（支援名稱異動的情況）
    private var isEvacuationCategory: Bool {
        category.titleZH.contains("撤離") || category.titleZH.contains("疏散") || category.id.lowercased().contains("evacu")
    }

    var body: some View {
        List {
            ForEach(sortedItems) { item in
                NavigationLink(destination: ItemDetailView(item: item)) {
                    ItemRowView(item: item)
                }
            }
            if isEvacuationCategory && searchText.isEmpty {
                NavigationLink(destination: ShelterMapView(context: modelContext)) {
                    ShelterMapRowView()
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(category.titleZH)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "搜尋")
    }
}

struct ShelterMapRowView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("附近避難所地圖")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Circle().fill(.green).frame(width: 8, height: 8)
            }
            Text("顯示目前位置 5 公里內的緊急避難所，支援導航功能")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            HStack(spacing: 4) {
                Image(systemName: "map.fill").font(.caption2)
                Text("內政部消防署資料").font(.caption2)
            }
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

struct ItemRowView: View {
    let item: GuideItem

    var priorityColor: Color {
        switch item.priority {
        case 5: return .red
        case 4: return .orange
        case 3: return .yellow
        default: return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.titleZH)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Circle()
                    .fill(priorityColor)
                    .frame(width: 8, height: 8)
            }
            Text(item.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            if !item.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(item.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.green.opacity(0.15))
                                .foregroundStyle(Color.green)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
