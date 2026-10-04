import Crypto
import Foundation

/// Everything that goes into a `.pkpass`: the pass itself plus its images.
public struct PassPackage {
    public var pass: Pass

    /// PNGs keyed by their file name in the bundle, e.g. `icon@2x.png`.
    public var images: [String: Data]

    public init(pass: Pass, images: [String: Data] = [:]) {
        self.pass = pass
        self.images = images
    }

    /// Builds the signed `.pkpass` archive that `PKPass(data:)` accepts.
    public func archive(signedBy signer: PassSigner, at date: Date = Date()) throws -> Data {
        var pass = pass
        pass.passTypeIdentifier = signer.passTypeIdentifier
        pass.teamIdentifier = signer.teamIdentifier

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]

        var files = images
        files["pass.json"] = try encoder.encode(pass)

        let manifest = try encoder.encode(files.mapValues { Insecure.SHA1.hash(data: $0).hex })
        let signature = try signer.signature(for: manifest, signedAt: date)

        var zip = ZipArchive(modified: date)
        for name in files.keys.sorted() {
            zip.add(name, data: files[name]!)
        }
        zip.add("manifest.json", data: manifest)
        zip.add("signature", data: signature)
        return zip.finalized()
    }
}

private extension Digest {
    var hex: String { map { String(format: "%02x", $0) }.joined() }
}
