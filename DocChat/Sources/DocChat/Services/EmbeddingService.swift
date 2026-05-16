import NaturalLanguage

struct EmbeddingService {
    private let embedding = NLEmbedding.wordEmbedding(for: .english)
    static let dimensions = 300

    func embed(_ text: String) -> [Float] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        var vectors: [[Double]] = []

        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let word = String(text[range]).lowercased()
            if let vector = embedding?.vector(for: word) {
                vectors.append(vector)
            }
            return true
        }

        guard !vectors.isEmpty else {
            return [Float](repeating: 0, count: Self.dimensions)
        }

        let mean = (0..<Self.dimensions).map { dim -> Float in
            Float(vectors.map { $0[dim] }.reduce(0, +) / Double(vectors.count))
        }
        return normalize(mean)
    }

    func similarity(_ a: [Float], _ b: [Float]) -> Float {
        zip(a, b).map(*).reduce(0, +)
    }

    private func normalize(_ v: [Float]) -> [Float] {
        let magnitude = sqrt(v.map { $0 * $0 }.reduce(0, +))
        guard magnitude > 0 else { return v }
        return v.map { $0 / magnitude }
    }
}

extension [Float] {
    var asData: Data { withUnsafeBytes { Data($0) } }

    static func fromData(_ data: Data) -> [Float] {
        data.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
    }
}
