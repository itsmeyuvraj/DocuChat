import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@main
struct DocChatApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var documentStore    = DocumentStore()
    @StateObject private var providerSettings = ProviderSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(documentStore)
                .environmentObject(providerSettings)
                .environmentObject(LLMService(settings: providerSettings))
                .frame(minWidth: 960, minHeight: 640)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Document...") {
                    NotificationCenter.default.post(name: .openDocument, object: nil)
                }
                .keyboardShortcut("o")
            }
        }
    }
}

extension Notification.Name {
    static let openDocument = Notification.Name("openDocument")
    static let importURLs   = Notification.Name("importURLs")
}
