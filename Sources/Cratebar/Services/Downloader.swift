import Foundation

enum DownloadError: LocalizedError {
    case missingTools
    case ytDlpFailed(String)
    case noAudioProduced
    case ffmpegFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingTools:        return "yt-dlp / ffmpeg not installed"
        case .ytDlpFailed(let s):  return "download error \(s)"
        case .noAudioProduced:     return "no audio file produced"
        case .ffmpegFailed(let s): return "convert error \(s)"
        }
    }
}

/// Orchestrates the per-track pipeline: yt-dlp (fetch best audio + cover) →
/// ffmpeg (transcode to the chosen format, embed ID3 tags + artwork) → move
/// the tagged file into the user's library folder.
struct Downloader {
    let ytDlpPath: String
    let ffmpegPath: String
    /// SoundCloud Go+ OAuth token, if the user supplied one. Unlocks HQ (256k AAC) streams.
    var oauthToken: String? = nil

    func run(item: DownloadItem, settings: AppSettings) async {
        do {
            let finalPath = try await pipeline(item: item, settings: settings)
            await MainActor.run { item.status = .done(path: finalPath) }
        } catch {
            let reason = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            await MainActor.run { item.status = .failed(reason: reason) }
        }
    }

    private func pipeline(item: DownloadItem, settings: AppSettings) async throws -> String {
        let track = item.track
        let fm = FileManager.default

        // Scratch directory for this single download.
        let work = fm.temporaryDirectory
            .appendingPathComponent("cratebar-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: work, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: work) }

        // 1. Download best audio + cover art with yt-dlp.
        await MainActor.run { item.status = .downloading }
        let template = work.appendingPathComponent("audio.%(ext)s").path
        var ytArgs = [
            "--no-playlist",
            "--newline",
            "--no-warnings",
            // Prefer the artist's original uploaded file (lossless / as-uploaded) when
            // SoundCloud exposes it, then the highest-bitrate stream, then anything.
            "-f", "download/bestaudio/best",
            // Among streams, rank by higher audio bitrate then sample rate.
            "-S", "abr,asr,quality",
            "--write-thumbnail",
            "--convert-thumbnails", "jpg",
            "-o", template,
            track.permalinkURL,
        ]
        // With a Go+ token, authenticate every request so SoundCloud returns HQ transcodings.
        if let token = oauthToken?.trimmingCharacters(in: .whitespacesAndNewlines), !token.isEmpty {
            ytArgs.insert(contentsOf: ["--add-header", "Authorization:OAuth \(token)"], at: 0)
        }

        let ytResult = try await ProcessRunner.run(ytDlpPath, ytArgs) { line in
            if let pct = Self.parseProgress(line) {
                Task { @MainActor in item.progress = pct }
            }
        }
        guard ytResult.exitCode == 0 else {
            throw DownloadError.ytDlpFailed(Self.tail(ytResult.output))
        }

        // 2. Locate the produced audio + cover files.
        let produced = try fm.contentsOfDirectory(at: work, includingPropertiesForKeys: nil)
        let imageExts: Set<String> = ["jpg", "jpeg", "png", "webp"]
        guard let audioURL = produced.first(where: {
            !imageExts.contains($0.pathExtension.lowercased()) && $0.lastPathComponent.hasPrefix("audio")
        }) else {
            throw DownloadError.noAudioProduced
        }
        let coverURL = produced.first { imageExts.contains($0.pathExtension.lowercased()) }

        // 3. Transcode + tag with ffmpeg.
        await MainActor.run { item.status = .converting }
        let outExt = settings.format.fileExtension ?? audioURL.pathExtension
        let outURL = work.appendingPathComponent("tagged.\(outExt)")
        try await transcode(
            audio: audioURL, cover: coverURL, output: outURL,
            track: track, settings: settings
        )

        // 4. Move into the library folder.
        await MainActor.run { item.status = .tagging }
        let destination = try placeInLibrary(
            file: outURL, ext: outExt, track: track, settings: settings
        )
        return destination.path
    }

    // MARK: - ffmpeg transcode

    private func transcode(
        audio: URL, cover: URL?, output: URL,
        track: SCTrack, settings: AppSettings
    ) async throws {
        let metadata = Self.metadataArgs(track: track, album: settings.albumTag)

        // First attempt: embed the cover art as an ID3 attached picture.
        if let cover {
            let args =
                ["-y", "-i", audio.path, "-i", cover.path,
                 "-map", "0:a", "-map", "1:v",
                 "-c:v", "copy", "-disposition:v:0", "attached_pic"]
                + settings.format.ffmpegAudioArgs
                + metadata
                + ["-write_id3v2", "1", "-id3v2_version", "3", output.path]

            let result = try await ProcessRunner.run(ffmpegPath, args)
            if result.exitCode == 0 { return }
            // Some muxers reject the attached picture — fall through to audio-only.
            try? FileManager.default.removeItem(at: output)
        }

        // Fallback: audio + metadata, no embedded artwork.
        let args =
            ["-y", "-i", audio.path, "-map", "0:a"]
            + settings.format.ffmpegAudioArgs
            + metadata
            + ["-write_id3v2", "1", "-id3v2_version", "3", output.path]

        let result = try await ProcessRunner.run(ffmpegPath, args)
        guard result.exitCode == 0 else {
            throw DownloadError.ffmpegFailed(Self.tail(result.output))
        }
    }

    private static func metadataArgs(track: SCTrack, album: String) -> [String] {
        var args = [
            "-metadata", "title=\(track.title)",
            "-metadata", "artist=\(track.artist)",
            "-metadata", "album_artist=\(track.artist)",
            "-metadata", "album=\(album)",
            "-metadata", "comment=\(track.permalinkURL)",
        ]
        if let genre = track.genre, !genre.isEmpty {
            args += ["-metadata", "genre=\(genre)"]
        }
        return args
    }

    // MARK: - Library placement

    private func placeInLibrary(
        file: URL, ext: String, track: SCTrack, settings: AppSettings
    ) throws -> URL {
        let fm = FileManager.default
        var dir = URL(fileURLWithPath: settings.downloadDirectory, isDirectory: true)
        if settings.organizeByArtist {
            dir.appendPathComponent(Self.sanitize(track.artist), isDirectory: true)
        }
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)

        let base = "\(Self.sanitize(track.artist)) - \(Self.sanitize(track.title))"
        var candidate = dir.appendingPathComponent("\(base).\(ext)")
        var counter = 1
        while fm.fileExists(atPath: candidate.path) {
            candidate = dir.appendingPathComponent("\(base) (\(counter)).\(ext)")
            counter += 1
        }
        try fm.moveItem(at: file, to: candidate)
        return candidate
    }

    // MARK: - Helpers

    private static func sanitize(_ s: String) -> String {
        let illegal = CharacterSet(charactersIn: "/\\:*?\"<>|")
        let cleaned = s.components(separatedBy: illegal).joined(separator: "_")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "Untitled" : String(cleaned.prefix(180))
    }

    /// Parse a yt-dlp progress line like `[download]  42.7% of ...` → 0.427
    private static func parseProgress(_ line: String) -> Double? {
        guard line.contains("[download]"),
              let regex = try? NSRegularExpression(pattern: #"(\d+(?:\.\d+)?)%"#) else { return nil }
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = regex.firstMatch(in: line, range: range),
              let r = Range(match.range(at: 1), in: line),
              let value = Double(line[r]) else { return nil }
        return value / 100.0
    }

    private static func tail(_ output: String, lines: Int = 4) -> String {
        let parts = output.split(whereSeparator: { $0 == "\n" || $0 == "\r" })
        return parts.suffix(lines).joined(separator: " ").trimmingCharacters(in: .whitespaces)
    }
}
