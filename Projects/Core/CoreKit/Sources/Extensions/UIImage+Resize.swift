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

        // scale을 1로 고정해야 newSize가 "픽셀"이 된다. 기본 포맷은 기기 스케일(3x)을 따라가서
        // 2048pt → 6144px로 렌더링되고, 2026-10-18 운영 첫 업로드가 4100×6144(4.3MB)로 올라갔다.
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let resized = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resized.jpegData(compressionQuality: 0.85)
    }
}
