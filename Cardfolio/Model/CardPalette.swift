import Foundation

struct CardPalette: Identifiable, Equatable {
    let name: String
    let startHex: String
    let endHex: String

    var id: String { name }

    static let `default` = all[0]

    static let all: [CardPalette] = [
        CardPalette(name: "Obsidian", startHex: "#2B2D31", endHex: "#0E0F11"),
        CardPalette(name: "Sapphire", startHex: "#2747A8", endHex: "#101B4A"),
        CardPalette(name: "Emerald", startHex: "#13866A", endHex: "#063B2E"),
        CardPalette(name: "Aubergine", startHex: "#6B2E6E", endHex: "#26102E"),
        CardPalette(name: "Crimson", startHex: "#B3263B", endHex: "#4C0A17"),
        CardPalette(name: "Copper", startHex: "#C27A4E", endHex: "#6E3B22"),
        CardPalette(name: "Ocean", startHex: "#1B8AA6", endHex: "#0B3B5A"),
        CardPalette(name: "Rosé", startHex: "#D9A0A6", endHex: "#9C5C68"),
        CardPalette(name: "Sand", startHex: "#EFE4CF", endHex: "#CDB892"),
        CardPalette(name: "Platinum", startHex: "#EEF0F3", endHex: "#A9AEB6"),
    ]
}

enum CardTexture: String, CaseIterable, Identifiable {
    case none
    case lines
    case rings
    case waves

    var id: Self { self }

    var title: String {
        switch self {
        case .none: "Plain"
        case .lines: "Lines"
        case .rings: "Rings"
        case .waves: "Waves"
        }
    }
}
