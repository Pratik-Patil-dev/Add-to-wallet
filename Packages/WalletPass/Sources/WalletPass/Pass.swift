import Foundation

/// The contents of `pass.json`, trimmed down to what Cardfolio actually uses.
///
/// Field reference: https://developer.apple.com/documentation/walletpasses/pass
public struct Pass: Encodable, Equatable {
    public enum Style: String {
        case generic
        case storeCard
    }

    public var formatVersion = 1
    public var serialNumber: String
    public var organizationName: String
    public var description: String
    public var logoText: String?

    public var foregroundColor: PassColor?
    public var backgroundColor: PassColor?
    public var labelColor: PassColor?

    /// Hides the share button on the back of the pass.
    public var sharingProhibited: Bool?

    public var style: Style
    public var fields: PassFields

    /// Filled in from the signing certificate when the pass is packaged.
    var passTypeIdentifier = ""
    var teamIdentifier = ""

    public init(
        serialNumber: String,
        organizationName: String,
        description: String,
        style: Style = .storeCard,
        fields: PassFields = PassFields()
    ) {
        self.serialNumber = serialNumber
        self.organizationName = organizationName
        self.description = description
        self.style = style
        self.fields = fields
    }

    private enum CodingKeys: String, CodingKey {
        case formatVersion, serialNumber, organizationName, description, logoText
        case foregroundColor, backgroundColor, labelColor
        case sharingProhibited, passTypeIdentifier, teamIdentifier
        case generic, storeCard
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(formatVersion, forKey: .formatVersion)
        try container.encode(passTypeIdentifier, forKey: .passTypeIdentifier)
        try container.encode(teamIdentifier, forKey: .teamIdentifier)
        try container.encode(serialNumber, forKey: .serialNumber)
        try container.encode(organizationName, forKey: .organizationName)
        try container.encode(description, forKey: .description)
        try container.encodeIfPresent(logoText, forKey: .logoText)
        try container.encodeIfPresent(foregroundColor, forKey: .foregroundColor)
        try container.encodeIfPresent(backgroundColor, forKey: .backgroundColor)
        try container.encodeIfPresent(labelColor, forKey: .labelColor)
        try container.encodeIfPresent(sharingProhibited, forKey: .sharingProhibited)

        switch style {
        case .generic: try container.encode(fields, forKey: .generic)
        case .storeCard: try container.encode(fields, forKey: .storeCard)
        }
    }
}

public struct PassFields: Encodable, Equatable {
    public var headerFields: [PassField] = []
    public var primaryFields: [PassField] = []
    public var secondaryFields: [PassField] = []
    public var auxiliaryFields: [PassField] = []
    public var backFields: [PassField] = []

    public init(
        header: [PassField] = [],
        primary: [PassField] = [],
        secondary: [PassField] = [],
        auxiliary: [PassField] = [],
        back: [PassField] = []
    ) {
        headerFields = header
        primaryFields = primary
        secondaryFields = secondary
        auxiliaryFields = auxiliary
        backFields = back
    }
}

public struct PassField: Encodable, Equatable {
    public enum Alignment: String, Encodable {
        case left = "PKTextAlignmentLeft"
        case center = "PKTextAlignmentCenter"
        case right = "PKTextAlignmentRight"
        case natural = "PKTextAlignmentNatural"
    }

    public var key: String
    public var label: String?
    public var value: String
    public var textAlignment: Alignment?

    public init(key: String, label: String? = nil, value: String, alignment: Alignment? = nil) {
        self.key = key
        self.label = label
        self.value = value
        self.textAlignment = alignment
    }
}

/// Wallet wants colours as CSS-style `rgb(r, g, b)` strings.
public struct PassColor: Encodable, Equatable {
    public var red: UInt8
    public var green: UInt8
    public var blue: UInt8

    public init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    /// Accepts `#RRGGBB` or `RRGGBB`.
    public init?(hex: String) {
        let digits = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard digits.count == 6, let value = UInt32(digits, radix: 16) else { return nil }
        red = UInt8((value >> 16) & 0xFF)
        green = UInt8((value >> 8) & 0xFF)
        blue = UInt8(value & 0xFF)
    }

    public var cssValue: String { "rgb(\(red), \(green), \(blue))" }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(cssValue)
    }
}
