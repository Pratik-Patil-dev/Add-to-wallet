import SwiftData
import SwiftUI

@main
struct CardfolioApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Cardfolio")
        }
        .modelContainer(for: Card.self)
    }
}
