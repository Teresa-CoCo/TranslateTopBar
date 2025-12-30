#if os(macOS)
import SwiftUI

@main
struct TranslateTopBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @StateObject private var settingsStore = SettingsStore()
    @StateObject private var historyStore = HistoryStore()
    @StateObject private var modelCache = ModelListCache()
    @StateObject private var openRouterClient = OpenRouterClient()

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environmentObject(settingsStore)
                .environmentObject(historyStore)
                .environmentObject(openRouterClient)
                .environmentObject(modelCache)
        }
        .windowStyle(.automatic)
        .commands {
            CommandGroup(replacing: .appInfo) {}
        }
    }
}
#endif
