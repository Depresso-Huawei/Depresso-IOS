// In Core/Data/DataSubmissionClient.swift
import Foundation
import ComposableArchitecture

// Define a Codable struct for the payload that would be sent to the backend.
/*
private struct MetricsPayload: Codable {
    let userId: String
    let dailyMetrics: DailyMetrics
    let typingMetrics: TypingMetrics
    let motionMetrics: DeviceMotionMetrics
}
*/

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
            
            // MARK: - Real Implementation (for future reference)
            /*
            // 1. Define the backend endpoint URL.
            guard let url = URL(string: "https://your-research-backend.example.com/submit_metrics") else {
                throw URLError(.badURL)
            }

            // 2. Construct the payload.
            let payload = MetricsPayload(
                userId: userId,
                dailyMetrics: dailyMetrics,
                typingMetrics: typingMetrics,
                motionMetrics: motionMetrics
            )

            // 3. Encode the payload to JSON.
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(payload)

            // 4. Create the URLRequest.
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // **Authentication Note:** In a real application, you would add an authentication
            // token here, likely retrieved from a secure storage like the Keychain.
            // For example:
            // if let authToken = getAuthToken() {
            //     request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            // }

            request.httpBody = jsonData

            // 5. Perform the network request.
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }

            print("Data submitted successfully. Server response: \(String(data: data, encoding: .utf8) ?? "")")
            */
            
            // MARK: - Simulation of a backend call (current implementation)
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
