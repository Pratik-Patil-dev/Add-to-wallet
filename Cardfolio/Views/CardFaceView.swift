import SwiftUI

/// The card as it looks in your hand. Everything is laid out on a 340pt
/// wide canvas and scaled, so a thumbnail and a full-width card match.
struct CardFaceView: View {
    static let aspectRatio: CGFloat = 1.586

    let design: CardDesign

    var body: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / 340
            let shape = RoundedRectangle(cornerRadius: 16 * scale, style: .continuous)

            ZStack {
                CardBackground(design: design, scale: scale)
                details(scale: scale)
                    .padding(20 * scale)
            }
            .foregroundStyle(ink)
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(.white.opacity(design.prefersDarkText ? 0.5 : 0.12), lineWidth: max(scale, 0.5))
            }
        }
        .aspectRatio(Self.aspectRatio, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    private var ink: Color {
        design.prefersDarkText ? Color(white: 0.12) : .white
    }

    private var title: String {
        let issuer = design.issuer.trimmingCharacters(in: .whitespaces)
        return issuer.isEmpty ? design.displayName : issuer
    }

    /// The nickname only earns a line when it says something the issuer doesn't.
    private var subtitle: String? {
        let name = design.name.trimmingCharacters(in: .whitespaces)
        return name.isEmpty || name == title ? nil : name
    }

    private func details(scale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2 * scale) {
                    Text(title)
                        .font(.system(size: 17 * scale, weight: .semibold))
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 11 * scale, weight: .medium))
                            .opacity(0.7)
                    }
                }
                .lineLimit(1)

                Spacer(minLength: 12 * scale)

                Text(design.kind.title.uppercased())
                    .font(.system(size: 9 * scale, weight: .semibold))
                    .tracking(1.4 * scale)
                    .opacity(0.65)
            }

            Spacer(minLength: 0)

            if design.kind.isPaymentCard {
                HStack(spacing: 12 * scale) {
                    ChipView(scale: scale)
                        .frame(width: 38 * scale, height: 29 * scale)
                    Image(systemName: "wave.3.right")
                        .font(.system(size: 16 * scale, weight: .medium))
                        .opacity(0.75)
                }
                Spacer(minLength: 0)
            }

            HStack(alignment: .bottom, spacing: 12 * scale) {
                VStack(alignment: .leading, spacing: 7 * scale) {
                    if let number = design.maskedNumber {
                        Text(number)
                            .font(.system(size: 20 * scale, weight: .medium).monospacedDigit())
                            .tracking(2 * scale)
                    }
                    footnote(scale: scale)
                }
                .lineLimit(1)

                Spacer(minLength: 0)

                NetworkMark(network: design.network, scale: scale)
            }
        }
    }

    @ViewBuilder
    private func footnote(scale: CGFloat) -> some View {
        let holder = design.holderName.trimmingCharacters(in: .whitespaces)
        if !holder.isEmpty || design.expiry != nil {
            HStack(spacing: 14 * scale) {
                if !holder.isEmpty {
                    Text(holder.uppercased())
                }
                if let expiry = design.expiry {
                    Text(expiry)
                        .monospacedDigit()
                        .strikethrough(design.isExpired)
                }
            }
            .font(.system(size: 11 * scale, weight: .medium))
            .tracking(1.2 * scale)
            .opacity(0.8)
        }
    }

    private var accessibilityDescription: String {
        var parts = [design.displayName, design.kind.title]
        if design.network != .none { parts.append(design.network.title) }
        if !design.lastFour.isEmpty { parts.append("ending in \(design.lastFour)") }
        return parts.joined(separator: ", ")
    }
}

struct CardBackground: View {
    let design: CardDesign
    var scale: CGFloat = 1

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: design.startHex), Color(hex: design.endHex)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            CardTextureView(texture: design.texture, scale: scale)
                .foregroundStyle(design.prefersDarkText ? Color.black.opacity(0.07) : Color.white.opacity(0.08))

            // A soft light falling from the top-left corner.
            GeometryReader { proxy in
                RadialGradient(
                    colors: [.white.opacity(0.2), .white.opacity(0)],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: proxy.size.width
                )
            }
            .blendMode(.softLight)
        }
    }
}

struct CardTextureView: View {
    let texture: CardTexture
    var scale: CGFloat = 1

    var body: some View {
        Canvas { context, size in
            var path = Path()
            switch texture {
            case .none:
                return
            case .lines:
                let step = 7 * scale
                var x = -size.height
                while x < size.width {
                    path.move(to: CGPoint(x: x, y: size.height))
                    path.addLine(to: CGPoint(x: x + size.height, y: 0))
                    x += step
                }
            case .rings:
                let center = CGPoint(x: size.width * 1.02, y: size.height * 1.15)
                var radius = 12 * scale
                while radius < size.width * 1.4 {
                    path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
                    radius += 9 * scale
                }
            case .waves:
                let amplitude = 7 * scale
                let wavelength = size.width / 1.6
                var y = -amplitude
                while y < size.height + amplitude {
                    path.move(to: CGPoint(x: 0, y: y))
                    for x in stride(from: 0, through: size.width, by: 4) {
                        path.addLine(to: CGPoint(x: x, y: y + sin(x / wavelength * .pi * 2) * amplitude))
                    }
                    y += 10 * scale
                }
            }
            context.stroke(path, with: .foreground, lineWidth: 0.8 * scale)
        }
    }
}

struct ChipView: View {
    var scale: CGFloat = 1

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 5 * scale, style: .continuous)
        shape
            .fill(
                LinearGradient(
                    colors: [Color(hex: "#EBD6A6"), Color(hex: "#B8955A"), Color(hex: "#E2C68E")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Canvas { context, size in
                    var path = Path()
                    for fraction in [1.0 / 3, 2.0 / 3] {
                        path.move(to: CGPoint(x: 0, y: size.height * fraction))
                        path.addLine(to: CGPoint(x: size.width, y: size.height * fraction))
                    }
                    path.move(to: CGPoint(x: size.width / 2, y: 0))
                    path.addLine(to: CGPoint(x: size.width / 2, y: size.height / 3))
                    path.move(to: CGPoint(x: size.width / 2, y: size.height * 2 / 3))
                    path.addLine(to: CGPoint(x: size.width / 2, y: size.height))
                    path.addRoundedRect(
                        in: CGRect(x: size.width * 0.3, y: size.height / 3, width: size.width * 0.4, height: size.height / 3),
                        cornerSize: CGSize(width: 2 * scale, height: 2 * scale)
                    )
                    context.stroke(path, with: .color(.black.opacity(0.28)), lineWidth: 0.7 * scale)
                }
            }
            .clipShape(shape)
    }
}

#Preview {
    VStack(spacing: 20) {
        CardFaceView(design: CardDesign(
            name: "Metal", issuer: "Revolut", holderName: "Pratik Patil", lastFour: "4242",
            expiryMonth: 9, expiryYear: 2029, network: .visa, texture: .rings
        ))
        CardFaceView(design: CardDesign(
            name: "Tesco Clubcard", lastFour: "", kind: .loyalty, network: .none,
            startHex: "#EFE4CF", endHex: "#CDB892", texture: .waves
        ))
    }
    .padding()
}
