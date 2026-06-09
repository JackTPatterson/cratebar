import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    // Search
    @Published var query = ""
    @Published var results: [SCTrack] = []
    @Published var isSearching = false
    @Published var searchError: String?

    // Downloads (most recent first)
    @Published var downloads: [DownloadItem] = []

    // Settings + tooling
    @Published var settings = AppSettings.load()
    @Published var tools = ToolLocator()

    // Homebrew install progress
    @Published var isInstallingTools = false
    @Published var installLog = ""

    // SoundCloud Go+ authentication (token stored in Keychain)
    @Published var hasAuthToken = Keychain.hasToken

    private let client = SoundCloudClient()

    // MARK: - Search

    func search() async {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        isSearching = true
        searchError = nil
        defer { isSearching = false }
        do {
            results = try await client.search(q)
            if results.isEmpty { searchError = "No tracks found." }
        } catch {
            searchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            results = []
        }
    }

    // MARK: - Downloads

    func download(_ track: SCTrack) {
        guard let ytDlp = tools.ytDlpPath, let ffmpeg = tools.ffmpegPath else { return }
        let item = DownloadItem(track: track)
        downloads.insert(item, at: 0)
        let downloader = Downloader(ytDlpPath: ytDlp, ffmpegPath: ffmpeg, oauthToken: Keychain.get())
        let settingsSnapshot = settings
        Task.detached {
            await downloader.run(item: item, settings: settingsSnapshot)
        }
    }

    func clearFinishedDownloads() {
        downloads.removeAll { $0.status.isTerminal }
    }

    func revealInFinder(_ item: DownloadItem) {
        if case let .done(path) = item.status {
            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
        }
    }

    // MARK: - Settings

    func updateSettings(_ mutate: (inout AppSettings) -> Void) {
        var copy = settings
        mutate(&copy)
        settings = copy
        copy.save()
    }

    // MARK: - Authentication

    func saveAuthToken(_ token: String) {
        Keychain.set(token.trimmingCharacters(in: .whitespacesAndNewlines))
        hasAuthToken = Keychain.hasToken
    }

    func clearAuthToken() {
        Keychain.set(nil)
        hasAuthToken = false
    }

    func openDownloadFolder() {
        let url = URL(fileURLWithPath: settings.downloadDirectory, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        NSWorkspace.shared.open(url)
    }

    // MARK: - Tool installation

    func installToolsWithHomebrew() {
        guard let brew = ToolLocator.brewPath, !isInstallingTools else { return }
        isInstallingTools = true
        installLog = "Installing yt-dlp and ffmpeg via Homebrew…\n"
        Task {
            let result = try? await ProcessRunner.run(brew, ["install", "yt-dlp", "ffmpeg"]) { line in
                Task { @MainActor in self.installLog += line + "\n" }
            }
            self.isInstallingTools = false
            self.tools.refresh()
            if self.tools.allInstalled {
                self.installLog += "\n✅ Done. Tools are ready.\n"
            } else {
                self.installLog += "\n⚠️ Install finished (exit \(result?.exitCode ?? -1)) " +
                                   "but tools still not found. Try installing from Terminal.\n"
            }
        }
    }
}
