import Foundation
import Security

/// Minimal Keychain wrapper for the single credential Cratebar stores:
/// the user's SoundCloud OAuth token (for Go+ HQ streams).
enum Keychain {
    private static let service = "com.jackpatterson.cratebar"
    private static let account = "soundcloud-oauth"

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    /// Store (or, with `nil`/empty, remove) the OAuth token.
    static func set(_ value: String?) {
        SecItemDelete(baseQuery as CFDictionary)
        guard let value, !value.isEmpty, let data = value.data(using: .utf8) else { return }
        var add = baseQuery
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(add as CFDictionary, nil)
    }

    static func get() -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static var hasToken: Bool { Self.get() != nil }
}
