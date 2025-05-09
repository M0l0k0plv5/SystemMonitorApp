import SwiftUI

@main
struct SystemMonitorApp: App {
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(
                    appearanceMode == .system ? nil :
                    (appearanceMode == .light ? .light : .dark)
                )
        }
    }
}
