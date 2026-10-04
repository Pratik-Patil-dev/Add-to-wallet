import SwiftData
import SwiftUI

struct CardEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    private let card: Card?
    @State private var draft: CardDesign

    init(card: Card? = nil) {
        self.card = card
        _draft = State(initialValue: card?.design ?? CardDesign())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Card") {
                    TextField("Nickname", text: $draft.name, prompt: Text("Everyday spending"))
                    TextField("Issuer", text: $draft.issuer, prompt: Text("Bank or brand"))
                    Picker("Type", selection: $draft.kind) {
                        ForEach(CardKind.allCases) { kind in
                            Label(kind.title, systemImage: kind.symbol).tag(kind)
                        }
                    }
                    Picker("Network", selection: $draft.network) {
                        ForEach(CardNetwork.allCases) { network in
                            Text(network.title).tag(network)
                        }
                    }
                }

                Section {
                    TextField("Last four digits", text: lastFour, prompt: Text("4242"))
                        .keyboardType(.numberPad)
                    TextField("Name on card", text: $draft.holderName)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    ExpiryPicker(month: $draft.expiryMonth, year: $draft.expiryYear)
                } header: {
                    Text("Details")
                } footer: {
                    Text("Only the last four digits are kept. Never store a full card number or security code.")
                }

                Section("Look") {
                    PalettePicker(design: $draft)
                    ColorPicker("Top colour", selection: color(\.startHex), supportsOpacity: false)
                    ColorPicker("Bottom colour", selection: color(\.endHex), supportsOpacity: false)
                    Picker("Texture", selection: $draft.texture) {
                        ForEach(CardTexture.allCases) { texture in
                            Text(texture.title).tag(texture)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Notes") {
                    TextField("Notes", text: $draft.notes, prompt: Text("Rewards, limits, when to use it…"), axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                CardFaceView(design: draft)
                    .frame(maxWidth: 280)
                    .shadow(color: .black.opacity(0.2), radius: 14, y: 8)
                    .animation(.smooth, value: draft)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(.bar)
            }
            .navigationTitle(card == nil ? "New Card" : "Edit Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        !draft.name.trimmingCharacters(in: .whitespaces).isEmpty
            || !draft.issuer.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var lastFour: Binding<String> {
        Binding(
            get: { draft.lastFour },
            set: { draft.lastFour = String($0.filter { $0.isASCII && $0.isNumber }.prefix(4)) }
        )
    }

    private func color(_ keyPath: WritableKeyPath<CardDesign, String>) -> Binding<Color> {
        Binding(
            get: { Color(hex: draft[keyPath: keyPath]) },
            set: { draft[keyPath: keyPath] = HexColor($0).hex }
        )
    }

    private func save() {
        if let card {
            guard card.design != draft else { return dismiss() }
            card.design = draft
            card.updatedAt = Date()
        } else {
            context.insert(Card(design: draft))
        }
        dismiss()
    }
}

private struct PalettePicker: View {
    @Binding var design: CardDesign

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(CardPalette.all) { palette in
                    let isSelected = design.palette == palette
                    Button {
                        design.apply(palette)
                    } label: {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: palette.startHex), Color(hex: palette.endHex)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay { Circle().strokeBorder(Color.primary.opacity(0.12)) }
                            .frame(width: 32, height: 32)
                            .padding(4)
                            .overlay {
                                Circle().strokeBorder(Color.primary, lineWidth: 2).opacity(isSelected ? 1 : 0)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(palette.name)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.vertical, 2)
        }
        .sensoryFeedback(.selection, trigger: design.palette)
    }
}

private struct ExpiryPicker: View {
    @Binding var month: Int?
    @Binding var year: Int?

    private var years: [Int] {
        let current = Calendar.current.component(.year, from: Date())
        var years = Array((current - 5)...(current + 12))
        if let year, !years.contains(year) { years.insert(year, at: 0) }
        return years
    }

    var body: some View {
        LabeledContent("Expires") {
            HStack(spacing: 0) {
                Picker("Month", selection: $month) {
                    Text("MM").tag(Int?.none)
                    ForEach(1...12, id: \.self) { month in
                        Text(String(format: "%02d", month)).tag(Int?.some(month))
                    }
                }
                Text("/").foregroundStyle(.tertiary)
                Picker("Year", selection: $year) {
                    Text("YYYY").tag(Int?.none)
                    ForEach(years, id: \.self) { year in
                        Text(String(year)).tag(Int?.some(year))
                    }
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
        }
    }
}

#Preview {
    CardEditorView()
        .modelContainer(for: Card.self, inMemory: true)
}
