import SwiftData
import SwiftUI

struct CardListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Card.createdAt) private var cards: [Card]

    @State private var isAddingCard = false
    @State private var editingCard: Card?

    var body: some View {
        NavigationStack {
            Group {
                if cards.isEmpty {
                    EmptyCardsView { isAddingCard = true }
                } else {
                    CardStack(cards: cards, edit: { editingCard = $0 }, delete: delete)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Cards")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAddingCard = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Card")
                }
            }
            .sheet(isPresented: $isAddingCard) {
                CardEditorView()
            }
            .sheet(item: $editingCard) { card in
                CardEditorView(card: card)
            }
        }
    }

    private func delete(_ card: Card) {
        withAnimation(.smooth) {
            context.delete(card)
        }
    }
}

/// Cards overlap like they do in Wallet: each one shows its top edge and the
/// newest sits in front, fully visible.
private struct CardStack: View {
    let cards: [Card]
    let edit: (Card) -> Void
    let delete: (Card) -> Void

    private let peek: CGFloat = 64

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width - 40, 0)
            let height = width / CardFaceView.aspectRatio

            ScrollView {
                VStack(spacing: -(height - peek)) {
                    ForEach(cards) { card in
                        CardFaceView(design: card.design)
                            .frame(width: width, height: height)
                            .shadow(color: .black.opacity(0.16), radius: 10, y: -2)
                            .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .contextMenu {
                                Button("Edit", systemImage: "pencil") { edit(card) }
                                Button("Delete", systemImage: "trash", role: .destructive) { delete(card) }
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.top, 12)

                summary
                    .padding(.top, 28)
                    .padding(.bottom, 40)
            }
        }
    }

    private var summary: some View {
        let inWallet = cards.filter { $0.addedToWalletAt != nil }.count
        var text = cards.count == 1 ? "1 card" : "\(cards.count) cards"
        if inWallet > 0 { text += " · \(inWallet) in Wallet" }
        return Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}

private struct EmptyCardsView: View {
    let addCard: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 6]))
                    .foregroundStyle(.tertiary)
                Image(systemName: "creditcard")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(.secondary)
            }
            .aspectRatio(CardFaceView.aspectRatio, contentMode: .fit)
            .frame(maxWidth: 240)

            VStack(spacing: 8) {
                Text("No cards yet")
                    .font(.title3.weight(.semibold))
                Text("Recreate the cards you carry, then keep them in Apple Wallet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("Add a Card", action: addCard)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(40)
    }
}

#Preview {
    CardListView()
        .modelContainer(for: Card.self, inMemory: true)
}
