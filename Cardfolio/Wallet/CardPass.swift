import PassKit
import SwiftUI
import WalletPass

/// Turns a card into a signed Wallet pass.
///
/// It's a store card pass: the card's colours become the pass background,
/// a banner drawn from the card design becomes the strip, and the details
/// you entered fill the fields around it.
@MainActor
enum CardPass {
    static func make(for card: Card, signedBy signer: PassSigner) throws -> PKPass {
        let design = card.design
        let package = PassPackage(
            pass: pass(for: design, serialNumber: card.serialNumber),
            images: artwork(for: design)
        )
        return try PKPass(data: package.archive(signedBy: signer))
    }

    static func pass(for design: CardDesign, serialNumber: String) -> Pass {
        let issuer = design.issuer.trimmingCharacters(in: .whitespaces)
        let holder = design.holderName.trimmingCharacters(in: .whitespaces)

        var fields = PassFields()

        if let number = design.maskedNumber {
            fields.headerFields = [PassField(key: "number", label: design.kind.title.uppercased(), value: number)]
        } else {
            fields.headerFields = [PassField(key: "kind", label: "TYPE", value: design.kind.title)]
        }

        let showsIssuerAbove = !issuer.isEmpty && issuer != design.displayName
        fields.primaryFields = [
            PassField(key: "name", label: showsIssuerAbove ? issuer.uppercased() : nil, value: design.displayName),
        ]

        if !holder.isEmpty {
            fields.secondaryFields.append(PassField(key: "holder", label: "CARDHOLDER", value: holder.uppercased()))
        }
        if let expiry = design.expiry {
            fields.secondaryFields.append(PassField(key: "expiry", label: "EXPIRES", value: expiry))
        }
        if design.network != .none {
            fields.auxiliaryFields.append(
                PassField(key: "network", label: "NETWORK", value: design.network.title, alignment: .right)
            )
        }

        if !design.notes.isEmpty {
            fields.backFields.append(PassField(key: "notes", label: "Notes", value: design.notes))
        }
        if !issuer.isEmpty {
            fields.backFields.append(PassField(key: "issuer", label: "Issuer", value: issuer))
        }
        fields.backFields.append(
            PassField(
                key: "about",
                label: "About this pass",
                value: "Made with Cardfolio as a reminder of a card you carry. It can't be used to pay."
            )
        )

        var pass = Pass(
            serialNumber: serialNumber,
            organizationName: issuer.isEmpty ? "Cardfolio" : issuer,
            description: "\(design.displayName) card",
            style: .storeCard,
            fields: fields
        )
        pass.logoText = issuer.isEmpty ? design.kind.title : issuer
        pass.sharingProhibited = true

        let colors = PassColors(design: design)
        pass.backgroundColor = colors.background
        pass.foregroundColor = colors.foreground
        pass.labelColor = colors.label
        return pass
    }

    // MARK: - Artwork

    private static let iconSize = CGSize(width: 29, height: 29)
    private static let stripSize = CGSize(width: 375, height: 144)

    static func artwork(for design: CardDesign) -> [String: Data] {
        var images: [String: Data] = [:]
        for scale in [1, 2, 3] {
            let suffix = scale == 1 ? "" : "@\(scale)x"
            images["icon\(suffix).png"] = render(PassIconView(design: design), size: iconSize, scale: CGFloat(scale))
            images["strip\(suffix).png"] = render(PassStripView(design: design), size: stripSize, scale: CGFloat(scale))
        }
        return images
    }

    private static func render(_ view: some View, size: CGSize, scale: CGFloat) -> Data? {
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
        renderer.scale = scale
        renderer.isOpaque = true
        return renderer.uiImage?.pngData()
    }
}

private struct PassColors {
    let background: PassColor
    let foreground: PassColor
    let label: PassColor

    init(design: CardDesign) {
        let base = HexColor(design.startHex).mixed(with: HexColor(design.endHex), amount: 0.5)
        let ink = HexColor(design.prefersDarkText ? "#1F1F1F" : "#FFFFFF")

        background = PassColor(base)
        foreground = PassColor(ink)
        label = PassColor(ink.mixed(with: base, amount: 0.35))
    }
}

private extension PassColor {
    init(_ color: HexColor) {
        self.init(
            red: UInt8((color.red * 255).rounded()),
            green: UInt8((color.green * 255).rounded()),
            blue: UInt8((color.blue * 255).rounded())
        )
    }
}

/// The banner behind the card name in Wallet. No text here; Wallet draws
/// the fields over it.
private struct PassStripView: View {
    let design: CardDesign

    var body: some View {
        ZStack {
            CardBackground(design: design)
            HStack {
                Spacer()
                VStack(alignment: .trailing) {
                    if design.kind.isPaymentCard {
                        Image(systemName: "wave.3.right")
                            .font(.system(size: 15, weight: .medium))
                            .opacity(0.75)
                    }
                    Spacer()
                    NetworkMark(network: design.network, scale: 0.9)
                }
            }
            .padding(16)
        }
        .foregroundStyle(design.prefersDarkText ? Color(white: 0.12) : .white)
    }
}

/// Shown on the lock screen and in notifications.
private struct PassIconView: View {
    let design: CardDesign

    var body: some View {
        ZStack {
            CardBackground(design: design, scale: 0.3)
            Image(systemName: design.kind.symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(design.prefersDarkText ? Color(white: 0.12) : .white)
        }
    }
}
