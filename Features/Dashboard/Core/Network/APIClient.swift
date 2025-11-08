
// Features/Dashboard/Core/Network/APIClient.swift
import Foundation
import ComposableArchitecture

// MARK: - API Configuration
enum APIConfig {
  //   static let baseURL = "http://localhost:3000/api/v1"
    // When testing on physical device, use your Mac's IP:
   static let baseURL = "http://192.168.1.7:3000/api/v1"
}

// MARK: - API Errors
enum APIError: Error, Equatable {
    case invalidURL
    case networkError(String)
    case decodingError(String)
    case serverError(Int, String)
    case noData
}

// MARK: - HTTP Method
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

// MARK: - API Client
struct APIClient {
    // Generic request function
    // This is the core function that all API calls will use
    private static func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        body: Encodable? = nil
    ) async throws -> T {
        // Step 1: Build the URL
        guard let url = URL(string: "\(APIConfig.baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        // Step 2: Configure the request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Step 3: Add body if provided (for POST/PUT requests)
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        // Step 4: Make the network call
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Step 5: Check response status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("Invalid response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(httpResponse.statusCode, errorMessage)
        }
        
        // Step 6: Decode the response
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }
    
    // MARK: - User Registration
    // Call this once when app first launches
    static func registerUser() async throws -> String {
        struct Response: Codable {
            let userId: String
        }
        
        let response: Response = try await request(
            endpoint: "/users/register",
            method: .post
        )
        
        return response.userId
    }
    
    // MARK: - Metrics Submission
    static func submitMetrics(
        userId: String,
        dailyMetrics: DailyMetrics,
        typingMetrics: TypingMetrics,
        motionMetrics: DeviceMotionMetrics
    ) async throws {
        struct Request: Codable {
            let userId: String
            let dailyMetrics: DailyMetricsDTO
            let typingMetrics: TypingMetricsDTO
            let motionMetrics: MotionMetricsDTO
        }
        
        // Convert your domain models to DTOs (Data Transfer Objects)
        let request = Request(
            userId: userId,
            dailyMetrics: DailyMetricsDTO(
                steps: dailyMetrics.steps,
                activeEnergy: dailyMetrics.activeEnergy,
                heartRate: dailyMetrics.heartRate
            ),
            typingMetrics: TypingMetricsDTO(
                wordsPerMinute: typingMetrics.wordsPerMinute,
                totalEditCount: typingMetrics.totalEditCount
            ),
            motionMetrics: MotionMetricsDTO(
                avgAccelerationX: motionMetrics.avgAccelerationX,
                avgAccelerationY: motionMetrics.avgAccelerationY,
                avgAccelerationZ: motionMetrics.avgAccelerationZ
            )
        )
        
        // Void response means we just check for errors
        let _: EmptyResponse = try await APIClient.request(
            endpoint: "/metrics/submit",
            method: .post,
            body: request
        )
    }
    
    // MARK: - Journal Entries
    static func createJournalEntry(
        userId: String,
        title: String?,
        content: String
    ) async throws -> JournalEntryDTO {
        struct Request: Codable {
            let userId: String
            let title: String?
            let content: String
        }
        
        return try await request(
            endpoint: "/journal/entries",
            method: .post,
            body: Request(userId: userId, title: title, content: content)
        )
    }
    
    static func addMessageToEntry(
        entryId: Int,
        userId: String,
        sender: String,
        content: String
    ) async throws -> AIChatMessageDTO {
        struct Request: Codable {
            let userId: String
            let sender: String
            let content: String
        }
        
        return try await request(
            endpoint: "/journal/entries/\(entryId)/messages",
            method: .post,
            body: Request(userId: userId, sender: sender, content: content)
        )
    }
    
    // MARK: - Community Posts
    static func getAllPosts() async throws -> [CommunityPostDTO] {
        return try await request(
            endpoint: "/community/posts",
            method: .get
        )
    }
    
    static func createPost(
        userId: String,
        title: String,
        content: String
    ) async throws -> CommunityPostDTO {
        struct Request: Codable {
            let userId: String
            let title: String
            let content: String
        }
        
        return try await request(
            endpoint: "/community/posts",
            method: .post,
            body: Request(userId: userId, title: title, content: content)
        )
    }
    
    static func likePost(postId: String, userId: String) async throws {
        struct Request: Codable {
            let userId: String
        }
        
        let _: EmptyResponse = try await request(
            endpoint: "/community/posts/\(postId)/like",
            method: .post,
body: Request(userId: userId)
        )
    }
    
    static func unlikePost(postId: String, userId: String) async throws {
        struct Request: Codable {
            let userId: String
        }
        
        let _: EmptyResponse = try await request(
            endpoint: "/community/posts/\(postId)/like",
            method: .delete,
            body: Request(userId: userId)
        )
    }
    
    // MARK: - Assessments
    static func submitAssessment(
        userId: String,
        assessmentType: String,
        score: Int,
        answers: [Int]?
    ) async throws -> AssessmentDTO {
        struct Request: Codable {
            let userId: String
            let assessmentType: String
            let score: Int
            let answers: [Int]?
        }
        
        return try await request(
            endpoint: "/assessments",
            method: .post,
            body: Request(
                userId: userId,
                assessmentType: assessmentType,
                score: score,
                answers: answers
            )
        )
    }
}

// MARK: - Data Transfer Objects (DTOs)
// These match your backend response structure

struct EmptyResponse: Codable {}

struct DailyMetricsDTO: Codable {
    let steps: Double
    let activeEnergy: Double
    let heartRate: Double
}

struct TypingMetricsDTO: Codable {
    let wordsPerMinute: Double
    let totalEditCount: Int
}

struct MotionMetricsDTO: Codable {
    let avgAccelerationX: Double
    let avgAccelerationY: Double
    let avgAccelerationZ: Double
}

struct JournalEntryDTO: Codable {
    let id: Int
    let userId: String
    let title: String?
    let content: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case content
        case createdAt = "created_at"
    }
}

struct AIChatMessageDTO: Codable {
    let id: Int
    let entryId: Int
    let userId: String
    let sender: String
    let content: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case entryId = "entry_id"
        case userId = "user_id"
        case sender
        case content
        case createdAt = "created_at"
    }
}

struct CommunityPostDTO: Codable {
    let id: String
    let title: String?
    let content: String
    let likeCount: Int
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case likeCount = "like_count"
        case createdAt = "created_at"
    }
}

struct AssessmentDTO: Codable {
    let id: Int
    let userId: String
    let assessmentType: String
    let score: Int
    let answers: [Int]?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case assessmentType = "assessment_type"
        case score
        case answers
        case createdAt = "created_at"
    }
}
