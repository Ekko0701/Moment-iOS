import SwiftUI
import UIKit
import Testing
@testable import CoreKit

@Test("Pretendard는 굵기마다 정해진 글꼴 파일을 고른다")
func pretendardFontNames() {
    #expect(Pretendard.fontName(for: Font.Weight.regular) == "Pretendard-Regular")
    #expect(Pretendard.fontName(for: Font.Weight.medium) == "Pretendard-Medium")
    #expect(Pretendard.fontName(for: Font.Weight.semibold) == "Pretendard-SemiBold")
    #expect(Pretendard.fontName(for: Font.Weight.bold) == "Pretendard-Bold")
    #expect(Pretendard.fontName(for: Font.Weight.thin) == "Pretendard-Regular")
    #expect(Pretendard.fontName(for: Font.Weight.heavy) == "Pretendard-Bold")
}

@Test("UIKit 굵기도 같은 글꼴 파일로 이어진다")
func pretendardUIFontNames() {
    #expect(Pretendard.fontName(for: UIFont.Weight.regular) == "Pretendard-Regular")
    #expect(Pretendard.fontName(for: UIFont.Weight.semibold) == "Pretendard-SemiBold")
    #expect(Pretendard.fontName(for: UIFont.Weight.black) == "Pretendard-Bold")
}
