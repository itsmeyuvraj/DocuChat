import Foundation

struct VectorStore {
    private let embedder = EmbeddingService()

    func search(query: String, chunks: [Chunk], topK: Int = 4) -> [Chunk] {
        let queryVec = embedder.embed(query)
        return chunks
            .map { ($0, embedder.similarity(queryVec, [Float].fromData($0.embeddingData))) }
            .sorted { $0.1 > $1.1 }
            .prefix(topK)
            .map { $0.0 }
    }
}
