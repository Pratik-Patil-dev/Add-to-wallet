import Foundation

/// A plain snapshot of everything that makes a card look the way it does.
///
/// The editor works on one of these so nothing touches the store until Save,
/// and the card face and Wallet pass are both drawn from it.
struct CardDesign: Equatable {
    var name = ""
    var issuer = ""
    var holderName = ""
    var lastFour = ""
    var expiryMonth: Int?
    var expiryYear: Int?
    var kind: CardKind = .credit
    var network: CardNetwork = .visa
    var startHex = CardPalette.default.startHex
    var endHex = CardPalette.default.endHex
    var texture: CardTexture = .none
    var notes = ""

    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { return trimmed }
        let issuer = issuer.trimmingCharacters(in: .whitespaces)
        return issuer.isEmpty ? "Untitled card" : issuer
    }

    var maskedNumber: String? {
        lastFour.count == 4 ? "•••• \(lastFour)" : nil
    }

    var expiry: String? {
        guard let expiryMonth, let expiryYear else { return nil }
        return String(format: "%02d/%02d", expiryMonth, expiryYear % 100)
    }

    var isExpired: Bool {
        guard let expiryMonth, let expiryYear else { return false }
        let now = Calendar.current.dateComponents([.year, .month], from: Date())
        guard let year = now.year, let month = now.month else { return false }
        return (expiryYear, expiryMonth) < (year, month)
    }

    var palette: CardPalette? {
        CardPalette.all.first { $0.startHex == startHex && $0.endHex == endHex }
    }

    /// Light cards (Sand, Platinum, custom pastels) need dark ink.
    var prefersDarkText: Bool {
        (HexColor(startHex).luminance + HexColor(endHex).luminance) / 2 > 0.6
    }

    mutating func apply(_ palette: CardPalette) {
        startHex = palette.startHex
        endHex = palette.endHex
    }
}
