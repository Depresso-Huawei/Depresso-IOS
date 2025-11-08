
// Features/Dashboard/Core/Data/UserManager.swift
import Foundation

// This manages the user's ID for all API calls
 @MainActor
class UserManager: ObservableObject {
    @Published private(set) var userId: String?
    
    private let userDefaultsKey = "depresso_user_id"
    
    // Singleton instance
    static let shared = UserManager()
    
    private init() {
        // Load existing user ID from UserDefaults
        self.userId = UserDefaults.standard.string(forKey: userDefaultsKey)
    }
    
    // Register or retrieve user ID
    func ensureUserRegistered() async throws {
        // If we already have a user ID, we're done
        if userId != nil {
            return
        }
        
        // Otherwise, register a new user with the backend
        let newUserId = try await APIClient.registerUser()
        
        // Save it
        self.userId = newUserId
        UserDefaults.standard.set(newUserId, forKey: userDefaultsKey)
        
        print("✅ User registered with ID: \(newUserId)")
    }
    
    // Get current user ID (throws if not registered)
    func getCurrentUserId() throws -> String {
        guard let id = userId else {
            throw UserError.notRegistered
        }
        return id
    }
}

enum UserError: Error {
    case notRegistered
}
