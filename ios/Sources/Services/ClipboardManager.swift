import UIKit

struct ClipboardItem: Codable, Identifiable {
    let id: UUID
    var content: String
    let timestamp: Date

    init(content: String) {
        self.id = UUID()
        self.content = content
        self.timestamp = Date()
    }
}

class ClipboardManager {
    static let shared = ClipboardManager()
    private let maxItems = 10
    private let userDefaults = UserDefaults.standard
    private let storageKey = "Clipboard10Items"

    private(set) var items: [ClipboardItem] = []

    private init() {
        load()
        startMonitoring()
    }

    private func load() {
        guard let data = userDefaults.data(forKey: storageKey) else { return }
        items = (try? JSONDecoder().decode([ClipboardItem].self, from: data)) ?? []
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            userDefaults.set(data, forKey: storageKey)
        }
    }

    private func startMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    private func checkClipboard() {
        guard let content = UIPasteboard.general.string, !content.isEmpty else { return }
        let newItem = ClipboardItem(content: content)

        if let existingIndex = items.firstIndex(where: { $0.content == content }) {
            items.remove(at: existingIndex)
        }

        items.insert(newItem, at: 0)
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
        save()

        NotificationCenter.default.post(name: .clipboardUpdated, object: nil)
    }

    func copyItem(_ item: ClipboardItem) {
        UIPasteboard.general.string = item.content
    }

    func copyAll() -> String {
        items.map { $0.content }.joined(separator: "\n\n")
    }

    func deleteItem(at index: Int) {
        guard index >= 0 && index < items.count else { return }
        items.remove(at: index)
        save()
    }

    func dedupe() {
        var seen = Set<String>()
        items = items.filter { item in
            if seen.contains(item.content) { return false }
            seen.insert(item.content)
            return true
        }
        save()
    }

    func trimWhitespace() {
        items = items.map {
            var copy = $0
            copy.content = $0.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return copy
        }.filter { !$0.content.isEmpty }
        save()
    }

    func clearAll() {
        items.removeAll()
        save()
    }
}

extension Notification.Name {
    static let clipboardUpdated = Notification.Name("clipboardUpdated")
}