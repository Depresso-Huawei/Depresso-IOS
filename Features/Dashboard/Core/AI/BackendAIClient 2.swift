
// Features/Dashboard/Core/AI/BackendAIClient.swift
import Foundation
import ComposableArchitecture
import FirebaseAI

// This is the NEW AI client that uses your backend
struct BackendAIClient {
    var generateResponse: (_ history: [ModelContent], _ prompt: String, _ systemPrompt: String?) async throws -> String
}

extension BackendAIClient: DependencyKey {
    static let liveValue: Self = {
        let generateResponse: @Sendable (_ history: [ModelContent], _ prompt: String, _ systemPrompt: String?) async throws -> String = { history, prompt, systemPrompt in
            
            // EXPLANATION:
            // Instead of calling Huawei API directly, we'll:
            // 1. Create a journal entry on backend
            // 2. Send the user's message
            // 3. Backend handles AI call and returns response
            
            do {
                let userId = try await UserManager.shared.getCurrentUserId()
                
                // Step 1: Create journal entry if needed
                // For now, we'll use a single entry per session
                // You can modify this to create new entries as needed
                let entryId = try await getOrCreateJournalEntry(userId: userId)
                
                // Step 2: Send message to backend
                // Backend will:
                // - Save user message
                // - Call Qwen API
                // - Save AI response
                // - Return AI response to us
                let aiMessage = try await APIClient.addMessageToEntry(
                    entryId: entryId,
                    userId: userId,
                    sender: "user",
                    content: prompt
                )
                
                // Step 3: Return AI's response
                return aiMessage.content
                
            } catch {
                print("❌ Backend AI error: \(error)")
                throw AIError.responseError
            }
        }
        
        return Self(generateResponse: generateResponse)
    }()
    
    // Helper function to get or create a journal entry
    private static func getOrCreateJournalEntry(userId: String) async throws -> Int {
        // EXPLANATION:
        // We'll store the current entry ID in UserDefaults
        // This creates one journal entry per day
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayKey = "journal_entry_\(dateFormatter.string(from: Date()))"
        
        // Check if we already have an entry for today
        if let storedId = UserDefaults.standard.object(forKey: todayKey) as? Int {
            return storedId
        }
        
        // Create new entry
        let entry = try await APIClient.createJournalEntry(
            userId: userId,
            title: "Journal - \(dateFormatter.string(from: Date()))",
            content: ""
        )
        
        // Store for future use today
        UserDefaults.standard.set(entry.id, forKey: todayKey)
        
        return entry.id
    }
}

// Add to DependencyValues
extension DependencyValues {
    var backendAIClient: BackendAIClient {
        get { self[BackendAIClient.self] }
        set { self[BackendAIClient.self] = newValue }
    }
}
