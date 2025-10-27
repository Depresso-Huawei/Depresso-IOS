// In Core/Health/HealthClient.swift
import Foundation
import ComposableArchitecture
import XCTestDynamicOverlay // Needed for XCTFail

// ✅ Defined StepData struct here and made it Equatable
struct StepData: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let count: Double

    static var mock: [StepData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (0..<7).map { index -> StepData in
            let date = calendar.date(byAdding: .day, value: -index, to: today)!
            return StepData(date: date, count: Double.random(in: 3000...12000))
        }.reversed()
    }
}

struct EnergyData: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let value: Double

    static var mock: [EnergyData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (0..<7).map { index -> EnergyData in
            let date = calendar.date(byAdding: .day, value: -index, to: today)!
            return EnergyData(date: date, value: Double.random(in: 200...800))
        }.reversed()
    }
}

struct HeartRateData: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let value: Double

    static var mock: [HeartRateData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (0..<7).map { index -> HeartRateData in
            let date = calendar.date(byAdding: .day, value: -index, to: today)!
            return HeartRateData(date: date, value: Double.random(in: 55...90))
        }.reversed()
    }
}

struct HealthClient {
    // Ensure signatures match expected HealthKitManager methods
    var fetchHealthMetrics: @Sendable () async throws -> [HealthMetric]
    var fetchWeeklySteps: @Sendable () async throws -> [StepData]
    var fetchWeeklyActiveEnergy: @Sendable () async throws -> [EnergyData]
    var fetchWeeklyHeartRate: @Sendable () async throws -> [HeartRateData]
    var requestAuthorization: @Sendable () async throws -> Void
}

extension HealthClient: DependencyKey {
    static let liveValue = Self(
        fetchHealthMetrics: {
            let manager = HealthKitManager()
            // Use correct method names (assuming they exist in HealthKitManager)
            return await manager.fetchDailyMetrics()
        },
        fetchWeeklySteps: {
            let manager = HealthKitManager()
             // Use correct method names (assuming they exist in HealthKitManager)
            return await manager.fetchWeeklyStepData()
        },
        fetchWeeklyActiveEnergy: {
            let manager = HealthKitManager()
            return await manager.fetchWeeklyActiveEnergy()
        },
        fetchWeeklyHeartRate: {
            let manager = HealthKitManager()
            return await manager.fetchWeeklyHeartRate()
        },
        requestAuthorization: {
             let manager = HealthKitManager()
             try await manager.requestAuthorization()
        }
    )

     static let previewValue = Self(
         fetchHealthMetrics: { HealthMetric.mock }, // Assumes HealthMetric.mock exists
         fetchWeeklySteps: { StepData.mock },
         fetchWeeklyActiveEnergy: { EnergyData.mock },
         fetchWeeklyHeartRate: { HeartRateData.mock },
         requestAuthorization: { }
     )

     static let unimplemented = Self(
          fetchHealthMetrics: { XCTFail("Unimplemented: HealthClient.fetchHealthMetrics"); return [] },
          fetchWeeklySteps: { XCTFail("Unimplemented: HealthClient.fetchWeeklySteps"); return [] },
          fetchWeeklyActiveEnergy: { XCTFail("Unimplemented: HealthClient.fetchWeeklyActiveEnergy"); return [] },
          fetchWeeklyHeartRate: { XCTFail("Unimplemented: HealthClient.fetchWeeklyHeartRate"); return [] },
          requestAuthorization: { XCTFail("Unimplemented: HealthClient.requestAuthorization") }
     )
}

extension DependencyValues {
    var healthClient: HealthClient {
        get { self[HealthClient.self] }
        set { self[HealthClient.self] = newValue }
    }
}
