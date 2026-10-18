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

        // scale 1: newSize를 포인트가 아닌 픽셀로 렌더링한다. 기본 포맷은 기기 스케일(2x/3x)을 따라
        // 그만큼 큰 비트맵을 만들므로 maxDimension이 픽셀 상한으로 동작하지 않는다.
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let resized = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resized.jpegData(compressionQuality: 0.85)
    }
}
