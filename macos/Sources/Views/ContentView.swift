import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: ClipboardViewModel
    @State private var showingClearConfirm = false
    @State private var showingSettings = false

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            favoritesSection
            Divider()
            scrollView
            Divider()
            actionButtonsView
        }
        .frame(width: 320, height: 440)
        .background(Color(hex: "FFF8E7"))
        .sheet(isPresented: $showingSettings) {
            SettingsView(settings: viewModel.settingsService)
        }
        .alert("确认清除", isPresented: $showingClearConfirm) {
            Button("取消", role: .cancel) {}
            Button("确认清除", role: .destructive) {
                viewModel.clearAll()
            }
        } message: {
            Text("确定要清空全部剪贴板历史吗？")
        }
        .onAppear {
            viewModel.refreshFavorites()
        }
    }

    private var headerView: some View {
        HStack {
            Image(systemName: "doc.on.clipboard.fill")
                .foregroundColor(.orange)
            Text("Clipboard10")
                .font(.headline)
            Spacer()
            Text("⌘⇧V")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(4)
            Button(action: { showingSettings = true }) {
                Image(systemName: "gear")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("设置")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "FFF8E7"))
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                Text("常用")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(viewModel.favorites.count)/7")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            if viewModel.favorites.isEmpty {
                Text("长按项目添加常用")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.favorites) { item in
                            FavoriteItemView(
                                item: item,
                                onCopy: { viewModel.copyItem(item) },
                                onDelete: { viewModel.removeFromFavorites(item.id) }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .padding(.bottom, 10)
        .background(Color(hex: "FFF8E7"))
    }

    private var scrollView: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                if viewModel.items.isEmpty {
                    emptyStateView
                } else {
                    ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                        ClipboardItemView(
                            index: index,
                            item: item,
                            isFavorited: viewModel.isFavorite(item),
                            onCopy: { viewModel.copyItem(item) },
                            onDelete: { viewModel.deleteItem(at: IndexSet(integer: index)) },
                            onAddFavorite: { viewModel.addToFavorites(item) }
                        )
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(maxHeight: 200)
        .background(Color(hex: "FFF8E7"))
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "clipboard")
                .font(.system(size: 32))
                .foregroundColor(.gray.opacity(0.5))
            Text("暂无剪贴板记录")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var actionButtonsView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                if viewModel.settingsService.showCopyOne {
                    Button(action: { viewModel.isCopyAllMode.toggle() }) {
                        HStack {
                            Image(systemName: viewModel.isCopyAllMode ? "checkmark.circle.fill" : "circle")
                            Text("逐条复制")
                        }
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                if viewModel.settingsService.showCopyAll {
                    Button(action: { viewModel.copyAll() }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("复制全部")
                        }
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            HStack(spacing: 8) {
                if viewModel.settingsService.showDedup {
                    Button(action: { viewModel.dedupe() }) {
                        HStack {
                            Image(systemName: "square.on.square.dashed")
                            Text("去重")
                        }
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                if viewModel.settingsService.showTrim {
                    Button(action: { viewModel.trimWhitespace() }) {
                        HStack {
                            Image(systemName: "text.alignleft")
                            Text("去空白")
                        }
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                if viewModel.settingsService.showClear {
                    Button(action: { showingClearConfirm = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("清空")
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(hex: "FFF8E7"))
    }
}

struct FavoriteItemView: View {
    let item: ClipboardItem
    let onCopy: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.orange)
                    .font(.caption2)
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.caption2)
                }
                .buttonStyle(.plain)
            }
            Text(item.preview)
                .font(.caption2)
                .foregroundColor(.primary)
                .lineLimit(2)
                .frame(width: 80, height: 32, alignment: .topLeading)
        }
        .padding(8)
        .frame(width: 100, height: 60)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onTapGesture {
            onCopy()
        }
    }
}