// In Core/Data/DataSubmissionClient.swift
import Foundation
import ComposableArchitecture

struct DataSubmissionClient {
    var submitMetrics: (
        _ userId: String,
        _ dailyMetrics: DailyMetrics,
        _ typingMetrics: TypingMetrics,
        _ motionMetrics: DeviceMotionMetrics
    ) async throws -> Void
}

extension DataSubmissionClient: DependencyKey {
    static let liveValue = Self(
        submitMetrics: { userId, dailyMetrics, typingMetrics, motionMetrics in
            // Simulation of a backend call
            print("--- Data Submission Simulation ---")
            print("User ID: \(userId)")
            print("Daily Metrics: Steps \(dailyMetrics.steps), Energy: \(dailyMetrics.activeEnergy), HR: \(dailyMetrics.heartRate)")
            print("Typing Metrics: WPM \(typingMetrics.wordsPerMinute), Edits: \(typingMetrics.totalEditCount)")
            print("Motion Metrics: Avg X: \(motionMetrics.avgAccelerationX)")
            try await Task.sleep(for: .seconds(0.5))
            print("Data submitted successfully.")
        }
    )
}

extension DependencyValues {
    var dataSubmissionClient: DataSubmissionClient {
        get { self[DataSubmissionClient.self] }
        set { self[DataSubmissionClient.self] = newValue }
    }
}
