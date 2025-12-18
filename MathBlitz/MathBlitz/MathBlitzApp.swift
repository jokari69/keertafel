import SwiftUI
import SwiftData

@main
struct MathBlitzApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            // Use local-only storage (our CloudKitService handles sync manually)
            let schema = Schema([HighScore.self])
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none  // Disable automatic CloudKit sync
            )
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}
