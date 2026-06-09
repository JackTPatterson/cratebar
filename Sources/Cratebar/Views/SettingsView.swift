import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject var state: AppState
    @State private var tokenInput = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                librarySection
                Divider()
                formatSection
                Divider()
                authSection
                Divider()
                toolsSection
            }
            .padding(14)
        }
    }

    // MARK: - Library folder

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Record box folder")
            Text("Tracks are saved here with tags + artwork. Point Rekordbox at this folder.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Text(state.settings.downloadDirectory)
                    .font(.system(size: 11, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                Button("Choose…") { chooseFolder() }
            }
            HStack {
                Toggle("Organize into per-artist subfolders", isOn: Binding(
                    get: { state.settings.organizeByArtist },
                    set: { newValue in state.updateSettings { $0.organizeByArtist = newValue } }
                ))
                .toggleStyle(.checkbox)
                .font(.callout)
                Spacer()
                Button("Open") { state.openDownloadFolder() }
                    .font(.caption)
            }
        }
    }

    // MARK: - Format

    private var formatSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Audio format")
            Picker("", selection: Binding(
                get: { state.settings.format },
                set: { newValue in state.updateSettings { $0.format = newValue } }
            )) {
                ForEach(AudioFormat.allCases) { fmt in
                    Text(fmt.label).tag(fmt)
                }
            }
            .labelsHidden()
            .pickerStyle(.radioGroup)

            Text("SoundCloud streams cap quality at the source (often ~128 kbps). " +
                 "Transcoding can't add detail that isn't there — AIFF gives Rekordbox a " +
                 "clean, lossless container with full metadata.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Authentication (SoundCloud Go+)

    private var authSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionTitle("SoundCloud Go+ (optional)")
                Spacer()
                if state.hasAuthToken {
                    Label("Connected", systemImage: "checkmark.seal.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.green)
                }
            }
            Text("Paste your account's OAuth token to unlock HQ (256 kbps AAC) streams on " +
                 "tracks that don't offer an original download. Stored in your macOS Keychain.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                SecureField(state.hasAuthToken ? "•••••••• (saved)" : "oauth_token value", text: $tokenInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11, design: .monospaced))
                Button("Save") {
                    state.saveAuthToken(tokenInput)
                    tokenInput = ""
                }
                .disabled(tokenInput.trimmingCharacters(in: .whitespaces).isEmpty)
                if state.hasAuthToken {
                    Button("Remove") {
                        state.clearAuthToken()
                        tokenInput = ""
                    }
                }
            }

            DisclosureGroup("How do I get my token?") {
                VStack(alignment: .leading, spacing: 4) {
                    instructionRow(1, "Log into soundcloud.com in your browser with your Go+ account.")
                    instructionRow(2, "Open DevTools (⌥⌘I) → Application → Storage → Cookies → soundcloud.com.")
                    instructionRow(3, "Copy the value of the **oauth_token** cookie.")
                    instructionRow(4, "Paste it above and click Save.")
                    Text("Without Go+, Cratebar still grabs the best free stream (or the original file when an artist enables downloads).")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
                .padding(.top, 4)
            }
            .font(.caption)
        }
    }

    private func instructionRow(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("\(n).").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            Text(.init(text)).font(.caption).foregroundStyle(.secondary)
        }
    }

    // MARK: - Tools

    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Required tools")
            toolStatusRow("yt-dlp", installed: state.tools.ytDlpInstalled, path: state.tools.ytDlpPath)
            toolStatusRow("ffmpeg", installed: state.tools.ffmpegInstalled, path: state.tools.ffmpegPath)

            if !state.tools.allInstalled {
                HStack {
                    if ToolLocator.brewPath != nil {
                        Button {
                            state.installToolsWithHomebrew()
                        } label: {
                            Label("Install via Homebrew", systemImage: "shippingbox")
                        }
                        .disabled(state.isInstallingTools)
                    } else {
                        Text("Homebrew not found. Install from brew.sh, then run `brew install yt-dlp ffmpeg`.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if state.isInstallingTools { ProgressView().controlSize(.small) }
                    Button("Recheck") { state.tools.refresh() }
                        .font(.caption)
                }
            } else {
                Button("Recheck") { state.tools.refresh() }
                    .font(.caption)
            }

            if !state.installLog.isEmpty {
                ScrollView {
                    Text(state.installLog)
                        .font(.system(size: 10, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(height: 90)
                .background(.black.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    // MARK: - Bits

    private func sectionTitle(_ text: String) -> some View {
        Text(text).font(.headline)
    }

    private func toolStatusRow(_ name: String, installed: Bool, path: String?) -> some View {
        HStack(spacing: 6) {
            Image(systemName: installed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(installed ? .green : .red)
            Text(name).font(.callout.weight(.medium))
            Spacer()
            Text(installed ? (path ?? "") : "not found")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: state.settings.downloadDirectory)
        if panel.runModal() == .OK, let url = panel.url {
            state.updateSettings { $0.downloadDirectory = url.path }
        }
    }
}
