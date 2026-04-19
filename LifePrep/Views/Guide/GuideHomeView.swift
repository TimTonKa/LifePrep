import SwiftUI
import SwiftData

struct GuideHomeView: View {
    @EnvironmentObject var guideVM: GuideViewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GuideCategory.sortOrder) private var categories: [GuideCategory]
    @State private var searchText = ""

    var filteredCategories: [GuideCategory] {
        guard !searchText.isEmpty else { return categories }
        return categories.filter { category in
            category.titleZH.localizedCaseInsensitiveContains(searchText) ||
            category.items.contains { $0.titleZH.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if categories.isEmpty {
                    ContentUnavailableView("載入中…", systemImage: "arrow.clockwise",
                                          description: Text("正在載入生存指南"))
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                            ForEach(filteredCategories) { category in
                                NavigationLink(destination: CategoryDetailView(category: category)) {
                                    CategoryCardView(category: category)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()

                        if let msg = guideVM.updateMessage {
                            Text(msg)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.bottom)
                        }
                    }
                    .refreshable { guideVM.fetchUpdate() }
                }
            }
            .navigationTitle("生存指南")
            .searchable(text: $searchText, prompt: "搜尋指南內容")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if guideVM.isUpdating {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Button { guideVM.fetchUpdate() } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if let date = guideVM.lastUpdated {
                        Text(date.formatted(.relative(presentation: .named)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .alert("更新失敗", isPresented: .constant(guideVM.updateError != nil)) {
                Button("確定") { guideVM.updateError = nil }
            } message: {
                Text(guideVM.updateError ?? "")
            }
        }
        .onAppear { guideVM.seedIfNeeded() }
    }
}

struct CategoryCardView: View {
    let category: GuideCategory

    var cardColor: Color {
        Color(hex: category.colorHex) ?? .green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(category.items.count)")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.8))
            }
            Spacer()
            Text(category.titleZH)
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(2)
        }
        .padding()
        .frame(height: 120)
        .background(
            LinearGradient(colors: [cardColor, cardColor.opacity(0.7)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: cardColor.opacity(0.3), radius: 6, x: 0, y: 3)
    }
}

extension Color {
    init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") { hexString.removeFirst() }
        guard hexString.count == 6, let value = UInt64(hexString, radix: 16) else { return nil }
        self.init(red: Double((value >> 16) & 0xFF) / 255,
                  green: Double((value >> 8) & 0xFF) / 255,
                  blue: Double(value & 0xFF) / 255)
    }
}
