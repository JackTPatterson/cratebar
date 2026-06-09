import AppKit

/// The Cratebar menu bar glyph (record + note), embedded as a vector PDF so it
/// scales crisply and needs no resource bundling. Rendered as a *template*
/// image, so AppKit tints it to match the menu bar (light/dark, highlighted).
enum MenuBarIcon {
    static let image: NSImage = {
        guard let data = Data(base64Encoded: pdfBase64),
              let img = NSImage(data: data) else {
            // Fallback to an SF Symbol if decoding ever fails.
            return NSImage(systemSymbolName: "opticaldisc", accessibilityDescription: "Cratebar")
                ?? NSImage()
        }
        img.size = NSSize(width: 18, height: 18)
        img.isTemplate = true
        return img
    }()

    /// Vector PDF of Sources/Cratebar/Resources/icon.svg.
    private static let pdfBase64 = """
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
"""
}
