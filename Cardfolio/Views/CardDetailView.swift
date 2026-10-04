import PassKit
import SwiftData
import SwiftUI

struct CardDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(PassSigningStore.self) private var signing

    let card: Card

    @State private var isEditing = false
    @State private var isConfirmingDelete = false
    @State private var isDeleting = false
    @State private var pendingPass: PendingPass?
    @State private var isShowingSigningSetup = false
    @State private var isShowingSettings = false
    @State private var walletError: String?

    var body: some View {
        let design = card.design

        List {
            Section {
                CardFaceView(design: design)
                    .shadow(color: .black.opacity(0.25), radius: 22, y: 12)
                    .padding(.vertical, 8)
                    .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                    .listRowBackground(Color.clear)
            }

            Section {
                AddToWalletButton(action: addToWallet)
                    .frame(height: 50)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            } footer: {
                Text(walletStatus)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }

            Section {
                LabeledContent("Type", value: design.kind.title)
                if design.network != .none {
                    LabeledContent("Network", value: design.network.title)
                }
                if !design.issuer.isEmpty {
                    LabeledContent("Issuer", value: design.issuer)
                }
                if !design.lastFour.isEmpty {
                    LabeledContent("Ends in", value: design.lastFour)
                }
                if !design.holderName.isEmpty {
                    LabeledContent("Name on card", value: design.holderName)
                }
                if let month = design.expiryMonth, let year = design.expiryYear {
                    LabeledContent("Expires") {
                        HStack(spacing: 6) {
                            if design.isExpired {
                                Text("Expired").foregroundStyle(.red)
                                Text("·").foregroundStyle(.tertiary)
                            }
                            Text(String(format: "%02d/%d", month, year)).monospacedDigit()
                        }
                    }
                }
                LabeledContent("Added", value: card.createdAt.formatted(date: .abbreviated, time: .omitted))
            }

            if !design.notes.isEmpty {
                Section("Notes") {
                    Text(design.notes)
                        .textSelection(.enabled)
                }
            }

            Section {
                Button("Delete Card", role: .destructive) {
                    isConfirmingDelete = true
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(design.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Edit") { isEditing = true }
        }
        .sheet(isPresented: $isEditing) {
            CardEditorView(card: card)
        }
        .sheet(item: $pendingPass) { pending in
            AddPassSheet(pending: pending) { added in
                if added { card.addedToWalletAt = Date() }
                pendingPass = nil
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
        .alert("Set Up Wallet Signing", isPresented: $isShowingSigningSetup) {
            Button("Not Now", role: .cancel) {}
            Button("Open Settings") { isShowingSettings = true }
        } message: {
            Text("Wallet needs passes signed with your Pass Type ID certificate. Import it once in Settings and every card can go into Wallet.")
        }
        .alert("Couldn't Add to Wallet", isPresented: isShowingWalletError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(walletError ?? "")
        }
        .sensoryFeedback(.success, trigger: card.addedToWalletAt)
        .confirmationDialog("Delete this card?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete Card", role: .destructive) {
                isDeleting = true
                dismiss()
            }
        } message: {
            Text("This removes it from Cardfolio. If it's in Apple Wallet, delete it there too.")
        }
        .onDisappear {
            // Deleting while this screen is still on show would have it read a dead model.
            if isDeleting { context.delete(card) }
        }
    }

    private var walletStatus: String {
        if card.walletPassIsStale {
            return "Edited since you added it. Add it again to update the pass in Wallet."
        }
        if let added = card.addedToWalletAt {
            return "In Wallet since \(added.formatted(date: .abbreviated, time: .omitted))."
        }
        return "A pass you can pull up in Wallet to remember this card. It can't be used to pay."
    }

    private var isShowingWalletError: Binding<Bool> {
        Binding(get: { walletError != nil }, set: { if !$0 { walletError = nil } })
    }

    private func addToWallet() {
        guard PKAddPassesViewController.canAddPasses() else {
            walletError = "This device can't add passes to Wallet."
            return
        }
        guard let signer = signing.signer else {
            isShowingSigningSetup = true
            return
        }
        do {
            let pass = try CardPass.make(for: card, signedBy: signer)
            guard let pending = PendingPass(pass) else {
                walletError = "Wallet wouldn't open this pass."
                return
            }
            pendingPass = pending
        } catch {
            walletError = error.localizedDescription
        }
    }
}
