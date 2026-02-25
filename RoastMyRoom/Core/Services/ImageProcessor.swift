import UIKit

enum ImageProcessorError: Error, LocalizedError {
    case notARoom
    case tooSmall
    case compressionFailed

    var errorDescription: String? {
        switch self {
        case .notARoom:
            return String(localized: "error_not_a_room")
        case .tooSmall:
            return String(localized: "error_image_too_small")
        case .compressionFailed:
            return String(localized: "error_compression_failed")
        }
    }
}

protocol ImageProcessorProtocol: Sendable {
    nonisolated func prepare(_ image: UIImage) throws -> Data
}

final class ImageProcessor: ImageProcessorProtocol, @unchecked Sendable {
    nonisolated func prepare(_ image: UIImage) throws -> Data {
        // Validate minimum size
        guard image.size.width >= 100 && image.size.height >= 100 else {
            throw ImageProcessorError.tooSmall
        }

        // Resize to max 768×576 — GPT-4o Vision detail:low downscales to 512×512 anyway
        let resized = image.resized(maxWidth: 768, maxHeight: 576)

        // Compress to JPEG 0.6 — keeps enough quality for AI analysis, reduces payload
        guard let data = resized.compressedJPEG(quality: 0.6) else {
            throw ImageProcessorError.compressionFailed
        }

        return data
    }
}
