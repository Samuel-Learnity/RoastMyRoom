import UIKit

extension UIImage {
    nonisolated func resized(maxWidth: CGFloat = 1024, maxHeight: CGFloat = 768) -> UIImage {
        let aspectRatio = size.width / size.height
        var targetSize: CGSize

        if aspectRatio > maxWidth / maxHeight {
            targetSize = CGSize(width: maxWidth, height: maxWidth / aspectRatio)
        } else {
            targetSize = CGSize(width: maxHeight * aspectRatio, height: maxHeight)
        }

        // No upscaling
        if size.width <= targetSize.width && size.height <= targetSize.height {
            return self
        }

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    nonisolated func compressedJPEG(quality: CGFloat = 0.8) -> Data? {
        jpegData(compressionQuality: quality)
    }
}
