import Foundation

enum SCError: LocalizedError {
    case clientIDNotFound
    case badResponse(Int)
    case network(String)

    var errorDescription: String? {
        switch self {
        case .clientIDNotFound:
            return "Couldn't obtain a SoundCloud client id. SoundCloud may be unreachable."
        case .badResponse(let code):
            return "SoundCloud returned HTTP \(code)."
        case .network(let msg):
            return msg
        }
    }
}

/// Talks to SoundCloud's public `api-v2` endpoints. SoundCloud doesn't hand out
/// API keys anymore, so — like yt-dlp and scdl — we scrape a working `client_id`
/// out of the website's JavaScript bundles and reuse it.
actor SoundCloudClient {
    private var cachedClientID: String?
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " +
                          "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
        ]
        self.session = URLSession(configuration: config)
    }

    // MARK: - Public API

    func search(_ query: String, limit: Int = 30) async throws -> [SCTrack] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        do {
            return try await performSearch(trimmed, limit: limit)
        } catch SCError.badResponse(401) {
            // Stale client id — refresh once and retry.
            cachedClientID = nil
            return try await performSearch(trimmed, limit: limit)
        }
    }

    // MARK: - Search request

    private func performSearch(_ query: String, limit: Int) async throws -> [SCTrack] {
        let clientID = try await resolveClientID()

        var components = URLComponents(string: "https://api-v2.soundcloud.com/search/tracks")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: "0"),
        ]

        let (data, response) = try await session.data(from: components.url!)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard code == 200 else { throw SCError.badResponse(code) }

        let decoded = try JSONDecoder().decode(SCSearchResponse.self, from: data)
        return decoded.collection.compactMap { $0.toTrack() }
    }

    // MARK: - client_id discovery

    private func resolveClientID() async throws -> String {
        if let cached = cachedClientID { return cached }

        let homepage = try await fetchString("https://soundcloud.com/")
        let scriptURLs = Self.scriptSources(in: homepage)
            .filter { $0.contains("sndcdn.com") || $0.contains("soundcloud") }

        // The client_id usually lives in one of the later-loaded asset bundles.
        for url in scriptURLs.reversed() {
            guard let js = try? await fetchString(url) else { continue }
            if let id = Self.firstClientID(in: js) {
                cachedClientID = id
                return id
            }
        }
        throw SCError.clientIDNotFound
    }

    private func fetchString(_ urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else { throw SCError.network("Bad URL: \(urlString)") }
        let (data, response) = try await session.data(from: url)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard code == 200 else { throw SCError.badResponse(code) }
        return String(decoding: data, as: UTF8.self)
    }

    // MARK: - Parsing helpers

    private static func scriptSources(in html: String) -> [String] {
        regexMatches(in: html, pattern: #"<script[^>]+src="([^"]+)""#)
    }

    private static func firstClientID(in js: String) -> String? {
        // Matches  client_id:"xxxxx"  and  client_id="xxxxx"
        regexMatches(in: js, pattern: #"client_id\s*[:=]\s*"([A-Za-z0-9]{20,})""#).first
    }

    private static func regexMatches(in text: String, pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard match.numberOfRanges > 1,
                  let r = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[r])
        }
    }
}
