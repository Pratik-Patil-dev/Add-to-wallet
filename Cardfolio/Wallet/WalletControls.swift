import PassKit
import SwiftUI

/// Apple's own "Add to Apple Wallet" button. The guidelines ask for this
/// exact artwork rather than a homemade one.
struct AddToWalletButton: UIViewRepresentable {
    @Environment(\.colorScheme) private var colorScheme
    let action: () -> Void

    func makeUIView(context: Context) -> PKAddPassButton {
        let button = PKAddPassButton(addPassButtonStyle: style)
        button.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)
        return button
    }

    func updateUIView(_ button: PKAddPassButton, context: Context) {
        button.addPassButtonStyle = style
        context.coordinator.action = action
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    private var style: PKAddPassButtonStyle {
        colorScheme == .dark ? .blackOutline : .black
    }

    final class Coordinator: NSObject {
        var action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func tapped() {
            action()
        }
    }
}

/// A pass waiting to be shown in Wallet's own add sheet.
struct PendingPass: Identifiable {
    let id = UUID()
    let pass: PKPass
    let controller: PKAddPassesViewController

    init?(_ pass: PKPass) {
        guard let controller = PKAddPassesViewController(pass: pass) else { return nil }
        self.pass = pass
        self.controller = controller
    }
}

struct AddPassSheet: UIViewControllerRepresentable {
    let pending: PendingPass
    let onFinish: (_ added: Bool) -> Void

    func makeUIViewController(context: Context) -> PKAddPassesViewController {
        pending.controller.delegate = context.coordinator
        return pending.controller
    }

    func updateUIViewController(_ controller: PKAddPassesViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(pass: pending.pass, onFinish: onFinish)
    }

    final class Coordinator: NSObject, PKAddPassesViewControllerDelegate {
        let pass: PKPass
        let onFinish: (Bool) -> Void

        init(pass: PKPass, onFinish: @escaping (Bool) -> Void) {
            self.pass = pass
            self.onFinish = onFinish
        }

        func addPassesViewControllerDidFinish(_ controller: PKAddPassesViewController) {
            onFinish(PKPassLibrary().containsPass(pass))
        }
    }
}
