// In App/ContentView.swift

// github testing :D
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