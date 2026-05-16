import SwiftUI

struct ChatView: View {
    let document: Document
    @EnvironmentObject private var store: DocumentStore
    @EnvironmentObject private var llm: LLMService
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isGenerating = false
    private let vectorStore = VectorStore()

    var body: some View {
        VStack(spacing: 0) {
            if !llm.isAvailable {
                unavailableView
            } else {
                chatHeader
                messageList
                inputBar
            }
        }
        .background(.clear)
        .onAppear {
            messages = store.loadMessages(for: document.id)
        }
    }

    // MARK: - Header

    private var chatHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.42, green: 0.45, blue: 0.72).opacity(0.9), Color(red: 0.30, green: 0.33, blue: 0.60).opacity(0.9)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(document.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                HStack(spacing: 4) {
                    Circle().fill(llm.isAvailable ? Color.green : Color.orange).frame(width: 6, height: 6)
                    Text(llm.currentProviderName)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            Spacer()
            if isGenerating {
                ProgressView().controlSize(.small).tint(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial.opacity(0.5))
        .overlay(alignment: .bottom) { Divider().opacity(0.15) }
    }

    // MARK: - Messages

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 20) {
                    if messages.isEmpty {
                        suggestionsView
                    }
                    ForEach(messages) { msg in
                        MessageBubble(message: msg).id(msg.id)
                    }
                }
                .padding(20)
                .padding(.bottom, 8)
            }
            .onChange(of: messages.count) {
                withAnimation(.spring(duration: 0.4)) {
                    proxy.scrollTo(messages.last?.id, anchor: .bottom)
                }
            }
        }
    }

    private var suggestionsView: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 40)
            Image(systemName: "sparkles")
                .font(.system(size: 36))
                .foregroundStyle(
                    LinearGradient(colors: [Color(red: 0.55, green: 0.57, blue: 0.85), Color(red: 0.38, green: 0.48, blue: 0.78)], startPoint: .top, endPoint: .bottom)
                )
            Text("Ask anything about\n\(document.name)")
                .font(.title3.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            HStack(spacing: 10) {
                ForEach(["Summarize this", "Key points", "Who wrote this?"], id: \.self) { hint in
                    Button(hint) {
                        inputText = hint
                        Task { await send() }
                    }
                    .buttonStyle(.glass)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
    }

    // MARK: - Input

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask a question…", text: $inputText, axis: .vertical)
                .lineLimit(1...5)
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundStyle(.white)
                .padding(.vertical, 10)
                .onSubmit { Task { await send() } }

            Button {
                Task { await send() }
            } label: {
                Image(systemName: isGenerating ? "stop.circle.fill" : "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(
                        canSend
                        ? LinearGradient(colors: [Color(red: 0.55, green: 0.57, blue: 0.85), Color(red: 0.38, green: 0.48, blue: 0.78)], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [.white.opacity(0.3), .white.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .glassEffect(in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    // MARK: - Unavailable

    private var unavailableView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "brain.filled.head.profile")
                .font(.system(size: 56))
                .foregroundStyle(.white.opacity(0.3))
            VStack(spacing: 8) {
                Text("Apple Intelligence Required")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
                Text("Enable Apple Intelligence in System Settings\n→ Apple Intelligence & Siri")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
    }

    // MARK: - Logic

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isGenerating
    }

    private func send() async {
        let query = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        messages.append(ChatMessage(role: .user, content: query))
        inputText = ""
        isGenerating = true

        let chunks = store.chunks(for: document.id)
        let relevant = vectorStore.search(query: query, chunks: chunks, topK: 4)
        let context = relevant.map { "[Page \($0.pageNumber)]\n\($0.text)" }.joined(separator: "\n\n---\n\n")

        var reply = ChatMessage(role: .assistant, content: "", sourcePages: relevant.map { $0.pageNumber })
        messages.append(reply)

        do {
            for try await token in await llm.streamAnswer(query: query, context: context) {
                reply.content += token
                messages[messages.count - 1] = reply
            }
        } catch {
            reply.content = "Error: \(error.localizedDescription)"
            messages[messages.count - 1] = reply
        }
        isGenerating = false
        store.saveMessages(messages, for: document.id)
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if message.role == .user { Spacer(minLength: 60) }

            if message.role == .assistant {
                // AI avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(red: 0.45, green: 0.48, blue: 0.75).opacity(0.9), Color(red: 0.32, green: 0.42, blue: 0.68).opacity(0.9)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 28, height: 28)
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
                }
                .alignmentGuide(.bottom) { d in d[.bottom] }
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                if message.role == .user {
                    Text(message.content)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.32, green: 0.36, blue: 0.65), Color(red: 0.24, green: 0.28, blue: 0.55)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                        )
                        .foregroundStyle(.white)
                        .font(.body)
                } else {
                    Text(message.content.isEmpty ? "…" : message.content)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .glassEffect(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .foregroundStyle(.white.opacity(0.9))
                        .font(.body)
                }

                if !message.sourcePages.isEmpty && message.role == .assistant {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text").font(.caption2)
                        Text("Pages \(message.sourcePages.map(String.init).joined(separator: ", "))")
                            .font(.caption2)
                    }
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.leading, 4)
                }
            }

            if message.role == .user { }
            if message.role == .assistant { Spacer(minLength: 60) }
        }
        .transition(.asymmetric(
            insertion: .move(edge: message.role == .user ? .trailing : .leading).combined(with: .opacity),
            removal: .opacity
        ))
    }
}
