import SwiftUI
import MomentUIKit

// 매크로 없는 TCA 구성에서 모듈 경계를 지키기 위해 store.scope 대신 (state, send) 주입을 사용
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

            VStack(spacing: Spacing.lg) {
                EyebrowText("새 순간")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.lg)

                Text("우리의 순간을 기록하세요")
                    .font(MomentTypography.headline)
                    .foregroundColor(MomentColor.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.lg)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    TextEditor(text: Binding(
                        get: { state.text },
                        set: { send(.textChanged($0)) }
                    ))
                    .font(MomentTypography.body)
                    .foregroundColor(MomentColor.ink)
                    .scrollContentBackground(.hidden)
                    .background(MomentColor.canvas)
                    .border(MomentColor.hairline, width: 1)
                    .cornerRadius(Spacing.Radius.md)
                    .frame(minHeight: 120)

                    HStack(alignment: .center, spacing: Spacing.sm) {
                        Spacer()

                        Text(String(format: "%04d / 0500", state.characterCount))
                            .font(MomentTypography.caption)
                            .tracking(0.8)
                            .foregroundColor(MomentColor.ink.opacity(0.6))
                    }
                }
                .padding(.horizontal, Spacing.lg)

                MomentPillButton("공유하기", style: state.canSubmit ? .primary : .secondary) {
                    send(.submitTapped)
                }
                .disabled(!state.canSubmit)
                .padding(.horizontal, Spacing.lg)

                if state.isUploading {
                    ProgressView()
                }

                Spacer()
            }
            .padding(.vertical, Spacing.lg)
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
