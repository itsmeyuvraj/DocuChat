import Foundation

struct TextChunker {
    let chunkSize: Int
    let overlap: Int

    init(chunkSize: Int = 400, overlap: Int = 80) {
        self.chunkSize = chunkSize
        self.overlap = overlap
    }

    func chunk(text: String, page: Int) -> [(text: String, page: Int)] {
        let words = text.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard !words.isEmpty else { return [] }

        var chunks: [(String, Int)] = []
        var start = 0

        while start < words.count {
            let end = min(start + chunkSize, words.count)
            let chunk = words[start..<end].joined(separator: " ")
            let trimmed = chunk.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count > 20 {
                chunks.append((trimmed, page))
            }
            if end == words.count { break }
            start = end - overlap
        }
        return chunks
    }
}
