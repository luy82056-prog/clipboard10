import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var clipboardMonitor: ClipboardMonitor!
    private var hotKeyManager: HotKeyManager!
    private var eventMonitor: Any?
    private var settingsWindow: NSWindow?
    private var statusMenu: NSMenu!

    private var isLaunchingFromDock = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        let event = NSApp.currentEvent
        if event == nil {
            isLaunchingFromDock = true
        }

        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        setupClipboardMonitor()
        setupPopover()
        setupHotKey()
        setupEventMonitor()
        setupSettingsWindow()

        if isLaunchingFromDock {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showSettings()
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return true
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard10")
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.action = #selector(handleStatusItemClick(_:))
            button.target = self
        }

        statusMenu = NSMenu()
        statusMenu.addItem(
            NSMenuItem(
                title: "设置",
                action: #selector(openSettingsFromMenu),
                keyEquivalent: ","
            )
        )
        statusMenu.addItem(.separator())
        statusMenu.addItem(
            NSMenuItem(
                title: "退出 Clipboard10",
                action: #selector(quitApp),
                keyEquivalent: "q"
            )
        )
        statusMenu.items.forEach { $0.target = self }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 420)
        popover.behavior = .transient
        popover.animates = true

        let viewModel = ClipboardViewModel(monitor: clipboardMonitor)
        let contentView = ContentView(viewModel: viewModel)
        popover.contentViewController = NSHostingController(rootView: contentView)
    }

    private func setupClipboardMonitor() {
        clipboardMonitor = ClipboardMonitor()
        clipboardMonitor.startMonitoring()
    }

    private func setupHotKey() {
        hotKeyManager = HotKeyManager()
        hotKeyManager.register(key: .v, modifiers: [.command, .shift]) { [weak self] in
            self?.showPopover()
        }
    }

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if self?.popover.isShown == true {
                self?.popover.performClose(nil)
            }
        }
    }

    private func setupSettingsWindow() {
        let settingsView = SettingsView(settings: SettingsService.shared)
        let hostingController = NSHostingController(rootView: settingsView)

        settingsWindow = NSWindow(contentViewController: hostingController)
        settingsWindow?.title = "Clipboard10 设置"
        settingsWindow?.styleMask = [.titled, .closable]
        settingsWindow?.setContentSize(NSSize(width: 280, height: 380))
        settingsWindow?.isReleasedWhenClosed = false
        settingsWindow?.center()
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    @objc private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            statusMenu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height + 4), in: sender)
        } else {
            togglePopover()
        }
    }

    @objc private func openSettingsFromMenu() {
        popover.performClose(nil)
        showSettings()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func showPopover() {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func showSettings() {
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor.stopMonitoring()
        hotKeyManager.unregisterAll()
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
