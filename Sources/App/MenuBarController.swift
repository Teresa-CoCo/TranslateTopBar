#if os(macOS)
import AppKit
import SwiftUI

final class MenuBarController: NSObject, NSPopoverDelegate {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private var eventMonitor: Any?

    private let settingsStore: SettingsStore
    private let historyStore: HistoryStore
    private let openRouterClient: OpenRouterClient
    private let modelCache: ModelListCache

    init(settingsStore: SettingsStore,
         historyStore: HistoryStore,
         openRouterClient: OpenRouterClient,
         modelCache: ModelListCache) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.popover = NSPopover()
        self.settingsStore = settingsStore
        self.historyStore = historyStore
        self.openRouterClient = openRouterClient
        self.modelCache = modelCache
        super.init()
        configureStatusItem()
        configurePopover()
    }

    func showPopover() {
        guard let button = statusItem.button else { return }
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        startEventMonitor()
    }

    func closePopover() {
        popover.performClose(nil)
        stopEventMonitor()
    }

    private func configureStatusItem() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "character.bubble", accessibilityDescription: "TranslateTopBar")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        let contentView = MenuBarPopoverView()
            .environmentObject(settingsStore)
            .environmentObject(historyStore)
            .environmentObject(openRouterClient)
            .environmentObject(modelCache)
        popover.contentSize = NSSize(width: 420, height: 380)
        popover.contentViewController = NSHostingController(rootView: contentView)
    }

    @objc private func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func startEventMonitor() {
        guard eventMonitor == nil else { return }
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }

    private func stopEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
#endif
