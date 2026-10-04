import SwiftData
import SwiftUI

struct CardDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let card: Card

    @State private var isEditing = false
    @State private var isConfirmingDelete = false
    @State private var isDeleting = false

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
}
