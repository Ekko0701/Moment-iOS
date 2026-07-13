import Foundation
import UIKit

extension UIImage {
    /// 긴 변을 maxDimension으로 리사이즈하고 JPEG로 인코딩한다.
    /// EXIF 메타데이터는 제거된다.
    public func resizedAndCompressed(maxDimension: CGFloat = 2048) -> Data? {
        let maxSize = max(self.size.width, self.size.height)
        let scale = min(1.0, maxDimension / maxSize)

        let newSize = CGSize(
            width: self.size.width * scale,
            height: self.size.height * scale
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resized.jpegData(compressionQuality: 0.85)
    }
}
