//
//  UserDefaultsClient.swift
//  Depresso
//
//  Created by ElAmir Mansour.
//

import Foundation
import ComposableArchitecture

// MARK: - UserDefaults Keys
private enum UserDefaultsKeys {
    static let likedPostIDs = "likedPostIDs"
}

// MARK: - Client Definition
struct UserDefaultsClient {
    var loadLikedPostIDs: @Sendable () async -> Set<UUID>
    var saveLikedPostIDs: @Sendable (Set<UUID>) async -> Void
}

// MARK: - Live Implementation
extension UserDefaultsClient: DependencyKey {
    static let liveValue = Self(
        // ✅ Load liked post IDs (off main thread)
        loadLikedPostIDs: {
            await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .background).async {
                    let ids: Set<UUID>
                    if let uuidStrings = UserDefaults.standard.stringArray(forKey: UserDefaultsKeys.likedPostIDs) {
                        ids = Set(uuidStrings.compactMap { UUID(uuidString: $0) })
                    } else {
                        ids = []
                    }
                    continuation.resume(returning: ids)
                }
            }
        },

        // ✅ Save liked post IDs (off main thread)
        saveLikedPostIDs: { ids in
            await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .background).async {
                    let uuidStrings = ids.map { $0.uuidString }
                    UserDefaults.standard.set(uuidStrings, forKey: UserDefaultsKeys.likedPostIDs)
                    continuation.resume()
                }
            }
        }
    )
}

// MARK: - Dependency Key Accessor
extension DependencyValues {
    var userDefaultsClient: UserDefaultsClient {
        get { self[UserDefaultsClient.self] }
        set { self[UserDefaultsClient.self] = newValue }
    }
}
