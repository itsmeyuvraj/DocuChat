import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            VStack(spacing: 24) {
                // App icon + name
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(LinearGradient(
                                colors: [Color(red: 0.42, green: 0.45, blue: 0.72), Color(red: 0.28, green: 0.32, blue: 0.58)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .frame(width: 80, height: 80)
                            .shadow(color: Color(red: 0.40, green: 0.43, blue: 0.70).opacity(0.5), radius: 16, y: 6)
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundStyle(.white)
                    }

                    VStack(spacing: 4) {
                        Text("DocChat")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                        Text("Version \(version) (Build \(build))")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }

                Divider().opacity(0.15)

                // Developer info
                VStack(spacing: 14) {
                    InfoRow(icon: "person.fill", label: "Developer", value: "Yuvraj Poudyal")
                    InfoRow(icon: "envelope.fill", label: "Contact", value: "itsmeyuvraj@protonmail.com")
                    InfoRow(icon: "chevron.left.forwardslash.chevron.right", label: "GitHub", value: "github.com/itsmeyuvraj")
                    InfoRow(icon: "doc.text.fill", label: "License", value: "MIT")
                }
                .padding(16)
                .glassEffect(in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                Divider().opacity(0.15)

                Text("Built with Apple Intelligence, PDFKit, and Vision.\nAll processing happens entirely on your Mac.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
            .padding(.top, 8)
        }
        .frame(width: 340)
        .background {
            LinearGradient(
                colors: [Color(red: 0.07, green: 0.08, blue: 0.13), Color(red: 0.10, green: 0.10, blue: 0.18)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
}

private struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(Color(red: 0.55, green: 0.57, blue: 0.85))
                .frame(width: 18)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}
