import PhotosUI
import SwiftUI
import UIKit
import MomentUIKit
import Domain

/// 작성 — Final-MVP: 타이틀 없이 글래스 에디터 카드 + 카운터 + 다크 필 공유 버튼.
/// 매크로 없는 TCA 구성에서 모듈 경계를 지키기 위해 store.scope 대신 (state, send) 주입을 사용.
public struct ComposeView: View {
    let state: ComposeFeature.State
    let send: (ComposeFeature.Action) -> Void

    // PhotosPickerItem은 시스템 피커의 선택 핸들일 뿐이라 리듀서 상태로 올리지 않는다.
    // Data 로드가 끝나는 즉시 photoPicked로 넘기고 nil로 되돌린다.
    @State private var pickerItem: PhotosPickerItem?

    public init(state: ComposeFeature.State, send: @escaping (ComposeFeature.Action) -> Void) {
        self.state = state
        self.send = send
    }

    public var body: some View {
        ZStack {
            MomentColor.canvas.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                if state.availableSpaces.count > 1 {
                    destinationPicker
                        .padding(.top, Spacing.sm)
                }

                editorCard
                    .padding(.top, state.availableSpaces.count > 1 ? 0 : Spacing.lg)

                // 시안 05: CTA는 항상 잉크 캡슐(54pt) — 비활성은 스타일 교체가 아닌 투명도로.
                // (secondary는 캔버스색이라 화이트 톤에서 배경이 사라져 보임)
                MomentPillButton("공유하기", style: .primary, minHeight: 54) {
                    send(.submitTapped)
                }
                .disabled(!state.canSubmit)
                .opacity(state.canSubmit ? 1.0 : 0.6)
                // 임계(글자 입력)를 넘어 버튼이 "켜지는" 순간을 부드럽게
                .animation(.easeOut(duration: 0.15), value: state.canSubmit)

                if state.isUploading {
                    ProgressView()
                        .tint(MomentColor.ink)
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.lg)
        }
        .alert(
            state.error?.errorDescription ?? "오류가 발생했어요",
            isPresented: Binding(
                get: { state.error != nil },
                set: { if !$0 { send(.dismissError) } }
            )
        ) {
            Button("확인", role: .cancel) {}
        }
    }

    // MARK: - 보낼 곳 (스페이스가 둘 이상일 때)

    private var destinationPicker: some View {
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
            HStack(spacing: 6) {
                Text("보낼 곳")
                    .foregroundColor(MomentColor.ink.opacity(0.55))
                Text(state.selectedSpace.map(destinationTitle) ?? "선택")
                    .foregroundColor(MomentColor.ink)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(MomentColor.ink.opacity(0.55))
            }
            .font(.footnote.weight(.medium))
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 8)
            .background(MomentColor.surfaceSoft)
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func destinationTitle(_ space: Space) -> String {
        if let name = space.name, !name.isEmpty { return name }
        return space.isGroup ? "그룹" : "1:1 스페이스"
    }

    // MARK: - 에디터 카드

    private var editorCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                photoSection

                ZStack(alignment: .topLeading) {
                    if state.text.isEmpty {
                        Text("오늘의 순간을 남겨보세요…")
                            .font(MomentTypography.body)
                            .foregroundColor(MomentColor.ink.opacity(0.4))
                            .padding(.top, 8)
                            .padding(.leading, 5)
                    }

                    TextEditor(text: Binding(
                        get: { state.text },
                        set: { send(.textChanged($0)) }
                    ))
                    .font(MomentTypography.body)
                    .foregroundColor(MomentColor.ink)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 180)
                }

                HStack {
                    photoPickerButton
                    Spacer()
                    Text("\(state.characterCount) / 500")
                        .font(.system(size: 11, design: .default))
                        .tracking(0.8)
                        .foregroundColor(MomentColor.ink.opacity(0.45))
                }
            }
            .padding(Spacing.md)
        }
    }

    // MARK: - 사진 첨부

    @ViewBuilder
    private var photoSection: some View {
        if state.isProcessingPhoto {
            RoundedRectangle(cornerRadius: 14)
                .fill(MomentColor.surfaceSoft)
                .frame(height: 160)
                .overlay {
                    ProgressView().tint(MomentColor.ink)
                }
        } else if let data = state.selectedImage, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(alignment: .topTrailing) {
                    Button {
                        send(.clearImage)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white, Color.black.opacity(0.45))
                    }
                    .padding(Spacing.xs)
                    .accessibilityLabel("사진 제거")
                }
        }
    }

    private var photoPickerButton: some View {
        PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
            HStack(spacing: 6) {
                Image(systemName: "photo.on.rectangle")
                Text(state.selectedImage == nil ? "사진" : "사진 바꾸기")
            }
            .font(MomentTypography.bodySM)
            .foregroundColor(MomentColor.ink.opacity(0.7))
        }
        .disabled(state.isProcessingPhoto || state.isUploading)
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                // HEIC 등 원본 포맷 그대로 Data로 로드 — 변환·압축은 리듀서 이펙트가 수행
                let data = try? await newItem.loadTransferable(type: Data.self)
                send(.photoPicked(data))
            }
            pickerItem = nil
        }
    }
}

// MARK: - Xcode Previews

#Preview("작성 — 입력 중") {
    let state: ComposeFeature.State = {
        var s = ComposeFeature.State()
        s.text = "오늘 하루도 수고했어. 저녁에 산책 어때?"
        return s
    }()
    ComposeView(state: state, send: { _ in })
}

#Preview("작성 — 빈 상태") {
    ComposeView(state: ComposeFeature.State(), send: { _ in })
}

#Preview("작성 — 사진 첨부") {
    let state: ComposeFeature.State = {
        var s = ComposeFeature.State()
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 300))
        s.selectedImage = renderer.image { ctx in
            UIColor.systemOrange.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 400, height: 300))
        }.jpegData(compressionQuality: 0.8)
        s.text = "노을이 예뻐서 한 장"
        return s
    }()
    ComposeView(state: state, send: { _ in })
}
