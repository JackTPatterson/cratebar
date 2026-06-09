import Foundation

enum AudioFormat: String, Codable, CaseIterable, Identifiable {
    case aiff
    case wav
    case mp3_320
    case original

    var id: String { rawValue }

    var label: String {
        switch self {
        case .aiff:     return "AIFF (Rekordbox-native)"
        case .wav:      return "WAV"
        case .mp3_320:  return "MP3 320"
        case .original: return "Keep best original"
        }
    }

    /// File extension for the produced file. `nil` means "whatever yt-dlp produced".
    var fileExtension: String? {
        switch self {
        case .aiff:     return "aiff"
        case .wav:      return "wav"
        case .mp3_320:  return "mp3"
        case .original: return nil
        }
    }

    /// ffmpeg audio codec arguments for the transcode step.
    var ffmpegAudioArgs: [String] {
        switch self {
        case .aiff:     return ["-c:a", "pcm_s16be"]
        case .wav:      return ["-c:a", "pcm_s16le"]
        case .mp3_320:  return ["-c:a", "libmp3lame", "-b:a", "320k"]
        case .original: return ["-c:a", "copy"]
        }
    }
}

struct AppSettings: Codable {
    var downloadDirectory: String
    var format: AudioFormat
    var organizeByArtist: Bool
    var albumTag: String

    static var defaultDirectory: String {
        let music = FileManager.default.urls(for: .musicDirectory, in: .userDomainMask).first
        let base = music ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Music")
        return base.appendingPathComponent("Cratebar").path
    }

    static let `default` = AppSettings(
        downloadDirectory: defaultDirectory,
        format: .aiff,
        organizeByArtist: false,
        albumTag: "SoundCloud"
    )

    // MARK: - Persistence (UserDefaults JSON blob)

    private static let key = "cratebar.settings.v1"

    static func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(AppSettings.self, from: data)
        else { return .default }
        return decoded
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}
