import Foundation
import Security

// KeychainService provides direct Keychain access using the Security framework.
//
// WHY KEYCHAIN INSTEAD OF USERDEFAULTS:
//   • Keychain items are AES-256 encrypted at rest and protected by the device
//     passcode. UserDefaults is stored as a plaintext plist.
//   • With kSecAttrAccessibleWhenUnlockedThisDeviceOnly items are excluded from
//     iCloud / iTunes backups, preventing credential exposure if a backup is
//     compromised or shared.
//   • On devices with a Secure Enclave the encryption keys never leave the
//     hardware security boundary.
//   • OWASP M9 (Insecure Data Storage): Storing tokens or user identifiers in
//     UserDefaults is a common audit finding; Keychain is the recommended control.

enum KeychainError: Error, LocalizedError {
    case duplicateItem
    case itemNotFound
    case unexpectedStatus(OSStatus)
    case encodingError

    var errorDescription: String? {
        switch self {
        case .duplicateItem:
            return "A Keychain item with this key already exists."
        case .itemNotFound:
            return "No Keychain item found for the given key."
        case .unexpectedStatus(let status):
            return "Keychain returned unexpected status: \(status)."
        case .encodingError:
            return "Failed to encode or decode the value as UTF-8 data."
        }
    }
}

enum KeychainService {

    // The service name scopes all items to this app and avoids collisions with
    // other apps on the same device that might use the same key strings.
    private static let serviceName = "com.expensemy.keychain"

    // MARK: - Core Data Methods

    // Saves raw Data to the Keychain under the given key.
    // Returns false if the write failed for any reason (check console in DEBUG).
    // If an item for this key already exists it is updated rather than duplicated.
    @discardableResult
    static func save(key: String, data: Data) -> Bool {
        let query = baseQuery(for: key)

        // Attempt an update first; if the item doesn't exist, add it.
        let updateAttributes: [CFString: Any] = [kSecValueData: data]
        let updateStatus = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)

        if updateStatus == errSecSuccess {
            return true
        }

        if updateStatus == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            if addStatus != errSecSuccess {
                #if DEBUG
                print("[KeychainService] save failed for key '\(key)': OSStatus \(addStatus)")
                #endif
                return false
            }
            return true
        }

        #if DEBUG
        print("[KeychainService] save failed for key '\(key)': OSStatus \(updateStatus)")
        #endif
        return false
    }

    // Loads raw Data from the Keychain. Returns nil if the item does not exist
    // or if the read fails.
    static func load(key: String) -> Data? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            #if DEBUG
            if status != errSecItemNotFound {
                print("[KeychainService] load failed for key '\(key)': OSStatus \(status)")
            }
            #endif
            return nil
        }
        return result as? Data
    }

    // Deletes the Keychain item for the given key.
    // Returns true even if the item did not exist (idempotent delete).
    @discardableResult
    static func delete(key: String) -> Bool {
        let query = baseQuery(for: key)
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            #if DEBUG
            print("[KeychainService] delete failed for key '\(key)': OSStatus \(status)")
            #endif
            return false
        }
        return true
    }

    // Returns true if an item exists for the given key without reading its value.
    static func exists(key: String) -> Bool {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = false
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - String Convenience Methods

    // Encodes a String as UTF-8 and stores it. Returns false on encoding failure.
    @discardableResult
    static func saveString(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            #if DEBUG
            print("[KeychainService] saveString encoding failed for key '\(key)'")
            #endif
            return false
        }
        return save(key: key, data: data)
    }

    // Loads a UTF-8 String from the Keychain. Returns nil if missing or undecodable.
    static func loadString(key: String) -> String? {
        guard let data = load(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Private Helpers

    // Builds the base query dictionary shared by all Keychain operations.
    // kSecAttrAccessibleWhenUnlockedThisDeviceOnly:
    //   - Data is readable only while the device is unlocked.
    //   - The item is NOT migrated when the user restores from a backup.
    //   - This is the most secure accessibility constant for tokens / credentials.
    private static func baseQuery(for key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
    }
}
