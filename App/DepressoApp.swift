// In App/DepressoApp.swift
import SwiftUI
import SwiftData
import ComposableArchitecture
import FirebaseCore // ✅ ADD THIS IMPORT

@main
struct DepressoApp: App {

    private static var container: ModelContainer = {
        let schema = Schema()
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    static let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    } withDependencies: {
        $0.modelContext = ModelContextBox(container.mainContext)
    }

    // ✅ ADD THIS ENTIRE BLOCK
    // This initializer is called once when the app launches.
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: DepressoApp.store)
        }
      .modelContainer(Self.container)
    }
}