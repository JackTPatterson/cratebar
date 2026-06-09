import SwiftUI

enum Screen {
    case search
    case settings
}

struct RootView: View {
    @EnvironmentObject var state: AppState
    @State private var screen: Screen = .search

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            Group {
                switch screen {
                case .search:   SearchView()
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(.regularMaterial)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "music.note")
                .foregroundStyle(.orange)
            Text("Cratebar")
                .font(.headline)
            if !state.tools.allInstalled {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                    .help("yt-dlp / ffmpeg not installed — open Settings")
            }
            Spacer()
            Button {
                screen = (screen == .settings) ? .search : .settings
            } label: {
                Image(systemName: screen == .settings ? "magnifyingglass" : "gearshape")
            }
            .buttonStyle(.borderless)
            .help(screen == .settings ? "Back to search" : "Settings")

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.borderless)
            .help("Quit Cratebar")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
