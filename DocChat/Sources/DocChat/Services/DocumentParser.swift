import PDFKit
import Vision
import AppKit

actor DocumentParser {

    func parse(url: URL) async throws -> [(text: String, page: Int)] {
        switch url.pathExtension.lowercased() {
        case "pdf":
            return try await parsePDF(url: url)
        case "png", "jpg", "jpeg", "heic", "webp":
            return try await parseImage(url: url)
        case "txt", "md":
            return try parsePlainText(url: url)
        default:
            throw ParserError.unsupportedFormat(url.pathExtension)
        }
    }

    private func parsePDF(url: URL) async throws -> [(String, Int)] {
        guard let pdf = PDFDocument(url: url) else { throw ParserError.failedToLoad }
        var results: [(String, Int)] = []

        for i in 0..<pdf.pageCount {
            guard let page = pdf.page(at: i) else { continue }
            var text = page.string ?? ""

            if text.trimmingCharacters(in: .whitespacesAndNewlines).count < 50 {
                let size = CGSize(width: 1200, height: 1600)
                let image = page.thumbnail(of: size, for: .mediaBox)
                text = try await runOCR(on: image)
            }

            let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleaned.isEmpty { results.append((cleaned, i + 1)) }
        }
        return results
    }

    private func parseImage(url: URL) async throws -> [(String, Int)] {
        guard let image = NSImage(contentsOf: url) else { throw ParserError.failedToLoad }
        let text = try await runOCR(on: image)
        return [(text, 1)]
    }

    private func parsePlainText(url: URL) throws -> [(String, Int)] {
        let text = try String(contentsOf: url, encoding: .utf8)
        return [(text, 1)]
    }

    private func runOCR(on image: NSImage) async throws -> String {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return ""
        }
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { req, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let text = (req.results as? [VNRecognizedTextObservation])?
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n") ?? ""
                continuation.resume(returning: text)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            try? VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
        }
    }

    enum ParserError: LocalizedError {
        case unsupportedFormat(String)
        case failedToLoad

        var errorDescription: String? {
            switch self {
            case .unsupportedFormat(let ext): return "Unsupported format: .\(ext)"
            case .failedToLoad: return "Failed to load document"
            }
        }
    }
}
