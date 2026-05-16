import Foundation
import FoundationModels

struct AppleIntelligenceProvider: AIProviding {
    let displayName = "Apple Intelligence"

    var isConfigured: Bool {
        SystemLanguageModel.default.isAvailable
    }

    func streamAnswer(query: String, context: String) async -> AsyncThrowingStream<String, Error> {
        let prompt = "Document excerpts:\n\(context)\n\nQuestion: \(query)"
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let session = LanguageModelSession(instructions: systemPrompt)
                    var last = ""
                    for try await snapshot in session.streamResponse(to: prompt) {
                        let new = String(snapshot.content.dropFirst(last.count))
                        if !new.isEmpty { continuation.yield(new) }
                        last = snapshot.content
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
