import Foundation

/// Locates the external CLI tools the app depends on (`yt-dlp`, `ffmpeg`).
/// Apps launched from Finder don't inherit a login shell `PATH`, so we probe
/// the common Homebrew / system locations directly.
@MainActor
final class ToolLocator: ObservableObject {
    @Published private(set) var ytDlpPath: String?
    @Published private(set) var ffmpegPath: String?

    private static let searchDirectories = [
        "/opt/homebrew/bin",   // Apple Silicon Homebrew
        "/usr/local/bin",      // Intel Homebrew
        "/opt/local/bin",      // MacPorts
        "/usr/bin",
    ]

    init() {
        refresh()
    }

    var ytDlpInstalled: Bool { ytDlpPath != nil }
    var ffmpegInstalled: Bool { ffmpegPath != nil }
    var allInstalled: Bool { ytDlpInstalled && ffmpegInstalled }

    func refresh() {
        ytDlpPath = Self.locate("yt-dlp")
        ffmpegPath = Self.locate("ffmpeg")
    }

    private static func locate(_ name: String) -> String? {
        let fm = FileManager.default
        for dir in searchDirectories {
            let candidate = "\(dir)/\(name)"
            if fm.isExecutableFile(atPath: candidate) {
                return candidate
            }
        }
        return nil
    }

    /// Path to the `brew` binary, if present.
    static var brewPath: String? {
        for candidate in ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"] {
            if FileManager.default.isExecutableFile(atPath: candidate) {
                return candidate
            }
        }
        return nil
    }
}
