#if os(macOS)
import SwiftUI

@main
struct TranslateTopBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Minimal WindowGroup - will be closed by AppDelegate
        WindowGroup {
            EmptyView()
                .frame(width: 0, height: 0)
        }
    }
}
#endif
