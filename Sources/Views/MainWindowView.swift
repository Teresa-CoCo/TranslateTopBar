#if os(macOS)
import SwiftUI

struct MainWindowView: View {
    @EnvironmentObject private var historyStore: HistoryStore
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var modelCache: ModelListCache
    @EnvironmentObject private var openRouterClient: OpenRouterClient

    var body: some View {
        TabView {
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .environmentObject(historyStore)
        .environmentObject(settingsStore)
        .environmentObject(modelCache)
        .environmentObject(openRouterClient)
    }
}
#endif
