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
        var supportState = SupportFeature.State()
        @Presents var onboardingState: OnboardingFeature.State?
        var hasCompletedOnboarding: Bool = false
        var isRegisteringUser: Bool = false // NEW
    }

    enum Action {
        case journal(AICompanionJournalFeature.Action)
        case dashboard(DashboardFeature.Action)
        case community(CommunityFeature.Action)
        case support(SupportFeature.Action)
        case onboarding(PresentationAction<OnboardingFeature.Action>)
        case task
        case userRegistrationCompleted(Result<Void, Error>) // NEW
    }

    var body: some Reducer<State, Action> {
        Scope(state: \.journalState, action: \.journal) { AICompanionJournalFeature() }
        Scope(state: \.dashboardState, action: \.dashboard) { DashboardFeature() }
        Scope(state: \.communityState, action: \.community) { CommunityFeature() }
        Scope(state: \.supportState, action: \.support) { SupportFeature() }

        Reduce { state, action in
            switch action {
            case .task:
                // NEW: Register user on first launch
                state.isRegisteringUser = true
                return .run { send in
                    do {
                        try await UserManager.shared.ensureUserRegistered()
                        await send(.userRegistrationCompleted(.success(())))
                    } catch {
                        await send(.userRegistrationCompleted(.failure(error)))
                    }
                }
            
            case .userRegistrationCompleted(.success):
                state.isRegisteringUser = false
                // Now check onboarding
                if !state.hasCompletedOnboarding {
                    state.onboardingState = OnboardingFeature.State()
                }
                return .none
                
            case .userRegistrationCompleted(.failure(let error)):
                state.isRegisteringUser = false
                print("❌ User registration failed: \(error)")
                // You might want to show an alert here
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