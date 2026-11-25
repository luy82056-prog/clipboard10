import SwiftUI
import Combine

final class ClipboardViewModel: ObservableObject {
    @Published var items: [ClipboardItem] = []
    @Published var favorites: [ClipboardItem] = []
    @Published var isCopyAllMode: Bool = false
    @Published var showSettings: Bool = false

    private let monitor: ClipboardMonitor
    private let settings = SettingsService.shared
    private var cancellables = Set<AnyCancellable>()

    var settingsService: SettingsService { settings }

    init(monitor: ClipboardMonitor = ClipboardMonitor()) {
        self.monitor = monitor
        setupBindings()
        if !monitor.isMonitoring {
            monitor.startMonitoring()
        }
    }

    private func setupBindings() {
        monitor.$items
            .receive(on: DispatchQueue.main)
            .assign(to: &$items)
    }

    func refreshFavorites() {
        favorites = FavoritesService.shared.items
    }

    func copyItem(_ item: ClipboardItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.content, forType: .string)
    }

    func copyAll() {
        let combined = monitor.copyAll()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(combined, forType: .string)
    }

    func deleteItem(at offsets: IndexSet) {
        for index in offsets {
            monitor.removeItem(at: index)
        }
    }

    func dedupe() {
        monitor.dedupe()
    }

    func trimWhitespace() {
        monitor.trimWhitespace()
    }

    func clearAll() {
        monitor.clearAll()
    }

    func addToFavorites(_ item: ClipboardItem) {
        monitor.addToFavorites(item)
        refreshFavorites()
    }

    func removeFromFavorites(_ id: UUID) {
        monitor.removeFromFavorites(id)
        refreshFavorites()
    }

    func isFavorite(_ item: ClipboardItem) -> Bool {
        monitor.isFavorite(item)
    }
}
