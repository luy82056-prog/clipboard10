import Foundation
import ServiceManagement

final class SettingsService: ObservableObject {
    static let shared = SettingsService()

    private let userDefaults = UserDefaults.standard

    @Published var launchAtLogin: Bool {
        didSet {
            userDefaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            updateLaunchAtLogin()
        }
    }

    @Published var showCopyAll: Bool {
        didSet { userDefaults.set(showCopyAll, forKey: Keys.showCopyAll) }
    }

    @Published var showDedup: Bool {
        didSet { userDefaults.set(showDedup, forKey: Keys.showDedup) }
    }

    @Published var showTrim: Bool {
        didSet { userDefaults.set(showTrim, forKey: Keys.showTrim) }
    }

    @Published var showClear: Bool {
        didSet { userDefaults.set(showClear, forKey: Keys.showClear) }
    }

    @Published var showCopyOne: Bool {
        didSet { userDefaults.set(showCopyOne, forKey: Keys.showCopyOne) }
    }

    private struct Keys {
        static let launchAtLogin = "launchAtLogin"
        static let showCopyAll = "showCopyAll"
        static let showDedup = "showDedup"
        static let showTrim = "showTrim"
        static let showClear = "showClear"
        static let showCopyOne = "showCopyOne"
    }

    private init() {
        let defaults: [String: Any] = [
            Keys.launchAtLogin: false,
            Keys.showCopyAll: true,
            Keys.showDedup: true,
            Keys.showTrim: true,
            Keys.showClear: true,
            Keys.showCopyOne: true
        ]
        userDefaults.register(defaults: defaults)

        launchAtLogin = userDefaults.bool(forKey: Keys.launchAtLogin)
        showCopyAll = userDefaults.object(forKey: Keys.showCopyAll) as? Bool ?? true
        showDedup = userDefaults.object(forKey: Keys.showDedup) as? Bool ?? true
        showTrim = userDefaults.object(forKey: Keys.showTrim) as? Bool ?? true
        showClear = userDefaults.object(forKey: Keys.showClear) as? Bool ?? true
        showCopyOne = userDefaults.object(forKey: Keys.showCopyOne) as? Bool ?? true
    }

    private func updateLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update launch at login: \(error)")
            }
        }
    }
}
