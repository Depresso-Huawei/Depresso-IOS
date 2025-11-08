// In App/ContentView.swift

// github testing :D
import SwiftUI
import ComposableArchitecture
import SwiftData

struct ContentView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        TabView {
            DashboardView(store: store.scope(state: \.dashboardState, action: \.dashboard))
                .tabItem { Label("Dashboard", systemImage: "square.grid.2x2.fill") }

            JournalView(store: store.scope(state: \.journalState, action: \.journal))
                .tabItem { Label("Journal", systemImage: "book.fill") }

            CommunityView(store: store.scope(state: \.communityState, action: \.community))
                .tabItem { Label("Community", systemImage: "person.3.fill") }

            // ✅ UPDATED: Pass the store to SupportView
            SupportView(store: store.scope(state: \.supportState, action: \.support))
                .tabItem { Label("Support", systemImage: "heart.fill") }
        }
        .tint(.ds.accent)
        .sheet(store: self.store.scope(state: \.$onboardingState, action: \.onboarding)) { store in
            OnboardingView(store: store)
        }
        .task {
            await store.send(.task).finish()
        }
    }
}

#Preview {
    ContentView(
        store: Store(initialState: AppFeature.State()) {
            AppFeature()
        }
    )
    .modelContainer(for: [ChatMessage.self, WellnessTask.self, CommunityPost.self], inMemory: true)
}
