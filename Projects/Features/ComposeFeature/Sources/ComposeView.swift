import SwiftUI
import MomentUIKit

/// 작성 — Final-MVP: 타이틀 없이 글래스 에디터 카드 + 카운터 + 다크 필 공유 버튼.
/// 매크로 없는 TCA 구성에서 모듈 경계를 지키기 위해 store.scope 대신 (state, send) 주입을 사용.
public struct ComposeView: View {
    let state: ComposeFeature.State
    let send: (ComposeFeature.Action) -> Void

    public init(state: ComposeFeature.State, send: @escaping (ComposeFeature.Action) -> Void) {
        self.state = state
        self.send = send
    }

    public var body: some View {
        ZStack {
            MomentColor.canvas.ignoresSafeArea()
            OrbBackground.compose().ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                editorCard
                    .padding(.top, Spacing.lg)

                MomentPillButton("공유하기", style: state.canSubmit ? .primary : .secondary) {
                    send(.submitTapped)
                }
                .disabled(!state.canSubmit)

                if state.isUploading {
                    ProgressView()
                        .tint(MomentColor.ink)
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.lg)
        }
    }

    // MARK: - 에디터 카드

    private var editorCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: Spacing.xs) {
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
