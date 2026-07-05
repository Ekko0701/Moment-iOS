import Foundation
import Security

public final actor KeychainTokenStore: TokenStoreProtocol {
    private let service = "com.moment.app"
    private let accessTokenKey = "moment.accessToken"
    private let refreshTokenKey = "moment.refreshToken"

    public init() {}

    public func getAccessToken() -> String? {
        query(key: accessTokenKey)
    }

    public func setAccessToken(_ token: String) throws {
        try set(token, forKey: accessTokenKey)
    }

    public func getRefreshToken() -> String? {
        query(key: refreshTokenKey)
    }

    public func setRefreshToken(_ token: String) throws {
        try set(token, forKey: refreshTokenKey)
    }

    public func deleteTokens() throws {
        try delete(key: accessTokenKey)
        try delete(key: refreshTokenKey)
    }

    private func query(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    private func set(_ value: String, forKey key: String) throws {
        let data = value.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)

        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    private func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

// MARK: - Keychain Error

enum KeychainError: Error {
    case saveFailed(OSStatus)
    case deleteFailed(OSStatus)
    case itemNotFound
}
