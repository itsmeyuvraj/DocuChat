import Foundation

struct OpenAIProvider: AIProviding {
    let apiKey: String
    let model: String

    var displayName: String { "OpenAI · \(model)" }
    var isConfigured: Bool { !apiKey.isEmpty }

    func streamAnswer(query: String, context: String) async -> AsyncThrowingStream<String, Error> {
        let key = apiKey
        let mdl = model
        let userMessage = "Document excerpts:\n\(context)\n\nQuestion: \(query)"

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    var req = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
                    req.httpMethod = "POST"
                    req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
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
                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))
                        guard payload != "[DONE]",
                              let data = payload.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let choices = json["choices"] as? [[String: Any]],
                              let delta = choices.first?["delta"] as? [String: Any],
                              let text = delta["content"] as? String else { continue }
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
