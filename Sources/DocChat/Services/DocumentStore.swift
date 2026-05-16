import Foundation
import Combine

@MainActor
class DocumentStore: ObservableObject {
    @Published var documents: [Document] = []
    @Published var isImporting = false
    @Published var importProgress: Double = 0
    @Published var importError: String?

    private static let storageDir: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DocChat")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private static var documentsFile: URL { storageDir.appendingPathComponent("documents.json") }
    private static func chunksFile(for id: String) -> URL {
        storageDir.appendingPathComponent("chunks-\(id).json")
    }

    private static func messagesFile(for id: String) -> URL {
        storageDir.appendingPathComponent("messages-\(id).json")
    }

    func loadMessages(for documentId: String) -> [ChatMessage] {
        guard let data = try? Data(contentsOf: Self.messagesFile(for: documentId)),
              let messages = try? JSONDecoder().decode([ChatMessage].self, from: data) else { return [] }
        return messages
    }

    func saveMessages(_ messages: [ChatMessage], for documentId: String) {
        try? JSONEncoder().encode(messages).write(to: Self.messagesFile(for: documentId))
    }

    init() { load() }

    private func load() {
        guard let data = try? Data(contentsOf: Self.documentsFile),
              let docs = try? JSONDecoder().decode([Document].self, from: data) else { return }
        documents = docs
    }

    private func save() {
        try? JSONEncoder().encode(documents).write(to: Self.documentsFile)
    }

    func chunks(for documentId: String) -> [Chunk] {
        guard let data = try? Data(contentsOf: Self.chunksFile(for: documentId)),
              let chunks = try? JSONDecoder().decode([Chunk].self, from: data) else { return [] }
        return chunks
    }

    @discardableResult
    func importDocument(url: URL) async -> Document? {
        isImporting = true
        importProgress = 0
        importError = nil

        let result = await Task.detached(priority: .userInitiated) {
            await Self.processDocument(url: url)
        }.value

        switch result {
        case .success(let (doc, chunks, file)):
            try? JSONEncoder().encode(chunks).write(to: file)
            documents.insert(doc, at: 0)
            save()
            isImporting = false
            return doc
        case .failure(let error):
            importError = error.localizedDescription
            isImporting = false
            return nil
        }
    }

    func delete(_ document: Document) {
        try? FileManager.default.removeItem(at: Self.chunksFile(for: document.id))
        documents.removeAll { $0.id == document.id }
        save()
    }

    // Heavy work — runs off main actor
    private static func processDocument(url: URL) async -> Result<(Document, [Chunk], URL), Error> {
        let parser = DocumentParser()
        let chunker = TextChunker()
        let embedder = EmbeddingService()
        do {
            let pages = try await parser.parse(url: url)
            let rawChunks = pages.flatMap { chunker.chunk(text: $0.text, page: $0.page) }

            var doc = Document(
                name: url.deletingPathExtension().lastPathComponent,
                path: url.path,
                pageCount: pages.count
            )

            let chunks = rawChunks.map { raw in
                Chunk(documentId: doc.id, text: raw.text, pageNumber: raw.page,
                      embeddingData: embedder.embed(raw.text).asData)
            }

            doc.isProcessed = true
            doc.chunkCount = chunks.count
            return .success((doc, chunks, chunksFile(for: doc.id)))
        } catch {
            return .failure(error)
        }
    }
}
