// In Features/Journal/JournalView.swift
import SwiftUI
import ComposableArchitecture
import SwiftData

struct JournalView: View {
    @Bindable var store: StoreOf<AICompanionJournalFeature>
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack {
                ScrollViewReader { scrollViewProxy in
                    ScrollView {
                        LazyVStack(spacing: DesignSystem.Spacing.medium) {
                            ForEach(store.messages) { message in
                                MessageBubble(message: message)
                                   .id(message.id) // ID for individual messages (for scrolling)
                                   .transition(.scale(scale: 0.95, anchor: message.isFromCurrentUser ? .bottomTrailing : .bottomLeading).combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.medium)
                        .padding(.top, DesignSystem.Spacing.small)
                    }
                    .id("journalScrollView") // ✅ ADDED: Stable ID for the ScrollView
                    .onTapGesture {
                        isTextFieldFocused = false
                    }
                    .onChange(of: store.messages.count) {
                        if let lastMessage = store.messages.last {
                            DispatchQueue.main.async {
                                withAnimation {
                                    scrollViewProxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }

                HStack(spacing: 12) {
                    TextField("How are you feeling...", text: $store.textInput, axis: .vertical)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .focused($isTextFieldFocused)

                    Button {
                        store.send(.sendButtonTapped)
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.title3)
                            .foregroundStyle(store.textInput.isEmpty ? .gray : .accentColor)
                    }
                    .disabled(store.textInput.isEmpty)
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 1)

            }
            .background(Color.ds.backgroundPrimary)
            .navigationTitle("Mindful Moments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isTextFieldFocused {
                        Button("Done") {
                            isTextFieldFocused = false
                        }
                    }
                }
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .task {
            await store.send(.task).finish()
        }
    }
}

