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
                    .run { send in
                        // Fetch initial posts
                        let descriptor = FetchDescriptor<CommunityPost>(sortBy: [SortDescriptor(\.creationDate, order: .reverse)])
                        do {
                            // Access context directly because reducer is MainActor isolated
                            let posts = try modelContext.context.fetch(descriptor)
                            await send(.postsLoaded(.success(posts)))
                        } catch {
                            await send(.postsLoaded(.failure(error)))
                        }
                    },
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
                // Save explicitly (safe because reducer is MainActor isolated)
                return .run { send in
                    // Access context directly
                    modelContext.context.insert(newPost)
                    do {
                        try modelContext.context.save()
                        print("✅ Community post saved.")
                        await send(.postSavedSuccessfully(newPost))
                    } catch {
                        print("❌ Failed to save community post: \(error)")
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
                if state.likedPostIDs.contains(id) {
                    state.likedPostIDs.remove(id)
                    post.likeCount -= 1
                } else {
                    state.likedPostIDs.insert(id)
                    post.likeCount += 1
                }

                // Save the ModelContext
                try? modelContext.context.save()

                let likedIDs = state.likedPostIDs
                return .run { _ in
                    await userDefaultsClient.saveLikedPostIDs(likedIDs)
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
