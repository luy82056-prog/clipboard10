import Foundation

final class StorageService {
    static let shared = StorageService()

    private let userDefaults = UserDefaults.standard
    private let storageKey = "Clipboard10Items"

    private init() {}

    func save(items: [ClipboardItem]) {
        do {
            let data = try JSONEncoder().encode(items)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            print("Failed to save clipboard items: \(error)")
        }
    }

    func load() -> [ClipboardItem] {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return []
        }
        do {
            return try JSONDecoder().decode([ClipboardItem].self, from: data)
        } catch {
            print("Failed to load clipboard items: \(error)")
            return []
        }
    }

    func clear() {
        userDefaults.removeObject(forKey: storageKey)
    }
}
