import SwiftUI

/// Collapsible list of active / recent downloads shown above search results.
struct DownloadsStrip: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Downloads")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Clear finished") { state.clearFinishedDownloads() }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .disabled(!state.downloads.contains { $0.status.isTerminal })
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .padding(.bottom, 2)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(state.downloads) { item in
                        DownloadRow(item: item)
                    }
                }
            }
            .frame(maxHeight: 132)
        }
    }
}

struct DownloadRow: View {
    @EnvironmentObject var state: AppState
    @ObservedObject var item: DownloadItem

    var body: some View {
        HStack(spacing: 8) {
            statusIcon
            VStack(alignment: .leading, spacing: 2) {
                Text(item.track.title)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                if case .downloading = item.status {
                    ProgressView(value: item.progress)
                        .progressViewStyle(.linear)
                        .controlSize(.small)
                } else {
                    Text(item.statusText)
                        .font(.system(size: 10))
                        .foregroundStyle(statusColor)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 4)
            if case .done = item.status {
                Button {
                    state.revealInFinder(item)
                } label: {
                    Image(systemName: "magnifyingglass.circle")
                }
                .buttonStyle(.borderless)
                .help("Reveal in Finder")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
    }

    private var statusIcon: some View {
        Group {
            switch item.status {
            case .queued:
                Image(systemName: "clock").foregroundStyle(.secondary)
            case .downloading, .converting, .tagging:
                ProgressView().controlSize(.small)
            case .done:
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            case .failed:
                Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
            }
        }
        .frame(width: 16)
    }

    private var statusColor: Color {
        switch item.status {
        case .failed: return .red
        case .done:   return .green
        default:      return .secondary
        }
    }
}
