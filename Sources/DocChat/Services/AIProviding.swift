import Foundation

protocol AIProviding: Sendable {
    var displayName: String { get }
    var isConfigured: Bool { get }
    func streamAnswer(query: String, context: String) async -> AsyncThrowingStream<String, Error>
}

let systemPrompt = """
You are a helpful assistant that answers questions about documents.
Answer ONLY based on the provided document excerpts.
If the answer is not in the excerpts, say "I couldn't find that in the document."
Cite page numbers when relevant. Be concise.
"""
