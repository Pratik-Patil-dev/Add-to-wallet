import SwiftUI

/// A simple typographic nod to each card network. Not the official artwork,
/// just enough to tell cards apart at a glance.
struct NetworkMark: View {
    let network: CardNetwork
    var scale: CGFloat = 1

    var body: some View {
        switch network {
        case .visa:
            Text("VISA")
                .font(.system(size: 24 * scale, weight: .black))
                .italic()
                .tracking(-0.5 * scale)
        case .mastercard:
            InterlockingCircles(left: Color(hex: "#EB001B"), right: Color(hex: "#F79E1B"), scale: scale)
        case .maestro:
            InterlockingCircles(left: Color(hex: "#ED0006"), right: Color(hex: "#0099DF"), scale: scale)
        case .amex:
            Text("AMEX")
                .font(.system(size: 12 * scale, weight: .heavy))
                .tracking(1.5 * scale)
                .padding(.horizontal, 6 * scale)
                .padding(.vertical, 4 * scale)
                .overlay {
                    RoundedRectangle(cornerRadius: 3 * scale)
                        .strokeBorder(lineWidth: 1.2 * scale)
                }
        case .discover:
            Text("DISCOVER")
                .font(.system(size: 13 * scale, weight: .bold))
                .tracking(0.6 * scale)
        case .rupay:
            Text("RuPay")
                .font(.system(size: 19 * scale, weight: .heavy))
                .italic()
        case .none:
            EmptyView()
        }
    }
}

private struct InterlockingCircles: View {
    let left: Color
    let right: Color
    let scale: CGFloat

    var body: some View {
        let size = 26 * scale
        ZStack {
            Circle().fill(left).frame(width: size).offset(x: -size * 0.3)
            Circle().fill(right.opacity(0.9)).frame(width: size).offset(x: size * 0.3)
        }
        .frame(width: size * 1.6, height: size)
    }
}
