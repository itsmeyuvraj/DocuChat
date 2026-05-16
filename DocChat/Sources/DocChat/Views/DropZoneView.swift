import SwiftUI

struct DropZoneView: View {
    @EnvironmentObject private var store: DocumentStore
    @Binding var selectedDocument: Document?
    @State private var isTargeted = false
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 0.45, green: 0.48, blue: 0.75).opacity(0.25), Color.clear],
                            center: .center, startRadius: 0, endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(pulse ? 1.15 : 1.0)
                    .opacity(pulse ? 0.6 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulse)

                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.42, green: 0.45, blue: 0.72).opacity(0.55), Color(red: 0.30, green: 0.38, blue: 0.62).opacity(0.55)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 88)
                        .glassEffect(in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white.opacity(0.9))
                        .symbolEffect(.bounce, options: .repeating, value: isTargeted)
                }
            }
            .onAppear { pulse = true }

            VStack(spacing: 10) {
                Text(isTargeted ? "Release to Import" : "Drop Your Document")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .animation(.spring(), value: isTargeted)

                Text("PDF, images, or text files\nProcessed entirely on your Mac with Apple Intelligence")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button("Choose File…") {
                NotificationCenter.default.post(name: .openDocument, object: nil)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .font(.body.weight(.semibold))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: isTargeted ? 24 : 0)
                .strokeBorder(
                    LinearGradient(
                        colors: isTargeted ? [Color(red: 0.50, green: 0.53, blue: 0.80), Color(red: 0.35, green: 0.45, blue: 0.72)] : [Color.clear],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .padding(isTargeted ? 16 : 0)
                .animation(.spring(duration: 0.3), value: isTargeted)
        )
        .dropDestination(for: URL.self) { urls, _ in
            Task { @MainActor in
                for url in urls {
                    if let doc = await store.importDocument(url: url) {
                        withAnimation { selectedDocument = doc }
                    }
                }
            }
            return true
        } isTargeted: { targeted in
            withAnimation(.spring(duration: 0.3)) { isTargeted = targeted }
        }
    }
}
