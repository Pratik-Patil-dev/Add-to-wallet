import Foundation
import SwiftData

@Model
final class Card {
    /// Stays the same for the life of the card so Wallet treats re-adds as updates.
    var serialNumber: String = UUID().uuidString

    var name: String = ""
    var issuer: String = ""
    var holderName: String = ""
    var lastFour: String = ""
    var expiryMonth: Int?
    var expiryYear: Int?
    var kindID: String = CardKind.credit.rawValue
    var networkID: String = CardNetwork.visa.rawValue
    var startHex: String = CardPalette.default.startHex
    var endHex: String = CardPalette.default.endHex
    var textureID: String = CardTexture.none.rawValue
    var notes: String = ""

    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var addedToWalletAt: Date?

    /// True when the card was edited after its pass went into Wallet.
    var walletPassIsStale: Bool {
        guard let addedToWalletAt else { return false }
        return updatedAt > addedToWalletAt
    }

    init(design: CardDesign) {
        self.design = design
    }

    var design: CardDesign {
        get {
            CardDesign(
                name: name,
                issuer: issuer,
                holderName: holderName,
                lastFour: lastFour,
                expiryMonth: expiryMonth,
                expiryYear: expiryYear,
                kind: CardKind(rawValue: kindID) ?? .other,
                network: CardNetwork(rawValue: networkID) ?? .none,
                startHex: startHex,
                endHex: endHex,
                texture: CardTexture(rawValue: textureID) ?? .none,
                notes: notes
            )
        }
        set {
            name = newValue.name
            issuer = newValue.issuer
            holderName = newValue.holderName
            lastFour = newValue.lastFour
            expiryMonth = newValue.expiryMonth
            expiryYear = newValue.expiryYear
            kindID = newValue.kind.rawValue
            networkID = newValue.network.rawValue
            startHex = newValue.startHex
            endHex = newValue.endHex
            textureID = newValue.texture.rawValue
            notes = newValue.notes
        }
    }
}
