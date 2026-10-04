import XCTest
@testable import WalletPass

final class ZipArchiveTests: XCTestCase {
    func testChecksumMatchesKnownValue() {
        XCTAssertEqual(CRC32.checksum(Data("123456789".utf8)), 0xCBF4_3926)
        XCTAssertEqual(CRC32.checksum(Data()), 0)
    }

    func testEntriesCanBeReadBack() throws {
        var zip = ZipArchive()
        zip.add("pass.json", data: Data("{}".utf8))
        zip.add("icon.png", data: Data([0x89, 0x50, 0x4E, 0x47]))

        let entries = try ZipReader.entries(in: zip.finalized())

        XCTAssertEqual(entries.map(\.name), ["pass.json", "icon.png"])
        XCTAssertEqual(entries.first?.data, Data("{}".utf8))
        XCTAssertEqual(entries.last?.data, Data([0x89, 0x50, 0x4E, 0x47]))
    }
}

/// Walks the central directory the same way unzip does, so the tests catch
/// offset or size mistakes rather than just round-tripping our own writer.
enum ZipReader {
    struct Entry {
        let name: String
        let data: Data
    }

    struct Malformed: Error {}

    static func entries(in archive: Data) throws -> [Entry] {
        let bytes = [UInt8](archive)
        guard bytes.count >= 22, bytes.u32(bytes.count - 22) == 0x0605_4B50 else { throw Malformed() }

        let eocd = bytes.count - 22
        let count = Int(bytes.u16(eocd + 10))
        var cursor = Int(bytes.u32(eocd + 16))
        var result: [Entry] = []

        for _ in 0..<count {
            guard bytes.u32(cursor) == 0x0201_4B50 else { throw Malformed() }
            let crc = bytes.u32(cursor + 16)
            let size = Int(bytes.u32(cursor + 24))
            let nameLength = Int(bytes.u16(cursor + 28))
            let headerOffset = Int(bytes.u32(cursor + 42))
            let name = String(decoding: bytes[(cursor + 46)..<(cursor + 46 + nameLength)], as: UTF8.self)

            guard bytes.u32(headerOffset) == 0x0403_4B50 else { throw Malformed() }
            let dataStart = headerOffset + 30 + Int(bytes.u16(headerOffset + 26)) + Int(bytes.u16(headerOffset + 28))
            let data = Data(bytes[dataStart..<(dataStart + size)])
            guard CRC32.checksum(data) == crc else { throw Malformed() }

            result.append(Entry(name: name, data: data))
            cursor += 46 + nameLength
        }
        return result
    }
}

private extension Array where Element == UInt8 {
    func u16(_ offset: Int) -> UInt16 {
        UInt16(self[offset]) | UInt16(self[offset + 1]) << 8
    }

    func u32(_ offset: Int) -> UInt32 {
        UInt32(u16(offset)) | UInt32(u16(offset + 2)) << 16
    }
}
