import SwiftData
import SwiftUI

@main
struct CardfolioApp: App {
    var body: some Scene {
        WindowGroup {
            CardListView()
        }
        .modelContainer(for: Card.self)
    }
}
