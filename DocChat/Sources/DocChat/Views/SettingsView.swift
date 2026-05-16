import SwiftUI
import FoundationModels

struct SettingsView: View {
    @EnvironmentObject private var settings: ProviderSettings
    @Environment(\.dismiss) private var dismiss
    @State private var showKey = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("AI Provider")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(24)

            Divider().opacity(0.15)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(ProviderType.allCases) { type in
                        ProviderCard(type: type, isSelected: settings.selected == type) {
                            withAnimation(.spring(duration: 0.3)) { settings.selected = type }
                        }

                        // Config expands inline directly below its card
                        if settings.selected == type && type != .appleIntelligence {
                            providerConfig
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                }
                .padding(20)
            }

            Divider().opacity(0.15)

            Button {
                dismiss()
            } label: {
                Text("Save")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.glassProminent)
            .padding(20)
        }
        .frame(width: 420, height: 600)
        .background {
            LinearGradient(
                colors: [Color(red: 0.07, green: 0.08, blue: 0.13), Color(red: 0.10, green: 0.10, blue: 0.18)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var providerConfig: some View {
        VStack(alignment: .leading, spacing: 14) {
            switch settings.selected {
            case .openAI:
                labeledField("API Key", placeholder: "sk-…", text: $settings.openAIKey, secure: true)
                labeledPicker("Model", selection: $settings.openAIModel, options: ProviderSettings.openAIModels)

            case .anthropic:
                labeledField("API Key", placeholder: "sk-ant-…", text: $settings.anthropicKey, secure: true)
                labeledPicker("Model", selection: $settings.anthropicModel, options: ProviderSettings.anthropicModels)

            case .ollama:
                labeledField("Server URL", placeholder: "http://localhost:11434", text: $settings.ollamaURL, secure: false)
                labeledField("Model name", placeholder: "llama3.2", text: $settings.ollamaModel, secure: false)
                Text("Make sure Ollama is running: `ollama serve`")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.35))

            default: EmptyView()
            }
        }
        .padding(16)
        .glassEffect(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func labeledField(_ label: String, placeholder: String, text: Binding<String>, secure: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.5))
            Group {
                if secure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                }
            }
            .textFieldStyle(.plain)
            .font(.body.monospaced())
            .foregroundStyle(.white)
            .padding(10)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private func labeledPicker(_ label: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.5))
            Picker("", selection: selection) {
                ForEach(options, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            .padding(6)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct ProviderCard: View {
    let type: ProviderType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected
                            ? LinearGradient(colors: [Color(red: 0.45, green: 0.48, blue: 0.75), Color(red: 0.32, green: 0.35, blue: 0.62)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [.white.opacity(0.08), .white.opacity(0.08)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 40, height: 40)
                    Image(systemName: type.icon)
                        .font(.system(size: 17))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(type.label)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(subtitle(for: type))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(red: 0.55, green: 0.57, blue: 0.85))
                        .font(.title3)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(isSelected ? Color(red: 0.50, green: 0.53, blue: 0.80).opacity(0.6) : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.25), value: isSelected)
    }

    private func subtitle(for type: ProviderType) -> String {
        switch type {
        case .appleIntelligence: return "On-device · Private · No API key"
        case .openAI:            return "GPT-4o and more · Requires API key"
        case .anthropic:         return "Claude models · Requires API key"
        case .ollama:            return "Any local model · Requires Ollama app"
        }
    }
}
