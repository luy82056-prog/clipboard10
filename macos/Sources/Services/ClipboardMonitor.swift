import AppKit
import Combine

final class ClipboardMonitor: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []

    private var lastChangeCount: Int = 0
    private var timer: Timer?
    private let maxItems = 10
    private let maxContentCharacters = 200_000
    private let storage = StorageService.shared
    private let favorites = FavoritesService.shared

    var isMonitoring: Bool {
        timer != nil
    }

    init() {
        items = storage.load()
        lastChangeCount = NSPasteboard.general.changeCount
    }

    func startMonitoring() {
        guard timer == nil else { return }
        timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        let currentCount = pasteboard.changeCount

        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        guard let content = pasteboard.string(forType: .string), !content.isEmpty else { return }
        guard content.count <= maxContentCharacters else { return }
        guard items.first?.content != content else { return }

        let newItem = ClipboardItem(content: content)

        DispatchQueue.main.async { [weak self] in
            self?.addItem(newItem)
        }
    }

    private func addItem(_ item: ClipboardItem) {
        if let existingIndex = items.firstIndex(where: { $0.content == item.content }) {
            items.remove(at: existingIndex)
        }

        items.insert(item, at: 0)

        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }

        storage.save(items: items)
    }

    func removeItem(at index: Int) {
        guard index >= 0 && index < items.count else { return }
        items.remove(at: index)
        storage.save(items: items)
    }

    func dedupe() {
        var seen = Set<String>()
        items = items.filter { item in
            if seen.contains(item.content) {
                return false
            }
            seen.insert(item.content)
            return true
        }
        storage.save(items: items)
    }

    func trimWhitespace() {
        items = items.map { item in
            var copy = item
            copy.content = item.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return copy
        }
        items = items.filter { !$0.content.isEmpty }
        storage.save(items: items)
    }

    func clearAll() {
        items.removeAll()
        storage.clear()
    }

    func copyAll() -> String {
        items.map { $0.content }.joined(separator: "\n\n")
    }

    func addToFavorites(_ item: ClipboardItem) {
        favorites.add(item)
    }

    func removeFromFavorites(_ id: UUID) {
        favorites.remove(id: id)
    }

    func getFavorites() -> [ClipboardItem] {
        favorites.items
    }

    func isFavorite(_ item: ClipboardItem) -> Bool {
        favorites.contains(content: item.content)
    }
}
