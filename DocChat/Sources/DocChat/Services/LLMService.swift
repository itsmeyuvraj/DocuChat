import Foundation
import FoundationModels
import Combine

@MainActor
class LLMService: ObservableObject {
    @Published var providerSettings: ProviderSettings

    init(settings: ProviderSettings) {
        self.providerSettings = settings
    }

    var isAvailable: Bool {
        let p = providerSettings.makeProvider()
        return p.isConfigured
    }

    var currentProviderName: String {
        providerSettings.makeProvider().displayName
    }

    func streamAnswer(query: String, context: String) async -> AsyncThrowingStream<String, Error> {
        let provider = providerSettings.makeProvider()
        guard provider.isConfigured else {
            return AsyncThrowingStream { $0.finish(throwing: ProviderError.notConfigured) }
        }
        return await provider.streamAnswer(query: query, context: context)
    }
}
