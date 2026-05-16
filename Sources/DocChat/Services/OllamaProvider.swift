import Foundation

struct OllamaProvider: AIProviding {
    let baseURL: String
    let model: String

    var displayName: String { "Ollama · \(model)" }
    var isConfigured: Bool { !model.isEmpty }

    func streamAnswer(query: String, context: String) async -> AsyncThrowingStream<String, Error> {
        let url = baseURL.isEmpty ? "http://localhost:11434" : baseURL
        let mdl = model
        let userMessage = "Document excerpts:\n\(context)\n\nQuestion: \(query)"

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    var req = URLRequest(url: URL(string: "\(url)/api/chat")!)
                    req.httpMethod = "POST"
                    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    req.httpBody = try JSONSerialization.data(withJSONObject: [
                        "model": mdl,
                        "stream": true,
                        "messages": [
                            ["role": "system", "content": systemPrompt],
                            ["role": "user", "content": userMessage]
                        ]
                    ])

                    let (bytes, response) = try await URLSession.shared.bytes(for: req)
                    if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                        throw ProviderError.httpError(http.statusCode)
                    }

                    for try await line in bytes.lines {
                        guard let data = line.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let message = json["message"] as? [String: Any],
                              let text = message["content"] as? String,
                              !text.isEmpty else { continue }
                        continuation.yield(text)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
