import SwiftUI

struct SearchView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()

            if !state.downloads.isEmpty {
                DownloadsStrip()
                Divider()
            }

            content
        }
    }

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search SoundCloud…", text: $state.query)
                .textFieldStyle(.plain)
                .onSubmit { Task { await state.search() } }
            if state.isSearching {
                ProgressView().controlSize(.small)
            } else if !state.query.isEmpty {
                Button {
                    state.query = ""
                    state.results = []
                    state.searchError = nil
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var content: some View {
        if !state.tools.allInstalled {
            missingToolsNotice
        } else if let error = state.searchError {
            centeredMessage(icon: "exclamationmark.circle", text: error)
        } else if state.results.isEmpty {
            centeredMessage(
                icon: "music.note.list",
                text: "Search for a track to download into your record box."
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(state.results) { track in
                        TrackRow(track: track)
                        Divider()
                    }
                }
            }
        }
    }

    private var missingToolsNotice: some View {
        VStack(spacing: 10) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Setup required")
                .font(.headline)
            Text("Cratebar needs **yt-dlp** and **ffmpeg** to download and convert audio.")
                .multilineTextAlignment(.center)
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            Text("Open Settings (gear icon) to install them.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func centeredMessage(icon: String, text: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(text)
                .multilineTextAlignment(.center)
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Track row

struct TrackRow: View {
    @EnvironmentObject var state: AppState
    let track: SCTrack

    var body: some View {
        HStack(spacing: 10) {
            artwork
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Text(track.artist)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            Text(track.durationFormatted)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
            Button {
                state.download(track)
            } label: {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.borderless)
            .help("Download to your record box")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
    }

    private var artwork: some View {
        AsyncImage(url: track.hiResArtworkURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill)
            default:
                Rectangle().fill(.quaternary)
                    .overlay(Image(systemName: "music.note").foregroundStyle(.secondary))
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}
