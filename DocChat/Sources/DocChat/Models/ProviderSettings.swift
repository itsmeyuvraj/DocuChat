import Foundation
import Combine

enum ProviderType: String, CaseIterable, Identifiable, Codable {
    case appleIntelligence = "apple"
    case openAI            = "openai"
    case anthropic         = "anthropic"
    case ollama            = "ollama"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .appleIntelligence: return "Apple Intelligence"
        case .openAI:            return "OpenAI"
        case .anthropic:         return "Anthropic"
        case .ollama:            return "Ollama"
        }
    }

    var icon: String {
        switch self {
        case .appleIntelligence: return "apple.logo"
        case .openAI:            return "sparkles"
        case .anthropic:         return "brain.head.profile"
        case .ollama:            return "server.rack"
        }
    }

    var requiresKey: Bool {
        switch self {
        case .appleIntelligence, .ollama: return false
        case .openAI, .anthropic:         return true
        }
    }
}

@MainActor
class ProviderSettings: ObservableObject {
    @Published var selected: ProviderType     { didSet { save() } }
    @Published var openAIKey: String          { didSet { save() } }
    @Published var openAIModel: String        { didSet { save() } }
    @Published var anthropicKey: String       { didSet { save() } }
    @Published var anthropicModel: String     { didSet { save() } }
    @Published var ollamaURL: String          { didSet { save() } }
    @Published var ollamaModel: String        { didSet { save() } }

    static let openAIModels    = ["gpt-4o", "gpt-4o-mini", "gpt-4-turbo", "gpt-3.5-turbo"]
    static let anthropicModels = ["claude-sonnet-4-5", "claude-opus-4-5", "claude-haiku-4-5"]

    init() {
        let d = UserDefaults.standard
        selected       = ProviderType(rawValue: d.string(forKey: "providerType") ?? "") ?? .appleIntelligence
        openAIKey      = d.string(forKey: "openAIKey")      ?? ""
        openAIModel    = d.string(forKey: "openAIModel")    ?? "gpt-4o"
        anthropicKey   = d.string(forKey: "anthropicKey")   ?? ""
        anthropicModel = d.string(forKey: "anthropicModel") ?? "claude-sonnet-4-5"
        ollamaURL      = d.string(forKey: "ollamaURL")      ?? "http://localhost:11434"
        ollamaModel    = d.string(forKey: "ollamaModel")    ?? "llama3.2"
    }

    private func save() {
        let d = UserDefaults.standard
        d.set(selected.rawValue, forKey: "providerType")
        d.set(openAIKey,         forKey: "openAIKey")
        d.set(openAIModel,       forKey: "openAIModel")
        d.set(anthropicKey,      forKey: "anthropicKey")
        d.set(anthropicModel,    forKey: "anthropicModel")
        d.set(ollamaURL,         forKey: "ollamaURL")
        d.set(ollamaModel,       forKey: "ollamaModel")
    }

    func makeProvider() -> any AIProviding {
        switch selected {
        case .appleIntelligence: return AppleIntelligenceProvider()
        case .openAI:            return OpenAIProvider(apiKey: openAIKey, model: openAIModel)
        case .anthropic:         return AnthropicProvider(apiKey: anthropicKey, model: anthropicModel)
        case .ollama:            return OllamaProvider(baseURL: ollamaURL, model: ollamaModel)
        }
    }
}
