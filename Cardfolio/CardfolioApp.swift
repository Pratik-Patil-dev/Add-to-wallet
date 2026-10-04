import SwiftData
import SwiftUI

@main
struct CardfolioApp: App {
    @State private var signing = PassSigningStore()

    var body: some Scene {
        WindowGroup {
            CardListView()
                .environment(signing)
        }
        .modelContainer(for: Card.self)
    }
}
