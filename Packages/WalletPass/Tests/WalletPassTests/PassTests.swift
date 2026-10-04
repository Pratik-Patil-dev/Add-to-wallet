import XCTest
@testable import WalletPass

final class PassTests: XCTestCase {
    func testEncodesFieldsUnderTheStyleKey() throws {
        var pass = Pass(
            serialNumber: "A1",
            organizationName: "Revolut",
            description: "Revolut Metal card",
            fields: PassFields(header: [PassField(key: "last4", label: "CARD", value: "•••• 4242")])
        )
        pass.backgroundColor = PassColor(hex: "#0B0F19")
        pass.passTypeIdentifier = "pass.com.example.cards"
        pass.teamIdentifier = "ABCDE12345"

        let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(pass)) as? [String: Any]

        XCTAssertEqual(json?["formatVersion"] as? Int, 1)
        XCTAssertEqual(json?["passTypeIdentifier"] as? String, "pass.com.example.cards")
        XCTAssertEqual(json?["backgroundColor"] as? String, "rgb(11, 15, 25)")
        XCTAssertNil(json?["logoText"])
        XCTAssertNil(json?["generic"])

        let storeCard = json?["storeCard"] as? [String: Any]
        let header = storeCard?["headerFields"] as? [[String: Any]]
        XCTAssertEqual(header?.first?["value"] as? String, "•••• 4242")
    }

    func testRejectsMalformedHex() {
        XCTAssertNil(PassColor(hex: "#12345"))
        XCTAssertNil(PassColor(hex: "zzzzzz"))
        XCTAssertEqual(PassColor(hex: "ffffff")?.cssValue, "rgb(255, 255, 255)")
    }
}
