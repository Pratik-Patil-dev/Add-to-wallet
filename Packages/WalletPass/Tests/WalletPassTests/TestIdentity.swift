import Foundation
import SwiftASN1
import X509
import _CryptoExtras

/// A throwaway self-signed certificate shaped like the ones the Apple
/// Developer portal issues for Pass Type IDs.
enum TestIdentity {
    static func make(
        passType: String? = "pass.com.example.cards",
        team: String = "ABCDE12345",
        expiresIn lifetime: TimeInterval = 3600
    ) throws -> (certificate: Certificate, key: Certificate.PrivateKey) {
        let key = Certificate.PrivateKey(try _RSA.Signing.PrivateKey(keySize: .bits2048))

        var attributes: [RelativeDistinguishedName.Attribute] = [
            .init(type: .RDNAttributeType.commonName, utf8String: "Pass Type ID: \(passType ?? "none")"),
            .init(type: .RDNAttributeType.organizationalUnitName, utf8String: team),
        ]
        if let passType {
            attributes.insert(.init(type: [0, 9, 2342, 19_200_300, 100, 1, 1], utf8String: passType), at: 0)
        }
        let name = DistinguishedName(attributes.map { RelativeDistinguishedName($0) })

        let now = Date()
        let certificate = try Certificate(
            version: .v3,
            serialNumber: Certificate.SerialNumber(),
            publicKey: key.publicKey,
            notValidBefore: now - 3600,
            notValidAfter: now + lifetime,
            issuer: name,
            subject: name,
            signatureAlgorithm: .sha256WithRSAEncryption,
            extensions: Certificate.Extensions(),
            issuerPrivateKey: key
        )
        return (certificate, key)
    }
}
