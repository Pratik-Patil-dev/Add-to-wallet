import Foundation
import Observation
import Security
import WalletPass

/// Holds the Pass Type ID certificate used to sign passes on the phone.
///
/// The `.p12` and its password live in the keychain, never in the repo or
/// the app bundle, and never leave this device.
@Observable
final class PassSigningStore {
    private(set) var signer: PassSigner?
    private(set) var problem: String?

    init() {
        guard let stored = Keychain.read() else { return }
        do {
            let identity = try JSONDecoder().decode(StoredIdentity.self, from: stored)
            signer = try PassSigner(pkcs12: identity.pkcs12, password: identity.password)
        } catch {
            problem = error.localizedDescription
        }
    }

    func importCertificate(_ pkcs12: Data, password: String) throws {
        let signer = try PassSigner(pkcs12: pkcs12, password: password)
        try Keychain.write(JSONEncoder().encode(StoredIdentity(pkcs12: pkcs12, password: password)))
        self.signer = signer
        problem = nil
    }

    func removeCertificate() {
        Keychain.delete()
        signer = nil
        problem = nil
    }
}

private struct StoredIdentity: Codable {
    let pkcs12: Data
    let password: String
}

private enum Keychain {
    struct Failure: LocalizedError {
        let status: OSStatus
        var errorDescription: String? { "Couldn't save to the keychain (\(status))." }
    }

    private static let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "dev.pratikpatil.cardfolio.pass-signing",
        kSecAttrAccount as String: "pass-type-identity",
    ]

    static func read() -> Data? {
        var search = query
        search[kSecReturnData as String] = true
        search[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        guard SecItemCopyMatching(search as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    static func write(_ data: Data) throws {
        delete()
        var item = query
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let status = SecItemAdd(item as CFDictionary, nil)
        guard status == errSecSuccess else { throw Failure(status: status) }
    }

    static func delete() {
        SecItemDelete(query as CFDictionary)
    }
}
