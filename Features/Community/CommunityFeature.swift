// In Features/Community/CommunityFeature.swift
import Foundation
import ComposableArchitecture
import SwiftData
import SwiftUI

@Reducer
struct CommunityFeature {
    @ObservableState
    struct State: Equatable {
        var posts: [CommunityPost] = []
        var isLoading: Bool = true
        var errorMessage: String?
        var likedPostIDs: Set<UUID> = []
        @Presents var destination: Destination.State?
    }

    enum Action {
        case task
        case postsLoaded(Result<[CommunityPost], Error>)
        case likedIDsLoaded(Set<UUID>)
        case addPostButtonTapped
        case destination(PresentationAction<Destination.Action>)
        case postSavedSuccessfully(CommunityPost)
        case saveFailed(Error)
        case likeButtonTapped(id: CommunityPost.ID)
    }

    @Reducer(state: .equatable)
    enum Destination {
        case addPost(AddPostFeature)
    }

    @Dependency(\.modelContext) var modelContext
    @Dependency(\.userDefaultsClient) var userDefaultsClient

    @MainActor // Ensures reducer runs on the main actor
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
    state.isLoading = true
    state.errorMessage = nil
    return .merge(
        // CHANGED: Fetch posts from backend instead of local SwiftData
        .run { send in
            do {
                // Fetch from backend
                let postsDTO = try await APIClient.getAllPosts()
                
                // Convert DTOs to local models
                let posts = postsDTO.map { dto -> CommunityPost in
                    // Check if post already exists locally
                    let predicate = #Predicate<CommunityPost> { $0.id.uuidString == dto.id }
                    let descriptor = FetchDescriptor(predicate: predicate)
                    
                    if let existingPost = try? modelContext.context.fetch(descriptor).first {
                        // Update existing post
                        existingPost.title = dto.title ?? ""
                        existingPost.content = dto.content
                        existingPost.likeCount = dto.likeCount
                        return existingPost
                    } else {
                        // Create new post
                        let newPost = CommunityPost(
                            id: UUID(uuidString: dto.id) ?? UUID(),
                            title: dto.title ?? "",
                            content: dto.content,
                            creationDate: dto.createdAt,
                            imageData: nil, // Backend doesn't support images yet
                            likeCount: dto.likeCount
                        )
                        modelContext.context.insert(newPost)
                        return newPost
                    }
                }
                
                try modelContext.context.save()
                await send(.postsLoaded(.success(posts)))
                
            } catch {
                print("❌ Error fetching posts from backend: \(error)")
                // Fallback to local posts
                let descriptor = FetchDescriptor<CommunityPost>(
                    sortBy: [SortDescriptor(\.creationDate, order: .reverse)]
                )
                if let localPosts = try? modelContext.context.fetch(descriptor) {
                    await send(.postsLoaded(.success(localPosts)))
                } else {
                    await send(.postsLoaded(.failure(error)))
                }
            }
        },
        // Load liked post IDs (unchanged)
        .run { send in
            await send(.likedIDsLoaded(await userDefaultsClient.loadLikedPostIDs()))
        }
    )

            case .postsLoaded(.success(let posts)):
                state.posts = posts
                state.isLoading = false
                return .none

            case .postsLoaded(.failure(let error)):
                state.isLoading = false
                state.errorMessage = "Failed to load community stories."
                print("Error loading community posts: \(error)")
                return .none

            case .likedIDsLoaded(let ids):
                state.likedPostIDs = ids
                return .none

            case .addPostButtonTapped:
                state.destination = .addPost(AddPostFeature.State())
                return .none

            // Received 'savePost' delegate action from AddPostFeature
            case .destination(.presented(.addPost(.delegate(.savePost(let newPost))))):
    // CHANGED: Save to backend first, then local
    return .run { send in
        do {
            let userId = try await UserManager.shared.getCurrentUserId()
            
            // Save to backend
            let postDTO = try await APIClient.createPost(
                userId: userId,
                title: newPost.title,
                content: newPost.content
            )
            
            // Update local post with backend ID
            newPost.id = UUID(uuidString: postDTO.id) ?? newPost.id
            
            // Save locally
            modelContext.context.insert(newPost)
            try modelContext.context.save()
            
            print("✅ Post saved to backend and locally")
            await send(.postSavedSuccessfully(newPost))
            
        } catch {
            print("❌ Failed to save post to backend: \(error)")
            await send(.saveFailed(error))
        }
    }

            case .postSavedSuccessfully(let newPost):
                state.posts.insert(newPost, at: 0)
                state.destination = nil
                return .none

            case .saveFailed(let error):
                print("Error saving post: \(error)")
                state.destination = nil
                // Optionally show an alert here
                return .none

            case .likeButtonTapped(let id):
    guard let index = state.posts.firstIndex(where: { $0.id == id }) else {
        return .none
    }

    let post = state.posts[index]
    let wasLiked = state.likedPostIDs.contains(id)
    
    // Optimistic update
    if wasLiked {
        state.likedPostIDs.remove(id)
        post.likeCount -= 1
    } else {
        state.likedPostIDs.insert(id)
        post.likeCount += 1
    }

    // Save context
    try? modelContext.context.save()

    let likedIDs = state.likedPostIDs
    
    // CHANGED: Sync with backend
    return .run { _ in
        do {
            let userId = try await UserManager.shared.getCurrentUserId()
            let postIdString = id.uuidString
            
            if wasLiked {
                try await APIClient.unlikePost(postId: postIdString, userId: userId)
                print("✅ Post unliked on backend")
            } else {
                try await APIClient.likePost(postId: postIdString, userId: userId)
                print("✅ Post liked on backend")
            }
            
            // Save liked IDs locally
            await userDefaultsClient.saveLikedPostIDs(likedIDs)
            
        } catch {
            print("❌ Failed to sync like with backend: \(error)")
            // You might want to rollback the optimistic update here
        }
    }

            case .destination(.dismiss):
                 state.destination = nil
                 return .none

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}
