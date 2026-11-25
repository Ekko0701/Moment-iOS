import PhotosUI
import SwiftUI
import UIKit
import CoreKit
import Domain
import MomentUIKit

/// 사진 위에 글씨를 쓰는 편집기. 글씨는 사진 왼쪽 위 또는 왼쪽 아래에서 시작하고, 색을 고를 수 있다.
/// 보는 화면(홈·지난 순간·위젯)과 같은 모습으로 그려 올리기 전에 결과를 확인하게 한다.
struct PhotoComposeView: View {
    let state: ComposeFeature.State
    let send: (ComposeFeature.Action) -> Void
    /// 디코드가 끝난 사진. 아직이면 nil
    let photo: UIImage?
    let destinationTitle: (Space) -> String
    @Binding var pickerItem: PhotosPickerItem?

    @FocusState private var isTextFocused: Bool

    private static let background = Color(red: 0.055, green: 0.051, blue: 0.055)
    private static let chipFill = Color.white.opacity(0.14)
    /// 흰 버튼 위 글자색. 편집기는 화면 모드와 상관없이 늘 어두운 바탕이라 고정 색을 쓴다
    private static let ink = Color(red: 0.110, green: 0.110, blue: 0.118)

    private var position: PhotoTextPosition { PhotoTextPosition(name: state.textStyle.position.rawValue) }
    private var color: PhotoTextColor { PhotoTextColor(name: state.textStyle.color.rawValue) }

    var body: some View {
        ZStack {
            Self.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    header
                    photoCanvas
                    controls
                    hint
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.xs)
                .padding(.bottom, Spacing.md)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        // 글씨를 쓰는 동안에는 키보드 위에 "완료"만 두고, 보낼 곳·공유 버튼은 키보드를 내린 뒤에 보여 준다
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !isTextFocused {
                bottomBar
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .statusBarHidden()
    }

    // MARK: - 위쪽 버튼

    private var header: some View {
        HStack {
            Button {
                send(.clearImage)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Self.chipFill)
                    .clipShape(Circle())
            }
            .buttonStyle(MomentPressStyle())
            .accessibilityLabel("사진 빼기")

            Spacer()

            PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Self.chipFill)
                    .clipShape(Circle())
            }
            .accessibilityLabel("사진 바꾸기")
        }
        .disabled(state.isUploading || state.isProcessingPhoto)
    }

    // MARK: - 사진과 글씨

    private var photoCanvas: some View {
        Color.clear
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
            .overlay {
                if let photo {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .accessibilityLabel("고른 사진")
                } else {
                    ProgressView().tint(.white)
                }
            }
            .overlay { PhotoTextScrim(position: position, color: color) }
            .overlay {
                GeometryReader { proxy in
                    let metrics = PhotoTextMetrics(photoWidth: proxy.size.width)
                    textField(metrics)
                        .frame(width: proxy.size.width, height: proxy.size.height, alignment: position.alignment)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .animation(.easeOut(duration: 0.2), value: state.textStyle)
    }

    private func textField(_ metrics: PhotoTextMetrics) -> some View {
        TextField(
            "",
            text: Binding(get: { state.text }, set: { send(.textChanged($0)) }),
            prompt: Text("글씨를 입력해 보세요").foregroundColor(color.color.opacity(0.75)),
            axis: .vertical
        )
        .photoTextStyle(color: color, fontSize: metrics.fontSize)
        .lineLimit(1...6)
        .tint(color.color)
        .focused($isTextFocused)
        .disabled(state.isUploading)
        .accessibilityLabel("사진 위 글씨")
        .padding(6)
        // 글씨가 들어갈 자리를 점선으로 알려 준다. 글을 쓰고 키보드를 내리면 사라진다
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                .foregroundColor(.white.opacity(showsOutline ? 0.9 : 0))
        }
        .padding(.leading, metrics.inset - 6)
        .padding(.vertical, metrics.inset - 6)
        .padding(.trailing, metrics.trailingInset - 6)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("완료") { isTextFocused = false }
            }
        }
    }

    private var showsOutline: Bool { isTextFocused || state.text.isEmpty }

    // MARK: - 위치와 색

    private var controls: some View {
        HStack(spacing: Spacing.xs) {
            positionPicker
            Spacer(minLength: 0)
            colorPicker
        }
        .disabled(state.isUploading)
    }

    private var positionPicker: some View {
        HStack(spacing: 0) {
            positionButton(.top, title: "위", systemImage: "arrow.up.to.line")
            positionButton(.bottom, title: "아래", systemImage: "arrow.down.to.line")
        }
        .padding(3)
        .background(Self.chipFill)
        .clipShape(Capsule())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("글씨 위치")
    }

    private func positionButton(_ value: MomentTextPosition, title: String, systemImage: String) -> some View {
        let isSelected = state.textStyle.position == value
        return Button {
            send(.textPositionSelected(value))
        } label: {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.pretendard(size: 13, weight: .semibold))
            }
            .foregroundColor(isSelected ? Self.ink : .white)
            .padding(.horizontal, 14)
            .frame(height: 38)
            .background(isSelected ? Color.white : Color.clear)
            .clipShape(Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(MomentPressStyle())
        .accessibilityLabel(value == .top ? "왼쪽 위" : "왼쪽 아래")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var colorPicker: some View {
        HStack(spacing: 0) {
            ForEach(MomentTextColor.allCases, id: \.self) { value in
                let swatch = PhotoTextColor(name: value.rawValue)
                let isSelected = state.textStyle.color == value
                Button {
                    send(.textColorSelected(value))
                } label: {
                    Circle()
                        .fill(swatch.color)
                        .frame(width: 24, height: 24)
                        .overlay(Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 1))
                        .padding(4)
                        .overlay(Circle().strokeBorder(Color.white.opacity(isSelected ? 1 : 0), lineWidth: 2))
                        .frame(width: 38, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(MomentPressStyle())
                .accessibilityLabel(swatch.label)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("글씨 색")
    }

    private var hint: some View {
        HStack {
            Text(state.textStyle.position == .top
                 ? "글씨가 사진 왼쪽 위에서 시작해 아래로 이어져요"
                 : "글씨가 사진 왼쪽 아래에서 시작해 위로 쌓여요")
            Spacer(minLength: Spacing.xs)
            Text("\(state.characterCount) / \(state.maxCharacters)")
                .accessibilityLabel("글자 수 \(state.characterCount) / \(state.maxCharacters)")
        }
        .font(.pretendard(size: 12))
        .foregroundColor(Color(white: 0.68))
    }

    // MARK: - 보낼 곳과 공유

    private var bottomBar: some View {
        HStack(spacing: 10) {
            destination
            shareButton
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 10)
        .background(Self.background)
    }

    @ViewBuilder
    private var destination: some View {
        if state.availableSpaces.count > 1 {
            Menu {
                ForEach(state.availableSpaces) { space in
                    Button {
                        send(.spaceSelected(space.id))
                    } label: {
                        if space.id == state.selectedSpaceId {
                            Label(destinationTitle(space), systemImage: "checkmark")
                        } else {
                            Text(destinationTitle(space))
                        }
                    }
                }
            } label: {
                destinationLabel(showsChevron: true)
            }
            .disabled(state.isUploading)
        } else {
            destinationLabel(showsChevron: false)
        }
    }

    private func destinationLabel(showsChevron: Bool) -> some View {
        HStack(spacing: 6) {
            Text("보낼 곳")
                .foregroundColor(Color(white: 0.78))
            Text(state.selectedSpace.map(destinationTitle) ?? "선택")
                .font(.pretendard(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
            if showsChevron {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .font(.pretendard(size: 13))
        .padding(.horizontal, Spacing.sm)
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(Self.chipFill)
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
    }

    private var shareButton: some View {
        Button {
            isTextFocused = false
            send(.submitTapped)
        } label: {
            Group {
                if state.isUploading {
                    ProgressView().tint(Self.ink)
                } else {
                    Text("공유하기")
                        .font(.pretendard(size: 17, weight: .semibold))
                        .foregroundColor(Self.ink)
                }
            }
            .frame(width: 118, height: 54)
            .background(Color.white)
            .clipShape(Capsule())
        }
        .buttonStyle(MomentPressStyle())
        .disabled(!state.canSubmit)
        .opacity(state.canSubmit || state.isUploading ? 1 : 0.6)
        .accessibilityLabel(state.isUploading ? "공유하는 중" : "공유하기")
    }
}
