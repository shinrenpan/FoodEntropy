import UIKit

// 圖片壓縮（02-architecture §3）：拍照 / 選圖當下縮圖 + JPEG 壓縮，不存原圖。
// 預設 JPEG 0.7、長邊上限 1024px，目標約 100–300KB/張。數值可滾動微調。
enum ImageCompressor {
    static let defaultMaxDimension: CGFloat = 1024
    static let defaultQuality: CGFloat = 0.7

    /// 將圖片等比縮至長邊上限後壓成 JPEG Data。
    static func compressedJPEGData(
        from image: UIImage,
        maxDimension: CGFloat = defaultMaxDimension,
        quality: CGFloat = defaultQuality
    ) -> Data? {
        resized(image, maxDimension: maxDimension).jpegData(compressionQuality: quality)
    }

    /// 等比縮圖：長邊超過上限才縮，否則原樣返回。
    static func resized(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let longestSide = max(image.size.width, image.size.height)
        guard longestSide > maxDimension else { return image }

        let scale = maxDimension / longestSide
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1                // 以點=像素輸出，避免 @2x/@3x 放大體積
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
