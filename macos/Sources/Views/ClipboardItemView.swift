import SwiftUI

struct ClipboardItemView: View {
    let index: Int
    let item: ClipboardItem
    var isFavorited: Bool = false
    let onCopy: () -> Void
    let onDelete: () -> Void
    var onAddFavorite: (() -> Void)? = nil

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            Text("\(index + 1)")
                .font(.caption)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.orange.opacity(0.8))
                .cornerRadius(4)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.preview)
                    .font(.system(size: 12))
                    .lineLimit(item.isMultiline ? 2 : 1)
                    .foregroundColor(.primary)

                if item.isMultiline {
                    Text("多行文本")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if isHovered {
                HStack(spacing: 4) {
                    if let onAddFavorite = onAddFavorite, !isFavorited {
                        Button(action: onAddFavorite) {
                            Image(systemName: "star")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        .buttonStyle(.plain)
                        .help("添加到常用")
                    }

                    Button(action: onCopy) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .help("复制")

                    Button(action: onDelete) {
                        Image(systemName: "xmark")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                    .help("删除")
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isHovered ? Color.orange.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .onHover { hovering in
            isHovered = hovering
        }
        .help(item.content)
    }
}