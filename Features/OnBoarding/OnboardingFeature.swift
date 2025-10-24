// In Features/Onboarding/OnboardingFeature.swift
import Foundation
import ComposableArchitecture

@Reducer
struct OnboardingFeature {
    @ObservableState
    struct State: Equatable {
        var questions: [PHQ8.Question] = PHQ8.allQuestions
        var currentQuestionIndex: Int = 0
        var isCompleted: Bool = false
        var analysis: String?
        var isLoadingAnalysis: Bool = false

        // ✅ ADDED: State to hold the final score and its interpretation
        var finalScore: Int = 0
        var severity: String = ""

        var progress: Double {
            return Double(currentQuestionIndex) / Double(questions.count)
        }

        var isNextButtonEnabled: Bool {
            questions[currentQuestionIndex].answer != nil
        }
    }

    enum Action {
        case answerQuestion(index: Int, answer: PHQ8.Answer)
        case nextButtonTapped
        case backButtonTapped
        case getAnalysisButtonTapped
        case analysisResponse(Result<String, Error>)
        case delegate(Delegate)

        enum Delegate {
            case onboardingCompleted
        }
    }

    @Dependency(\.aiClient) var aiClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .answerQuestion(index, answer):
                state.questions[index].answer = answer
                return .none

            case .nextButtonTapped:
                if state.currentQuestionIndex < state.questions.count - 1 {
                    state.currentQuestionIndex += 1
                } else {
                    state.isCompleted = true
                }
                return .none

            case .backButtonTapped:
                if state.currentQuestionIndex > 0 {
                    state.currentQuestionIndex -= 1
                }
                return .none

            case .getAnalysisButtonTapped:
                state.isLoadingAnalysis = true
                
                // ✅ UPDATED: Calculate and store the score and severity
                let score = state.questions.compactMap(\.answer?.rawValue).reduce(0, +)
                let severity = getSeverity(for: score)
                state.finalScore = score
                state.severity = severity
                
                let prompt = createAnalysisPrompt(score: score, severity: severity)

                return .run { send in
                    do {
                        let response = try await aiClient.generateResponse([], prompt, nil)
                        await send(.analysisResponse(.success(response)))
                    } catch {
                        await send(.analysisResponse(.failure(error)))
                    }
                }

            case .analysisResponse(.success(let analysis)):
                state.isLoadingAnalysis = false
                state.analysis = analysis
                return .none

            case .analysisResponse(.failure(let error)):
                state.isLoadingAnalysis = false
                state.analysis = "Sorry, we couldn't generate your analysis at this time. Please try again later. \n(\(error.localizedDescription))"
                return .none

            case .delegate:
                return .none
            }
        }
    }

    private func getSeverity(for score: Int) -> String {
        switch score {
        case 0...4: return "Minimal"
        case 5...9: return "Mild"
        case 10...14: return "Moderate"
        case 15...19: return "Moderately Severe"
        default: return "Severe"
        }
    }

    private func createAnalysisPrompt(score: Int, severity: String) -> String {
        return """
        A user has completed the PHQ-8 questionnaire and scored \(score), which indicates \(severity.lowercased()) depression symptoms.
        Based on this, please provide a brief, supportive, and encouraging analysis written directly to the user.

        - Start with a reassuring and empathetic tone.
        - Briefly explain what the score suggests in simple terms.
        - Suggest that the app's features (like the journal and wellness tasks) can be helpful tools.
        - Frame the app as a supportive companion for their mental wellness journey.
        - Keep the analysis to 3-4 short paragraphs.
        - Do NOT provide a medical diagnosis or medical advice.
        
        IMPORTANT: Your entire response will be shown directly to the user. Do not include any of your own thoughts, XML tags, or any text that is not part of the final, user-facing analysis.
        """
    }
}
