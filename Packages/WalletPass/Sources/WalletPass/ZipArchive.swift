import Foundation

/// Just enough of the ZIP format to build a `.pkpass`.
///
/// Entries are stored uncompressed. Pass bundles are mostly PNGs, which are
/// already compressed, so deflate would buy almost nothing here.
struct ZipArchive {
    private struct Entry {
        let name: [UInt8]
        let crc: UInt32
        let size: UInt32
        let offset: UInt32
    }

    private var body = Data()
    private var entries: [Entry] = []
    private let time: UInt16
    private let date: UInt16

    init(modified: Date = Date()) {
        (time, date) = Self.dosTimestamp(for: modified)
    }

    mutating func add(_ name: String, data: Data) {
        let entry = Entry(
            name: Array(name.utf8),
            crc: CRC32.checksum(data),
            size: UInt32(data.count),
            offset: UInt32(body.count)
        )

        body.append(le32: 0x0403_4B50)
        body.append(le16: 20) // version needed to extract
        body.append(le16: 0)  // flags
        body.append(le16: 0)  // method: stored
        body.append(le16: time)
        body.append(le16: date)
        body.append(le32: entry.crc)
        body.append(le32: entry.size) // compressed size
        body.append(le32: entry.size) // uncompressed size
        body.append(le16: UInt16(entry.name.count))
        body.append(le16: 0)  // extra field length
        body.append(contentsOf: entry.name)
        body.append(data)

        entries.append(entry)
    }

    func finalized() -> Data {
        var archive = body
        let directoryOffset = UInt32(archive.count)

        for entry in entries {
            archive.append(le32: 0x0201_4B50)
            archive.append(le16: 20) // version made by
            archive.append(le16: 20) // version needed to extract
            archive.append(le16: 0)
            archive.append(le16: 0)
            archive.append(le16: time)
            archive.append(le16: date)
            archive.append(le32: entry.crc)
            archive.append(le32: entry.size)
            archive.append(le32: entry.size)
            archive.append(le16: UInt16(entry.name.count))
            archive.append(le16: 0) // extra field length
            archive.append(le16: 0) // comment length
            archive.append(le16: 0) // disk number
            archive.append(le16: 0) // internal attributes
            archive.append(le32: 0) // external attributes
            archive.append(le32: entry.offset)
            archive.append(contentsOf: entry.name)
        }

        let directorySize = UInt32(archive.count) - directoryOffset

        archive.append(le32: 0x0605_4B50)
        archive.append(le16: 0)
        archive.append(le16: 0)
        archive.append(le16: UInt16(entries.count))
        archive.append(le16: UInt16(entries.count))
        archive.append(le32: directorySize)
        archive.append(le32: directoryOffset)
        archive.append(le16: 0) // comment length

        return archive
    }

    private static func dosTimestamp(for date: Date) -> (time: UInt16, date: UInt16) {
        let parts = Calendar(identifier: .gregorian).dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: date
        )
        let year = max((parts.year ?? 1980) - 1980, 0)
        let time = (parts.hour ?? 0) << 11 | (parts.minute ?? 0) << 5 | (parts.second ?? 0) / 2
        let day = year << 9 | (parts.month ?? 1) << 5 | (parts.day ?? 1)
        return (UInt16(time), UInt16(day))
    }
}

enum CRC32 {
    private static let table: [UInt32] = (0..<256).map { index in
        var value = UInt32(index)
        for _ in 0..<8 {
            value = value & 1 == 1 ? 0xEDB8_8320 ^ (value >> 1) : value >> 1
        }
        return value
    }

    static func checksum(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in data {
            crc = table[Int((crc ^ UInt32(byte)) & 0xFF)] ^ (crc >> 8)
        }
        return crc ^ 0xFFFF_FFFF
    }
}

private extension Data {
    mutating func append(le16 value: UInt16) {
        Swift.withUnsafeBytes(of: value.littleEndian) { append(contentsOf: $0) }
    }

    mutating func append(le32 value: UInt32) {
        Swift.withUnsafeBytes(of: value.littleEndian) { append(contentsOf: $0) }
    }
}
