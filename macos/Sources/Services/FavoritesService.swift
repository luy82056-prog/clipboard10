import Foundation

final class FavoritesService {
    static let shared = FavoritesService()
    private let userDefaults = UserDefaults.standard
    private let storageKey = "Clipboard10Favorites"
    private let maxFavorites = 7

    private(set) var items: [ClipboardItem] = []

    private init() {
        load()
    }

    func load() {
        guard let data = userDefaults.data(forKey: storageKey) else {
            items = []
            return
        }
        do {
            items = try JSONDecoder().decode([ClipboardItem].self, from: data)
        } catch {
            print("Failed to load favorites: \(error)")
            items = []
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(items)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            print("Failed to save favorites: \(error)")
        }
    }

    func add(_ item: ClipboardItem) {
        guard items.count < maxFavorites else { return }
        guard !items.contains(where: { $0.content == item.content }) else { return }

        var newItem = item
        newItem.isFavorite = true
        items.insert(newItem, at: 0)
        save()
    }

    func remove(id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }

    func contains(content: String) -> Bool {
        items.contains { $0.content == content }
    }

    func clear() {
        items.removeAll()
        save()
    }
}