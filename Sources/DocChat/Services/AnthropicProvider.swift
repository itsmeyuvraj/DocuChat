import Foundation

struct AnthropicProvider: AIProviding {
    let apiKey: String
    let model: String

    var displayName: String { "Anthropic · \(model)" }
    var isConfigured: Bool { !apiKey.isEmpty }

    func streamAnswer(query: String, context: String) async -> AsyncThrowingStream<String, Error> {
        let key = apiKey
        let mdl = model
        let userMessage = "Document excerpts:\n\(context)\n\nQuestion: \(query)"

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
                    req.httpMethod = "POST"
                    req.setValue(key, forHTTPHeaderField: "x-api-key")
                    req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    req.httpBody = try JSONSerialization.data(withJSONObject: [
                        "model": mdl,
                        "max_tokens": 1024,
                        "stream": true,
                        "system": systemPrompt,
                        "messages": [["role": "user", "content": userMessage]]
                    ])

                    let (bytes, response) = try await URLSession.shared.bytes(for: req)
                    if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                        throw ProviderError.httpError(http.statusCode)
                    }

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: "),
                              let data = String(line.dropFirst(6)).data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let type_ = json["type"] as? String,
                              type_ == "content_block_delta",
                              let delta = json["delta"] as? [String: Any],
                              let text = delta["text"] as? String else { continue }
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
