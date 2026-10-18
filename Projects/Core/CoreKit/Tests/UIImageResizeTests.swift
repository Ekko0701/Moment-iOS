import Testing
import UIKit
@testable import CoreKit

/// resizedAndCompressed의 출력 크기 규약을 검증한다. maxDimension은 기기 스케일과 무관한 픽셀 상한이며,
/// 긴 변 기준으로 축소만 하고 확대는 하지 않는다. 결과 JPEG를 다시 디코드해 실제 픽셀 크기로 판정한다.
private func solidImage(width: Int, height: Int) -> UIImage {
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1
    return UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { ctx in
        UIColor.systemTeal.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
    }
}

private func pixelSize(of jpeg: Data) -> CGSize? {
    guard let image = UIImage(data: jpeg), let cg = image.cgImage else { return nil }
    return CGSize(width: cg.width, height: cg.height)
}

@Test("긴 변이 maxDimension을 넘는 사진은 픽셀 기준으로 그 크기까지만 줄어든다 (기기 스케일 무관)")
func downscalesToMaxDimensionInPixels() throws {
    let data = try #require(solidImage(width: 4032, height: 3024).resizedAndCompressed(maxDimension: 2048))
    let size = try #require(pixelSize(of: data))

    #expect(size.width == 2048)
    #expect(size.height == 1536)
}

@Test("세로 사진도 긴 변 기준으로 줄어든다")
func downscalesPortrait() throws {
    let data = try #require(solidImage(width: 3000, height: 4000).resizedAndCompressed(maxDimension: 2048))
    let size = try #require(pixelSize(of: data))

    #expect(size.height == 2048)
    #expect(size.width == 1536)
}

@Test("maxDimension보다 작은 사진은 확대하지 않는다")
func doesNotUpscale() throws {
    let data = try #require(solidImage(width: 640, height: 480).resizedAndCompressed(maxDimension: 2048))
    let size = try #require(pixelSize(of: data))

    #expect(size.width == 640)
    #expect(size.height == 480)
}

@Test("위젯용 800px 축소도 같은 규칙을 따른다")
func widgetSizeAlsoInPixels() throws {
    let data = try #require(solidImage(width: 4032, height: 3024).resizedAndCompressed(maxDimension: 800))
    let size = try #require(pixelSize(of: data))

    #expect(size.width == 800)
    #expect(size.height == 600)
}
