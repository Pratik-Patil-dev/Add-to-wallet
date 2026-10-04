import SwiftUI

/// sRGB colour stored as `#RRGGBB`, which is what both SwiftData and
/// pass.json are happy to hold.
struct HexColor {
    var red: Double
    var green: Double
    var blue: Double

    init(_ hex: String) {
        let digits = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        let value = UInt32(digits, radix: 16) ?? 0
        red = Double((value >> 16) & 0xFF) / 255
        green = Double((value >> 8) & 0xFF) / 255
        blue = Double(value & 0xFF) / 255
    }

    init(_ color: Color) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        red = min(max(Double(r), 0), 1)
        green = min(max(Double(g), 0), 1)
        blue = min(max(Double(b), 0), 1)
    }

    var hex: String {
        String(format: "#%02X%02X%02X", channel(red), channel(green), channel(blue))
    }

    var color: Color { Color(.sRGB, red: red, green: green, blue: blue) }

    /// Relative luminance, good enough for picking light or dark text.
    var luminance: Double { 0.2126 * red + 0.7152 * green + 0.0722 * blue }

    private func channel(_ value: Double) -> Int {
        Int((value * 255).rounded())
    }

    func mixed(with other: HexColor, amount: Double) -> HexColor {
        var result = self
        result.red += (other.red - red) * amount
        result.green += (other.green - green) * amount
        result.blue += (other.blue - blue) * amount
        return result
    }
}

extension Color {
    init(hex: String) {
        self = HexColor(hex).color
    }
}
