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

    var body: some View {
        List {
            ForEach(sortedItems) { item in
                if item.tags.contains("feature:shelter-map") {
                    NavigationLink(destination: ShelterMapView(context: modelContext)) {
                        ItemRowView(item: item)
                    }
                } else {
                    NavigationLink(destination: ItemDetailView(item: item)) {
                        ItemRowView(item: item)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(category.titleZH)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "搜尋")
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
