import Foundation

/// A single SoundCloud track returned from the v2 search API.
struct SCTrack: Identifiable, Hashable {
    let id: Int
    let title: String
    let artist: String
    let durationMs: Int
    let permalinkURL: String
    let artworkURL: String?
    let genre: String?

    var durationFormatted: String {
        let total = durationMs / 1000
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    /// A higher-resolution artwork URL (SoundCloud serves `-large` by default).
    var hiResArtworkURL: URL? {
        guard let raw = artworkURL else { return nil }
        let upgraded = raw.replacingOccurrences(of: "-large", with: "-t500x500")
        return URL(string: upgraded)
    }
}

// MARK: - Wire decoding (SoundCloud api-v2 shape)

struct SCSearchResponse: Decodable {
    let collection: [SCTrackWire]
}

struct SCTrackWire: Decodable {
    let id: Int
    let kind: String?
    let title: String?
    let duration: Int?
    let permalink_url: String?
    let artwork_url: String?
    let genre: String?
    let user: SCUserWire?

    struct SCUserWire: Decodable {
        let username: String?
        let avatar_url: String?
    }

    /// Convert a wire object into a clean `SCTrack`, or `nil` if it isn't a usable track.
    func toTrack() -> SCTrack? {
        guard (kind == nil || kind == "track"),
              let title, let permalink_url else { return nil }
        return SCTrack(
            id: id,
            title: title,
            artist: user?.username ?? "Unknown Artist",
            durationMs: duration ?? 0,
            permalinkURL: permalink_url,
            artworkURL: artwork_url ?? user?.avatar_url,
            genre: genre
        )
    }
}
