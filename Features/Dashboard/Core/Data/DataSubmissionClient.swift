// Features/Dashboard/Core/Data/DataSubmissionClient.swift
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
    // REAL implementation - connects to backend
    static let liveValue = Self(
        submitMetrics: { userId, dailyMetrics, typingMetrics, motionMetrics in
            print("📤 Submitting metrics to backend...")
            print("   User ID: \(userId)")
            print("   Daily: Steps \(dailyMetrics.steps), Energy: \(dailyMetrics.activeEnergy), HR: \(dailyMetrics.heartRate)")
            print("   Typing: WPM \(typingMetrics.wordsPerMinute), Edits: \(typingMetrics.totalEditCount)")
            print("   Motion: X: \(motionMetrics.avgAccelerationX), Y: \(motionMetrics.avgAccelerationY), Z: \(motionMetrics.avgAccelerationZ)")
            
            do {
                try await APIClient.submitMetrics(
                    userId: userId,
                    dailyMetrics: dailyMetrics,
                    typingMetrics: typingMetrics,
                    motionMetrics: motionMetrics
                )
                print("✅ Metrics submitted successfully")
            } catch {
                print("❌ Failed to submit metrics: \(error)")
                throw error
            }
        }
    )
}

extension DependencyValues {
    var dataSubmissionClient: DataSubmissionClient {
        get { self[DataSubmissionClient.self] }
        set { self[DataSubmissionClient.self] = newValue }
    }
}
