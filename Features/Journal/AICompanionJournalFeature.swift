// In Features/Journal/AICompanionJournalFeature.swift
import Foundation
import ComposableArchitecture
import CoreMotion
import FirebaseAI
import SwiftData
import SwiftUI

@Reducer
struct AICompanionJournalFeature {
      private enum CancelID { case motion }

      @ObservableState
      struct State: Equatable {
          static func == (lhs: AICompanionJournalFeature.State, rhs: AICompanionJournalFeature.State) -> Bool {
              return lhs.messages.map(\.id) == rhs.messages.map(\.id) &&
                     lhs.textInput == rhs.textInput &&
                     lhs.isSendingMessage == rhs.isSendingMessage
          }
          var messages: [ChatMessage] = []
          var textInput: String = ""
          var isSendingMessage: Bool = false
          @Presents var alert: AlertState<Action.Alert>?
          var journalSessionStartDate: Date?
          var editCount: Int = 0
          var motionSamples: [CMAcceleration] = [] // Ensure correct type CMAcceleration
          var currentWPM: Double = 0
          var currentSessionDuration: TimeInterval = 0
          var currentMotionData: [CMAcceleration] = [] // Ensure correct type CMAcceleration
          var currentEditCountForSubmission: Int = 0
      }

      enum Action: BindableAction {
          case binding(BindingAction<State>)
          case sendButtonTapped
          case aiResponseReceived(Result<ChatMessage, Error>)
          case alert(PresentationAction<Alert>)
          case task
          case motionUpdate(MotionData)
          case userDidBackspace
          case submissionDataLoaded(Result<DailyMetrics, Error>)
          case messagesLoaded(Result<[ChatMessage], Error>)
          case userMessageSaved(Result<ChatMessage, Error>)
          case aiMessageSaved(Result<ChatMessage, Error>)

          @CasePathable
          enum Alert: Equatable {}
      }

      @Dependency(\.aiClient) var aiClient
      @Dependency(\.motionClient) var motionClient
      @Dependency(\.healthClient) var healthClient
      @Dependency(\.dataSubmissionClient) var dataSubmissionClient
      @Dependency(\.uuid) var uuid
      @Dependency(\.modelContext) var modelContext

      private func history(from messages: [ChatMessage]) -> [ModelContent] {
           return messages.map { message in
                let role = message.isFromCurrentUser ? "user" : "model"
                return ModelContent(role: role, parts: [message.content])
           }
      }

    @MainActor
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
             case .task:
                 state.journalSessionStartDate = Date()
                 return .merge(
                     .run { send in
                         let descriptor = FetchDescriptor<ChatMessage>(sortBy: [SortDescriptor(\.timestamp)])
                         await send(.messagesLoaded(Result { try modelContext.context.fetch(descriptor) }))
                     },
                     .run { send in
                         for await motionData in self.motionClient.start() {
                             await send(.motionUpdate(motionData))
                         }
                     }
                     .cancellable(id: CancelID.motion)
                 )
             case .messagesLoaded(.success(let messages)):
                 state.messages = messages
                 if messages.isEmpty {
                     let greeting = ChatMessage(content: "Hello! How are you feeling today?", isFromCurrentUser: false)
                     state.messages.append(greeting)
                 }
                 return .none
             case .messagesLoaded(.failure(let error)):
                 state.alert = AlertState { TextState("Error") } message: { TextState("Could not load journal history. \(error.localizedDescription)") }
                 return .none
             case .motionUpdate(let motionData):
                 state.motionSamples.append(motionData.userAcceleration)
                 return .none
             case .userDidBackspace:
                 state.editCount += 1
                 return .none
             case .binding:
                 return .none

            case .sendButtonTapped:
                  guard !state.textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return .none }

                  let userMessage = ChatMessage(content: state.textInput, isFromCurrentUser: true)
                  let prompt = state.textInput

                  state.currentMotionData = state.motionSamples
                  state.currentEditCountForSubmission = state.editCount
                  state.currentSessionDuration = Date().timeIntervalSince(state.journalSessionStartDate ?? Date())
                  let wordCount = userMessage.content.split(whereSeparator: \.isWhitespace).count
                  state.currentWPM = state.currentSessionDuration > 0 ? (Double(wordCount) / state.currentSessionDuration) * 60.0 : 0

                  state.textInput = ""
                  state.isSendingMessage = true
                  state.journalSessionStartDate = Date()
                  state.editCount = 0
                  state.motionSamples = []

                  let historyToSubmit = history(from: state.messages)

                return .run { send in
                    // Save user message
                    modelContext.context.insert(userMessage)
                    do {
                        try modelContext.context.save()
                        await send(.userMessageSaved(.success(userMessage)))
                    } catch {
                        await send(.userMessageSaved(.failure(error)))
                        return
                    }

                    // --- Start concurrent fetches ---
                    async let aiResponseTask = Task {
                         let systemPrompt = "You are a friendly journaling companion..."
                         let responseText = try await aiClient.generateResponse(historyToSubmit, prompt, systemPrompt)
                         return ChatMessage(content: responseText, isFromCurrentUser: false)
                     }

                    async let healthMetricsTask = Task { () -> DailyMetrics in
                        // ✅ FIX: Add 'try await' here
                         let metricsArray = try await healthClient.fetchHealthMetrics()
                         let steps = metricsArray.first(where: { $0.type == .steps })?.value ?? 0.0
                         let energy = metricsArray.first(where: { $0.type == .calories })?.value ?? 0.0 // Use correct enum case
                         let heartRate = metricsArray.first(where: { $0.type == .heartRate })?.value ?? 0.0
                         return DailyMetrics(steps: steps, activeEnergy: energy, heartRate: heartRate)
                    }

                    // Await results and save AI message
                    do {
                        let aiMessage = try await aiResponseTask.value
                        let dailyMetrics = try await healthMetricsTask.value

                        // Save AI message
                        modelContext.context.insert(aiMessage)
                        try modelContext.context.save()
                        await send(.aiMessageSaved(.success(aiMessage)))

                        await send(.submissionDataLoaded(.success(dailyMetrics)))

                    } catch {
                        print("❌ Error during concurrent fetch/save: \(error)")
                        await send(.aiMessageSaved(.failure(error)))
                        await send(.submissionDataLoaded(.failure(error)))
                    }
                }

             case .userMessageSaved(.success(let message)):
                 withAnimation {
                     if !state.messages.contains(where: { $0.id == message.id }) {
                         state.messages.append(message)
                     }
                 }
                 return .none
             case .userMessageSaved(.failure(let error)):
                 state.alert = AlertState { TextState("Save Error") } message: { TextState("Could not save your message: \(error.localizedDescription)") }
                 state.isSendingMessage = false
                 return .none
             case .aiMessageSaved(.success(let message)):
                  withAnimation {
                      if !state.messages.contains(where: { $0.id == message.id }) {
                          state.messages.append(message)
                      }
                  }
                  state.isSendingMessage = false
                  return .none
             case .aiMessageSaved(.failure(let error)):
                 state.isSendingMessage = false
                 state.alert = AlertState { TextState("Save Error") } message: { TextState("Could not save the AI response: \(error.localizedDescription)") }
                 return .none
             case .aiResponseReceived: // Should not happen if saves are handled first
                  print("Warning: aiResponseReceived hit directly")
                  state.isSendingMessage = false
                  return .none
             case .submissionDataLoaded(.success(let dailyMetrics)):
                 let avgMotion = state.currentMotionData.reduce((0.0, 0.0, 0.0)) { ($0.0 + $1.x, $0.1 + $1.y, $0.2 + $1.z) }
                 let count = Double(state.currentMotionData.count)
                 let motionMetrics = DeviceMotionMetrics(
                    avgAccelerationX: count > 0 ? avgMotion.0 / count : 0,
                    avgAccelerationY: count > 0 ? avgMotion.1 / count : 0,
                    avgAccelerationZ: count > 0 ? avgMotion.2 / count : 0
                 )
                 let typingMetrics = TypingMetrics(
                    wordsPerMinute: state.currentWPM,
                    totalEditCount: state.currentEditCountForSubmission
                 )
                 return .run { [typing = typingMetrics, motion = motionMetrics] _ in
                    try await self.dataSubmissionClient.submitMetrics(self.uuid().uuidString, dailyMetrics, typing, motion)
                 } catch: { error, _ in print("Error submitting analytics data: \(error)") }
             case .submissionDataLoaded(.failure(let error)):
                 print("Failed to load HealthKit data for submission: \(error)")
                 return .none
             case .alert:
                 return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
