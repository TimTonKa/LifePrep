import SwiftUI

struct ItemDetailView: View {
    let item: GuideItem
    @State private var fontSize: CGFloat = 16

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack {
                        ForEach(item.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.15))
                                .foregroundStyle(.green)
                                .clipShape(Capsule())
                        }
                        Spacer()
                        PriorityBadge(priority: item.priority)
                    }
                }
                .padding(.horizontal)

                Divider()

                // Markdown content rendered as AttributedString
                MarkdownContentView(markdown: item.content, fontSize: fontSize)
                    .padding(.horizontal)

                Divider()

                Text("最後更新：\(item.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal)
                    .padding(.bottom)
            }
            .padding(.top)
        }
        .navigationTitle(item.titleZH)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { fontSize = max(12, fontSize - 2) } label: {
                    Image(systemName: "textformat.size.smaller")
                }
                Button { fontSize = min(24, fontSize + 2) } label: {
                    Image(systemName: "textformat.size.larger")
                }
            }
        }
    }
}

struct PriorityBadge: View {
    let priority: Int

    var label: String {
        switch priority {
        case 5: return "最高優先"
        case 4: return "高優先"
        case 3: return "中等"
        default: return "參考"
        }
    }

    var color: Color {
        switch priority {
        case 5: return .red
        case 4: return .orange
        case 3: return .yellow
        default: return .gray
        }
    }

    var body: some View {
        Text(label)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

struct MarkdownContentView: View {
    let markdown: String
    let fontSize: CGFloat

    var attributedString: AttributedString {
        (try? AttributedString(markdown: markdown,
                               options: AttributedString.MarkdownParsingOptions(
                                interpretedSyntax: .inlineOnlyPreservingWhitespace
                               ))) ?? AttributedString(markdown)
    }

    var body: some View {
        Text(attributedString)
            .font(.system(size: fontSize))
            .lineSpacing(4)
            .textSelection(.enabled)
    }
}
