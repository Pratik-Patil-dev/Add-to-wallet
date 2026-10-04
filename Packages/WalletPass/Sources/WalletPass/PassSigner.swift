import Foundation
import SwiftASN1
@_spi(CMS) import X509

/// Signs pass manifests with a Pass Type ID certificate from the Apple
/// Developer portal.
///
/// Wallet expects a detached PKCS #7 signature over `manifest.json` that
/// carries both the pass certificate and Apple's WWDR intermediate.
public struct PassSigner {
    public enum Failure: LocalizedError, Equatable {
        case wrongPassword
        case unreadableIdentity
        case notAPassCertificate
        case expired(Date)

        public var errorDescription: String? {
            switch self {
            case .wrongPassword:
                return "That password doesn't unlock the certificate."
            case .unreadableIdentity:
                return "Couldn't read a certificate and private key from that file."
            case .notAPassCertificate:
                return "This isn't a Pass Type ID certificate. Create one under Identifiers → Pass Type IDs in the Apple Developer portal."
            case .expired(let date):
                return "This certificate expired on \(date.formatted(date: .abbreviated, time: .omitted))."
            }
        }
    }

    public let passTypeIdentifier: String
    public let teamIdentifier: String
    public var expiresAt: Date { certificate.notValidAfter }

    private let certificate: Certificate
    private let privateKey: Certificate.PrivateKey
    private let intermediate: Certificate

    public init(
        certificate: Certificate,
        privateKey: Certificate.PrivateKey,
        intermediate: Certificate? = nil,
        now: Date = Date()
    ) throws {
        guard let identifiers = Self.identifiers(in: certificate) else {
            throw Failure.notAPassCertificate
        }
        guard certificate.notValidAfter > now else {
            throw Failure.expired(certificate.notValidAfter)
        }

        self.passTypeIdentifier = identifiers.passType
        self.teamIdentifier = identifiers.team
        self.certificate = certificate
        self.privateKey = privateKey
        self.intermediate = try intermediate ?? Self.appleIntermediate()
    }

    func signature(for manifest: Data, signedAt date: Date = Date()) throws -> Data {
        let signature = try CMS.sign(
            manifest,
            signatureAlgorithm: .sha256WithRSAEncryption,
            additionalIntermediateCertificates: [intermediate],
            certificate: certificate,
            privateKey: privateKey,
            signingTime: date,
            detached: true
        )
        return Data(signature)
    }

    /// Pass certificates put the pass type in the subject's UID and the team
    /// in its OU, so the user never has to type either.
    private static func identifiers(in certificate: Certificate) -> (passType: String, team: String)? {
        let userID: ASN1ObjectIdentifier = [0, 9, 2342, 19_200_300, 100, 1, 1]
        var passType: String?
        var team: String?

        for attribute in certificate.subject.flatMap({ $0 }) {
            if attribute.type == userID {
                passType = String(attribute.value)
            } else if attribute.type == .RDNAttributeType.organizationalUnitName {
                team = String(attribute.value)
            }
        }

        guard let passType, passType.hasPrefix("pass."), let team, !team.isEmpty else { return nil }
        return (passType, team)
    }

    /// Apple Worldwide Developer Relations G4, valid until December 2030.
    /// https://www.apple.com/certificateauthority/
    static let appleIntermediateURL = Bundle.module.url(forResource: "AppleWWDRCAG4", withExtension: "cer")

    private static func appleIntermediate() throws -> Certificate {
        guard let url = appleIntermediateURL else { throw Failure.unreadableIdentity }
        return try Certificate(derEncoded: Array(Data(contentsOf: url)))
    }
}

#if canImport(Security)
import Security

extension PassSigner {
    /// Loads the identity exported from Keychain Access as a `.p12`.
    public init(pkcs12: Data, password: String) throws {
        var items: CFArray?
        let options = [kSecImportExportPassphrase as String: password] as CFDictionary

        switch SecPKCS12Import(pkcs12 as CFData, options, &items) {
        case errSecSuccess: break
        case errSecAuthFailed: throw Failure.wrongPassword
        default: throw Failure.unreadableIdentity
        }

        guard
            let item = (items as? [[String: Any]])?.first,
            let rawIdentity = item[kSecImportItemIdentity as String]
        else { throw Failure.unreadableIdentity }

        let identity = rawIdentity as! SecIdentity
        var certificate: SecCertificate?
        var key: SecKey?

        guard
            SecIdentityCopyCertificate(identity, &certificate) == errSecSuccess, let certificate,
            SecIdentityCopyPrivateKey(identity, &key) == errSecSuccess, let key
        else { throw Failure.unreadableIdentity }

        try self.init(certificate: Certificate(certificate), privateKey: Certificate.PrivateKey(key))
    }
}
#endif
