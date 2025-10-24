// In App/ContentView.swift
import SwiftUI
import ComposableArchitecture
import SwiftData

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var journalState = AICompanionJournalFeature.State()
        var dashboardState = DashboardFeature.State()
        var communityState = CommunityFeature.State()
        var supportState = SupportFeature.State() // ✅ ADDED
        @Presents var onboardingState: OnboardingFeature.State?
        var hasCompletedOnboarding: Bool = false
    }

    enum Action {
        case journal(AICompanionJournalFeature.Action)
        case dashboard(DashboardFeature.Action)
        case community(CommunityFeature.Action)
        case support(SupportFeature.Action) // ✅ ADDED
        case onboarding(PresentationAction<OnboardingFeature.Action>)
        case task
    }

    var body: some Reducer<State, Action> {
        Scope(state: \.journalState, action: \.journal) { AICompanionJournalFeature() }
        Scope(state: \.dashboardState, action: \.dashboard) { DashboardFeature() }
        Scope(state: \.communityState, action: \.community) { CommunityFeature() }
        Scope(state: \.supportState, action: \.support) { SupportFeature() }

        Reduce { state, action in
            switch action {
            case .task:
                if !state.hasCompletedOnboarding {
                    state.onboardingState = OnboardingFeature.State()
                }
                return .none
            
            case .onboarding(.presented(.delegate(.onboardingCompleted))):
                state.hasCompletedOnboarding = true
                state.onboardingState = nil
                return .none

            default:
                return .none
            }
        }
        .ifLet(\.$onboardingState, action: \.onboarding) {
            OnboardingFeature()
        }
    }
}

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
