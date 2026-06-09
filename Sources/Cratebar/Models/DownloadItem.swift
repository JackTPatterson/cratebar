import Foundation
import Combine

@MainActor
final class DownloadItem: ObservableObject, Identifiable {
    enum Status: Equatable {
        case queued
        case downloading
        case converting
        case tagging
        case done(path: String)
        case failed(reason: String)

        var isTerminal: Bool {
            switch self {
            case .done, .failed: return true
            default: return false
            }
        }
    }

    let id = UUID()
    let track: SCTrack

    @Published var status: Status = .queued
    @Published var progress: Double = 0   // 0...1, used during the download phase

    init(track: SCTrack) {
        self.track = track
    }

    var statusText: String {
        switch status {
        case .queued:               return "Queued"
        case .downloading:          return "Downloading \(Int(progress * 100))%"
        case .converting:           return "Converting…"
        case .tagging:              return "Tagging…"
        case .done:                 return "Saved"
        case .failed(let reason):   return "Failed: \(reason)"
        }
    }
}
