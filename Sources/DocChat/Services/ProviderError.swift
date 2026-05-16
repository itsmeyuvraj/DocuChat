import Foundation

enum ProviderError: LocalizedError {
    case httpError(Int)
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .httpError(let code): return "API error \(code) — check your API key in Settings"
        case .notConfigured: return "Provider not configured — open Settings to add your API key"
        }
    }
}
