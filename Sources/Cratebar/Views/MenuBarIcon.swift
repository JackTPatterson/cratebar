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
JVBERi0xLjcKJbXtrvsKNCAwIG9iago8PCAvTGVuZ3RoIDUgMCBSCiAgIC9GaWx0ZXIgL0ZsYXRlRGVjb2RlCj4+CnN0cmVhbQp4nFVSS45UMQzc5xS+AJ5n5+ecAAmJBbAczQI9JBDqXoxYcH2qkvRjRq1+SSWuctmOyYHfB8PHi5z39Jqw11rMesMmj3b0kK8f5en7IT//JNMqfxHzCf/f6fkFMYf8SEU+i2tFaGjrLnfJaqNK05GlqIdJhRi/3QZPspziYgzFgmiwXN0siZEwtp6B54HgoQfOkL+DYkgLLmBUJxoR4lMP31Osa/XEPQ8J9u05V4OXIHsUIzuWdBQCz0y3jNrQXiXdAb0S5W5wHwdoATZLoRRACdJ88ZvmQpsBwkAvmhsr8ZHTqnqa3LavatRK7Dq1sEGhddC+4eiOm9IuCI4FetVWfiJmqFuYqGhDeZuVOYmlN7endFRoG6X+CO+XSn+I78CV962lU36l9xa/JWtUKs1YfkM4+nbjbj4FaHPQTXueBjlaXDRqYSqsv3MMt8QiMOpVGihocBkPMNTQ0PMBl+MbsyO10fdRp4E6X9LGtFY5mP8ez7nPWsOvYNfo6xVSaiLGIShfmItfxAUuxQVXpslKl4O39ti9PalDe/PVsDErYi1f0j/qerCyCmVuZHN0cmVhbQplbmRvYmoKNSAwIG9iagogICA0MjQKZW5kb2JqCjMgMCBvYmoKPDwKICAgL0V4dEdTdGF0ZSA8PAogICAgICAvYTAgPDwgL0NBIDEgL2NhIDEgPj4KICAgPj4KPj4KZW5kb2JqCjcgMCBvYmoKPDwgL1R5cGUgL09ialN0bQogICAvTGVuZ3RoIDggMCBSCiAgIC9OIDEKICAgL0ZpcnN0IDQKICAgL0ZpbHRlciAvRmxhdGVEZWNvZGUKPj4Kc3RyZWFtCnicM1Mw4IrmiuUCAAY4AV0KZW5kc3RyZWFtCmVuZG9iago4IDAgb2JqCiAgIDE2CmVuZG9iago5IDAgb2JqCjw8IC9UeXBlIC9PYmpTdG0KICAgL0xlbmd0aCAxMiAwIFIKICAgL04gNAogICAvRmlyc3QgMjMKICAgL0ZpbHRlciAvRmxhdGVEZWNvZGUKPj4Kc3RyZWFtCnicVZFBa4QwEIXv+RVzKdVDdRLdbbvIHlZhKaUgbm+lhxAHVyhGkli6/76JrltKcpmPN3lvJhyQcYQNMgF8wxnnkD0KVhSQvl9GgrSWHVkGAOlr31r4AAEIDXzOqNTT4ICz/X7uqI1uJ0UGIiV7o4En/CnJITo7N9pdms60M3I898om2nRxvDxjSLpeD5V0BFG1Eyi2uMVnRMxy/oD5PWK8mvzFgjtvHfpraSjkCMlm8EZtLw/6x8dFf0Qe7hp5cF5sIb+pj0ZPIxRFKEK9OMx0RSdPjRzsGJzUZcUv4MxEa1V6VUXfvaLmeAjQJw68Iasno8hCdvM8+UblluDW/8G/4Urp5JfurrP5/V9H86JfR9luXQplbmRzdHJlYW0KZW5kb2JqCjEyIDAgb2JqCiAgIDI3NgplbmRvYmoKMTMgMCBvYmoKPDwgL1R5cGUgL1hSZWYKICAgL0xlbmd0aCA1OAogICAvRmlsdGVyIC9GbGF0ZURlY29kZQogICAvU2l6ZSAxNAogICAvVyBbMSAyIDJdCiAgIC9Sb290IDExIDAgUgogICAvSW5mbyAxMCAwIFIKPj4Kc3RyZWFtCnicY2Bg+P+fiYGTgQFEMDEySTEwMDLwAwkmFpAYO4iVBCKegIifEHWMIIKZkaURKMYyg4EBANqYBdkKZW5kc3RyZWFtCmVuZG9iagpzdGFydHhyZWYKMTE3NgolJUVPRgo=
"""
}
