<div align="center">

# 🎚️ Cratebar

**Search SoundCloud and drop tracks straight into your DJ crate — from the macOS menu bar.**

A native SwiftUI menu bar app that finds tracks on SoundCloud, downloads the
best available audio, transcodes to a Rekordbox-ready format, tags it with
artwork, and files it into a folder you choose.

![platform](https://img.shields.io/badge/platform-macOS%2014%2B-black)
![swift](https://img.shields.io/badge/Swift-6-orange)
![license](https://img.shields.io/badge/license-MIT-blue)

</div>

---

## Features

- 🔎 **Search SoundCloud** right from the menu bar — no browser needed
- ⬇️ **Best-quality downloads** via [`yt-dlp`](https://github.com/yt-dlp/yt-dlp): prefers the artist's original uploaded file, falls back to the highest-bitrate stream
- 🎛️ **DJ-ready formats** via [`ffmpeg`](https://ffmpeg.org): **AIFF** (Rekordbox-native), WAV, MP3 320, or keep the original
- 🏷️ **Full metadata** — embeds ID3 tags (title / artist / album / genre) **and cover art**
- 📁 **Your folder, your rules** — pick a "record box" directory, optionally split into per-artist subfolders
- 🔐 **SoundCloud Go+ support** (optional) — unlock 256 kbps AAC HQ streams; token stored in the macOS Keychain
- 🍺 **Zero-fuss setup** — installs `yt-dlp` + `ffmpeg` for you via Homebrew
- 🪶 **Truly native & lightweight** — `MenuBarExtra`, no Dock icon, no Electron

> **A note on audio quality.** SoundCloud streams are capped at the source
> bitrate (commonly ~128 kbps, or the original file when the uploader enabled
> downloads; up to 256 kbps AAC with Go+). Cratebar always grabs the best
> available source — transcoding to AIFF gives you a clean, lossless *container*
> with full metadata, but it can't manufacture detail the source doesn't contain.

---

## Screenshots

> _The app lives in your menu bar. Click the icon to search; the gear opens Settings._

```
┌─────────────────────────────────┐
│ 🎵 Cratebar            ⚙︎  ⏻     │
├─────────────────────────────────┤
│ 🔎 daft punk                  ✕ │
├─────────────────────────────────┤
│ ▸ Downloads                     │
│   ✓ Around the World   Saved 🔍 │
├─────────────────────────────────┤
│ ▦  Around the World             │
│    Daft Punk            7:09  ⬇ │
│ ▦  One More Time                │
│    Daft Punk            5:20  ⬇ │
└─────────────────────────────────┘
```

---

## Requirements

- **macOS 14 (Sonoma) or later**
- **Xcode / Swift 6 toolchain** to build (`xcode-select --install` provides the basics; full Xcode recommended)
- **[`yt-dlp`](https://github.com/yt-dlp/yt-dlp)** and **[`ffmpeg`](https://ffmpeg.org)** — Cratebar can install these for you via [Homebrew](https://brew.sh) on first run

---

## Install

```bash
git clone https://github.com/JackTPatterson/cratebar.git
cd cratebar

# Build a proper menu-bar .app bundle
./Scripts/build-app.sh

# Launch it
open build/Cratebar.app

# (optional) move it into /Applications
cp -R build/Cratebar.app /Applications/
```

Prefer to run straight from source while hacking on it:

```bash
swift run Cratebar
```

A small **download-into-box** icon appears in your menu bar. Click it to start.

---

## First run

1. Click the menu bar icon → **gear** (Settings).
2. If **yt-dlp** / **ffmpeg** show as missing, click **Install via Homebrew**.
3. Choose your **record box folder** (defaults to `~/Music/Cratebar`).
4. Pick your **audio format** (defaults to AIFF).
5. _(Optional)_ Under **SoundCloud Go+**, paste your `oauth_token` to unlock HQ
   streams — see [below](#unlocking-hq-with-soundcloud-go).
6. Back on the search screen, search a track and hit the **download arrow** ⬇.

Then point Rekordbox at your record box folder (or drag the files in) and they
import with artwork and tags intact.

### Unlocking HQ with SoundCloud Go+

Cratebar works fully without an account. If you have **SoundCloud Go+**, you can
unlock 256 kbps AAC streams on tracks that don't offer an original download:

1. Log into [soundcloud.com](https://soundcloud.com) in your browser (Go+ account).
2. Open DevTools (`⌥⌘I`) → **Application** → **Storage** → **Cookies** → `soundcloud.com`.
3. Copy the value of the **`oauth_token`** cookie.
4. Paste it into **Settings → SoundCloud Go+** and click **Save**.

The token is stored in your **macOS Keychain** and sent to `yt-dlp` as an
`Authorization: OAuth <token>` header. Tokens rotate periodically — if HQ stops
working, paste a fresh one.

---

## How it works

```
Search   →  SoundCloud api-v2 /search/tracks
            (client_id scraped from the site's JS, the same technique yt-dlp/scdl use)

Download →  yt-dlp -f "download/bestaudio/best" -S abr,asr   (+ cover thumbnail)
            └─ with a Go+ token: Authorization: OAuth <token>  → HQ transcodings

Convert  →  ffmpeg → AIFF / WAV / MP3, ID3v2 tags + attached cover art
            (cover embed has an audio-only fallback if a muxer rejects it)

Place    →  moved into your folder as "Artist - Title.aiff"
            (optionally Artist/ subfolders, with collision-safe naming)
```

---

## Project layout

```
Sources/Cratebar/
  CratebarApp.swift         App entry — MenuBarExtra, accessory (no Dock icon)
  AppState.swift            Observable app state (search, downloads, settings, auth)
  Models/
    Track.swift             SCTrack + api-v2 wire decoding
    Settings.swift          AppSettings (persisted) + AudioFormat
    DownloadItem.swift       Per-download progress/status
  Services/
    SoundCloudClient.swift   client_id discovery + v2 search (actor)
    Downloader.swift         yt-dlp → ffmpeg → tag → move pipeline
    ProcessRunner.swift      async subprocess runner with line streaming
    ToolLocator.swift        finds yt-dlp / ffmpeg / brew
    Keychain.swift           stores the SoundCloud Go+ OAuth token
  Views/
    RootView.swift           header + screen switching
    SearchView.swift         search bar, results, setup notice
    DownloadsStrip.swift     active/recent downloads list
    SettingsView.swift       folder, format, auth, tools
Scripts/
  build-app.sh              Packages the binary into Cratebar.app
```

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Menu bar icon doesn't appear | Make sure the build succeeded; relaunch with `open build/Cratebar.app`. |
| "No tracks found" / search errors | SoundCloud may have rotated its asset bundles; the client_id auto-refreshes on a 401. Try again. |
| Downloads fail immediately | Check Settings — `yt-dlp` and `ffmpeg` must both be green. |
| HQ not kicking in | Confirm Go+ shows **Connected ✓**; paste a fresh `oauth_token` if it expired. |
| First Keychain save shows a prompt | Expected for an unsigned app — click **Allow**. |
| "app can't be opened" (Gatekeeper) | The bundle is ad-hoc signed. Right-click → **Open**, or `xattr -dr com.apple.quarantine build/Cratebar.app`. |

---

## Legal & ethics

Cratebar is a personal tool. **Only download tracks you have the right to
download.** Respect [SoundCloud's Terms of Service](https://soundcloud.com/terms-of-use)
and the rights of artists and rightsholders. The author accepts no liability for
misuse.

---

## License

[MIT](LICENSE) © 2026 Jack Patterson
