import XCTest
@_spi(CMS) import X509
@testable import WalletPass

final class PassSignerTests: XCTestCase {
    func testReadsIdentifiersFromTheCertificate() throws {
        let identity = try TestIdentity.make()
        let signer = try PassSigner(certificate: identity.certificate, privateKey: identity.key)

        XCTAssertEqual(signer.passTypeIdentifier, "pass.com.example.cards")
        XCTAssertEqual(signer.teamIdentifier, "ABCDE12345")
    }

    func testRejectsCertificatesWithoutAPassType() throws {
        let identity = try TestIdentity.make(passType: nil)

        XCTAssertThrowsError(try PassSigner(certificate: identity.certificate, privateKey: identity.key)) {
            XCTAssertEqual($0 as? PassSigner.Failure, .notAPassCertificate)
        }
    }

    func testRejectsExpiredCertificates() throws {
        let identity = try TestIdentity.make(expiresIn: -60)

        XCTAssertThrowsError(try PassSigner(certificate: identity.certificate, privateKey: identity.key)) {
            guard case .expired = $0 as? PassSigner.Failure else { return XCTFail("Expected .expired, got \($0)") }
        }
    }

    func testSignatureVerifiesAndCarriesTheAppleIntermediate() async throws {
        let identity = try TestIdentity.make()
        let signer = try PassSigner(certificate: identity.certificate, privateKey: identity.key)
        let manifest = Data(#"{"pass.json":"0000"}"#.utf8)

        let signature = try signer.signature(for: manifest)

        let result = await CMS.isValidSignature(
            dataBytes: manifest,
            signatureBytes: signature,
            trustRoots: CertificateStore([identity.certificate])
        ) {}
        guard case .success = result else { return XCTFail("Signature did not verify: \(result)") }

        let intermediate = try XCTUnwrap(PassSigner.appleIntermediateURL)
        XCTAssertNotNil(signature.range(of: try Data(contentsOf: intermediate)), "Wallet rejects passes without the WWDR certificate")
    }
}
