// In Features/Dashboard/Core/Data/BackendClients.swift
import Foundation
import ComposableArchitecture

private let testUserID = "00000000-0000-0000-0000-000000000001"

enum NetworkError: Error { case invalidURL, serverError, decodingError }

// MARK: - Backend Models (Prefixed to avoid conflict)

struct BackendJournalEntry: Codable, Equatable, Identifiable, Sendable { let id: Int, user_id: String, title: String?, content: String?, created_at: String }
struct BackendJournalMessage: Codable, Equatable, Identifiable, Sendable { let id: Int, entry_id: Int, user_id: String, sender: String, content: String, created_at: String }

// MARK: - Journal Client

@DependencyClient
struct JournalClient {
    var createEntry: @Sendable () async throws -> BackendJournalEntry
    var sendMessage: @Sendable (_ content: String, _ entryId: Int) async throws -> BackendJournalMessage
    var getMessages: @Sendable (_ entryId: Int) async throws -> [BackendJournalMessage]
}

extension JournalClient: DependencyKey {
    static let liveValue = Self(
        createEntry: { try await post(to: "journal/entries", body: ["userId": testUserID, "title": "New Journal"]) },
        sendMessage: { content, entryId in try await post(to: "journal/entries/\(entryId)/messages", body: ["userId": testUserID, "sender": "user", "content": content]) },
        getMessages: { entryId in try await get(from: "journal/entries/\(entryId)/messages") }
    )
}

extension DependencyValues {
    var journalClient: JournalClient {
        get { self[JournalClient.self] }
        set { self[JournalClient.self] = newValue }
    }
}

// MARK: - Generic Network Helpers (moved from DepressoApp.swift for clarity)
private func get<T: Decodable>(from path: String) async throws -> T {
    guard let url = URL(string: "http://localhost:3000/api/v1/\(path)") else { throw NetworkError.invalidURL }
    let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url))
    guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { throw NetworkError.serverError }
    return try JSONDecoder().decode(T.self, from: data)
}
private func post<B: Encodable, R: Decodable>(to path: String, body: B, responseType: R.Type = R.self) async throws -> R {
    guard let url = URL(string: "http://localhost:3000/api/v1/\(path)") else { throw NetworkError.invalidURL }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(body)
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { throw NetworkError.serverError }
    if R.self == Empty.self { return Empty() as! R }
    return try JSONDecoder().decode(R.self, from: data)
}
private struct Empty: Decodable {}