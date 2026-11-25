import AppKit
import Carbon

final class HotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var callback: (() -> Void)?

    private static var sharedInstance: HotKeyManager?

    init() {
        HotKeyManager.sharedInstance = self
    }

    func register(key: Key, modifiers: Modifiers, callback: @escaping () -> Void) {
        self.callback = callback

        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x434C5031) // "CLP1"
        hotKeyID.id = 1

        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)

        let handler: EventHandlerUPP = { _, event, userData -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.callback?()
            return noErr
        }

        InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        let keyCode = UInt32(key.rawValue)
        let modifiers = carbonModifiers(modifiers)

        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func unregisterAll() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
        callback = nil
    }

    private func carbonModifiers(_ modifiers: Modifiers) -> UInt32 {
        var result: UInt32 = 0
        if modifiers.contains(.command) {
            result |= UInt32(cmdKey)
        }
        if modifiers.contains(.shift) {
            result |= UInt32(shiftKey)
        }
        return result
    }

    enum Key: UInt32 {
        case v = 0x09
        case c = 0x08
    }

    struct Modifiers: OptionSet {
        let rawValue: UInt32

        static let command = Modifiers(rawValue: 0x0003)
        static let shift = Modifiers(rawValue: 0x0004)
    }

    deinit {
        unregisterAll()
    }
}
