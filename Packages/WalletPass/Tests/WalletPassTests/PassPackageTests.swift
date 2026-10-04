import Crypto
import XCTest
@_spi(CMS) import X509
@testable import WalletPass

final class PassPackageTests: XCTestCase {
    func testArchiveHasEveryFileWalletNeeds() throws {
        let (package, signer, _) = try makePackage()

        let entries = try ZipReader.entries(in: package.archive(signedBy: signer))

        XCTAssertEqual(
            Set(entries.map(\.name)),
            ["pass.json", "icon.png", "icon@2x.png", "manifest.json", "signature"]
        )
    }

    func testManifestHashesEveryOtherFile() throws {
        let (package, signer, _) = try makePackage()
        let entries = try ZipReader.entries(in: package.archive(signedBy: signer))
        let files = Dictionary(uniqueKeysWithValues: entries.map { ($0.name, $0.data) })

        let manifest = try JSONDecoder().decode([String: String].self, from: XCTUnwrap(files["manifest.json"]))

        XCTAssertEqual(Set(manifest.keys), ["pass.json", "icon.png", "icon@2x.png"])
        for (name, hash) in manifest {
            let expected = Insecure.SHA1.hash(data: try XCTUnwrap(files[name])).map { String(format: "%02x", $0) }.joined()
            XCTAssertEqual(hash, expected, name)
        }
    }

    func testPassJSONUsesTheCertificateIdentifiers() throws {
        let (package, signer, _) = try makePackage()
        let entries = try ZipReader.entries(in: package.archive(signedBy: signer))
        let passJSON = try XCTUnwrap(entries.first { $0.name == "pass.json" }?.data)

        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: passJSON) as? [String: Any])

        XCTAssertEqual(json["passTypeIdentifier"] as? String, "pass.com.example.cards")
        XCTAssertEqual(json["teamIdentifier"] as? String, "ABCDE12345")
    }

    func testSignatureCoversTheManifest() async throws {
        let (package, signer, certificate) = try makePackage()
        let entries = try ZipReader.entries(in: package.archive(signedBy: signer))
        let manifest = try XCTUnwrap(entries.first { $0.name == "manifest.json" }?.data)
        let signature = try XCTUnwrap(entries.first { $0.name == "signature" }?.data)

        let result = await CMS.isValidSignature(
            dataBytes: manifest,
            signatureBytes: signature,
            trustRoots: CertificateStore([certificate])
        ) {}

        guard case .success = result else { return XCTFail("Signature did not verify: \(result)") }
    }

    private func makePackage() throws -> (PassPackage, PassSigner, Certificate) {
        let identity = try TestIdentity.make()
        let signer = try PassSigner(certificate: identity.certificate, privateKey: identity.key)
        let pass = Pass(serialNumber: "card-1", organizationName: "Revolut", description: "Revolut Metal card")
        let images = ["icon.png": Data([1, 2, 3]), "icon@2x.png": Data([4, 5, 6])]
        return (PassPackage(pass: pass, images: images), signer, identity.certificate)
    }
}
