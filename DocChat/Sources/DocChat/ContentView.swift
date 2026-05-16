import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: DocumentStore
    @EnvironmentObject private var providerSettings: ProviderSettings
    @State private var selectedDocument: Document?

    var body: some View {
        ZStack {
            // Full-window gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.08, blue: 0.13),
                    Color(red: 0.10, green: 0.10, blue: 0.18),
                    Color(red: 0.07, green: 0.10, blue: 0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            NavigationSplitView {
                DocumentLibraryView(selectedDocument: $selectedDocument)
                    .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
            } detail: {
                if let doc = selectedDocument {
                    ChatView(document: doc)
                        .id(doc.id)
                } else {
                    DropZoneView(selectedDocument: $selectedDocument)
                }
            }
            .navigationSplitViewStyle(.balanced)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openDocument)) { _ in
            openFilePicker()
        }
    }

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf, .plainText, .png, .jpeg, .heic]
        panel.allowsMultipleSelection = true
        if panel.runModal() == .OK {
            NotificationCenter.default.post(name: .importURLs, object: panel.urls)
        }
    }
}
