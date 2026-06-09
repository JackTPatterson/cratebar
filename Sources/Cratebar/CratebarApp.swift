import SwiftUI

@main
struct CratebarApp: App {
    @StateObject private var state = AppState()

    init() {
        // Menu-bar-only app: no Dock icon, no main window.
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            RootView()
                .environmentObject(state)
                .frame(width: 400, height: 540)
        } label: {
            Image(nsImage: MenuBarIcon.image)
        }
        .menuBarExtraStyle(.window)
    }
}
