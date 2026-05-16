import SwiftUI

struct DocumentLibraryView: View {
    @EnvironmentObject private var store: DocumentStore
    @EnvironmentObject private var providerSettings: ProviderSettings
    @Binding var selectedDocument: Document?
    @State private var showSettings = false
    @State private var showAbout = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DocChat")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("\(store.documents.count) documents")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                Button { showAbout = true } label: {
                    Image(systemName: "info.circle")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.glass)
                .help("About DocChat")

                Button { showSettings = true } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.glass)
                .help("AI Settings")

                Button {
                    NotificationCenter.default.post(name: .openDocument, object: nil)
                } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.glass)
                .help("Import Document")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)

            Divider().opacity(0.15)

            if store.documents.isEmpty && !store.isImporting {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(store.documents) { doc in
                            DocumentCard(document: doc, isSelected: selectedDocument?.id == doc.id)
                                .onTapGesture { withAnimation(.spring(duration: 0.3)) { selectedDocument = doc } }
                                .contextMenu {
                                    Button("Delete", role: .destructive) {
                                        if selectedDocument?.id == doc.id { selectedDocument = nil }
                                        store.delete(doc)
                                    }
                                }
                        }
                    }
                    .padding(12)
                }
            }

            if store.isImporting {
                importingBar
            }
        }
        .background(.ultraThinMaterial.opacity(0.4))
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(providerSettings)
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .importURLs)) { note in
            guard let urls = note.object as? [URL] else { return }
            Task { @MainActor in
                for url in urls {
                    if let doc = await store.importDocument(url: url) {
                        withAnimation { selectedDocument = doc }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.3))
            Text("No documents yet")
                .font(.callout.weight(.medium))
                .foregroundStyle(.white.opacity(0.4))
            Text("Tap + to import a PDF or image")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.25))
            Spacer()
        }
    }

    private var importingBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Processing…").font(.caption).foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text("\(Int(store.importProgress * 100))%")
                    .font(.caption.monospacedDigit()).foregroundStyle(.white.opacity(0.5))
            }
            ProgressView(value: store.importProgress)
                .tint(Color(red: 0.50, green: 0.53, blue: 0.80))
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(12)
    }
}

struct DocumentCard: View {
    let document: Document
    let isSelected: Bool

    private var fileType: FileType {
        switch URL(fileURLWithPath: document.path).pathExtension.lowercased() {
        case "pdf":                          return .pdf
        case "png", "jpg", "jpeg", "heic", "webp": return .image
        case "txt", "md":                    return .text
        default:                             return .text
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // File type icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        colors: fileType.gradient,
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 36, height: 36)
                Image(systemName: fileType.icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(document.name)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(fileType.label)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(fileType.gradient.first ?? .white)
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.3))
                    Text("\(document.pageCount)p · \(document.chunkCount) chunks")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isSelected ? Color.white.opacity(0.3) : Color.clear,
                            lineWidth: 1
                        )
                )
        )
        .animation(.spring(duration: 0.2), value: isSelected)
    }
}

enum FileType {
    case pdf, image, text

    var icon: String {
        switch self {
        case .pdf:   return "doc.richtext.fill"
        case .image: return "photo.fill"
        case .text:  return "doc.plaintext.fill"
        }
    }

    var label: String {
        switch self {
        case .pdf:   return "PDF"
        case .image: return "Image"
        case .text:  return "Text"
        }
    }

    var gradient: [Color] {
        switch self {
        case .pdf:   return [Color(red: 0.9, green: 0.25, blue: 0.25), Color(red: 0.7, green: 0.1, blue: 0.1)]
        case .image: return [Color(red: 0.2, green: 0.6, blue: 0.95), Color(red: 0.1, green: 0.4, blue: 0.8)]
        case .text:  return [Color(red: 0.35, green: 0.75, blue: 0.45), Color(red: 0.15, green: 0.55, blue: 0.3)]
        }
    }
}
