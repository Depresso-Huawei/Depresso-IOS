// In Core/Health/HealthKitManager.swift
import Foundation
import HealthKit

class HealthKitManager {
    let healthStore = HKHealthStore()

    // Function to request authorization
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.healthDataNotAvailable
        }
        
        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]
        
        // No types to share for now
        let typesToShare: Set<HKSampleType> = []
        
        try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
        print("HealthKit Authorization Requested.") // Added log
    }

    // ✅ Renamed function to match HealthClient expectation: fetchDailyMetrics
    func fetchDailyMetrics() async -> [HealthMetric] {
        print("Fetching daily metrics...") // Added log
        var metrics: [HealthMetric] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let now = Date()

        // Steps
        if let steps = await fetchQuantityData(for: .stepCount, from: today, to: now) {
            metrics.append(HealthMetric(type: .steps, value: steps, date: now))
            print("Fetched Steps: \(steps)") // Added log
        } else { print("Failed to fetch steps.") }
        // Active Energy
        if let calories = await fetchQuantityData(for: .activeEnergyBurned, from: today, to: now) {
            metrics.append(HealthMetric(type: .calories, value: calories, date: now))
            print("Fetched Calories: \(calories)") // Added log
        } else { print("Failed to fetch calories.") }
        // Heart Rate
        if let heartRate = await fetchLatestQuantitySample(for: .heartRate) {
             metrics.append(HealthMetric(type: .heartRate, value: heartRate, date: now))
             print("Fetched Heart Rate: \(heartRate)") // Added log
        } else { print("Failed to fetch heart rate.") }

        print("Finished fetching daily metrics. Count: \(metrics.count)") // Added log
        return metrics
    }

    // ✅ Renamed function to match HealthClient expectation: fetchWeeklyStepData
    func fetchWeeklyStepData() async -> [StepData] {
        print("Fetching weekly step data...") // Added log
        var weeklyData: [StepData] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let steps = await fetchQuantityData(for: .stepCount, from: dayStart, to: dayEnd, options: .cumulativeSum) ?? 0.0
            weeklyData.append(StepData(date: dayStart, count: steps))
        }
        
        print("Finished fetching weekly steps. Count: \(weeklyData.count)") // Added log
        return weeklyData.sorted { $0.date < $1.date }
    }

    // --- Helper Functions ---
     private func fetchQuantityData(for typeIdentifier: HKQuantityTypeIdentifier, from start: Date, to end: Date, options: HKStatisticsOptions = .cumulativeSum) async -> Double? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: typeIdentifier) else {
            print("Error: Invalid quantity type identifier: \(typeIdentifier.rawValue)")
            return nil
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let queryDescriptor = HKSampleQueryDescriptor(predicates: [.sample(type: quantityType, predicate: predicate)], sortDescriptors: [])
        
        do {
            let results = try await queryDescriptor.result(for: healthStore)
            var totalValue: Double = 0
            for sample in results {
                if let quantitySample = sample as? HKQuantitySample {
                    let unit: HKUnit
                    switch typeIdentifier {
                    case .stepCount: unit = .count()
                    case .activeEnergyBurned: unit = .kilocalorie()
                    case .heartRate: unit = HKUnit.count().unitDivided(by: .minute())
                    default: unit = HKUnit.count()
                    }
                    totalValue += quantitySample.quantity.doubleValue(for: unit)
                }
            }
             return totalValue
        } catch {
            print("Error fetching quantity data for \(typeIdentifier.rawValue): \(error)")
            return nil
        }
    }
    
    private func fetchLatestQuantitySample(for typeIdentifier: HKQuantityTypeIdentifier) async -> Double? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: typeIdentifier) else {
            print("Error: Invalid quantity type identifier: \(typeIdentifier.rawValue)")
            return nil
        }
        
        let queryDescriptor = HKSampleQueryDescriptor(
            predicates: [.sample(type: quantityType)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )
        
        do {
            let results = try await queryDescriptor.result(for: healthStore)
            guard let sample = results.first as? HKQuantitySample else { return nil }
            
            let unit: HKUnit
             switch typeIdentifier {
             case .heartRate: unit = HKUnit.count().unitDivided(by: .minute())
             default: unit = HKUnit.count()
             }
            return sample.quantity.doubleValue(for: unit)
        } catch {
            print("Error fetching latest sample for \(typeIdentifier.rawValue): \(error)")
            return nil
        }
    }

    enum HealthKitError: Error {
        case healthDataNotAvailable
    }
}
