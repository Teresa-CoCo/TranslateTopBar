#if os(macOS)
import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var mainWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let settingsStore = SettingsStore()
        let historyStore = HistoryStore()
        let openRouterClient = OpenRouterClient()
        let modelCache = ModelListCache()

        let contentView = MainWindowView()
            .environmentObject(settingsStore)
            .environmentObject(historyStore)
            .environmentObject(openRouterClient)
            .environmentObject(modelCache)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 960, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.setFrameAutosaveName("MainWindow")
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        self.mainWindow = window

        menuBarController = MenuBarController(
            settingsStore: settingsStore,
            historyStore: historyStore,
            openRouterClient: openRouterClient,
            modelCache: modelCache
        )
        menuBarController?.showPopover()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
        } else {
            applicationDidFinishLaunching(Notification(name: Notification.Name("ApplicationReopen")))
        }
        return true
    }
}
#endif
