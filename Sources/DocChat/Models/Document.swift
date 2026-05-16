import Foundation

struct Document: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var path: String
    var createdAt: Date = Date()
    var pageCount: Int = 0
    var isProcessed: Bool = false
    var chunkCount: Int = 0
}

struct Chunk: Identifiable, Codable {
    var id: String = UUID().uuidString
    var documentId: String
    var text: String
    var pageNumber: Int
    var embeddingData: Data
}

struct ChatMessage: Identifiable, Codable {
    var id: String = UUID().uuidString
    var role: Role
    var content: String
    var sourcePages: [Int] = []

    enum Role: String, Codable { case user, assistant }
}

