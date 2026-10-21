import SwiftUI
import Domain
import MomentUIKit

/// 방장 수락을 기다리는 내 그룹 참여 요청 목록. 요청마다 취소할 수 있다.
/// 홈과, 스페이스가 하나도 없을 때의 연결 화면이 함께 쓴다.
public struct PendingJoinRequestsView: View {
    let requests: [GroupJoinRequest]
    let onCancel: (GroupJoinRequest) -> Void

    public init(requests: [GroupJoinRequest], onCancel: @escaping (GroupJoinRequest) -> Void) {
        self.requests = requests
        self.onCancel = onCancel
    }

    public var body: some View {
        if !requests.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("수락을 기다리는 그룹")
                    .font(.footnote.weight(.medium))
                    .foregroundColor(MomentColor.ink.opacity(0.6))
                ForEach(requests) { request in
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "hourglass")
                            .foregroundColor(MomentColor.ink.opacity(0.5))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(request.spaceName)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(MomentColor.ink)
                            Text("방장 수락 대기 중")
                                .font(.caption)
                                .foregroundColor(MomentColor.ink.opacity(0.55))
                        }
                        Spacer()
                        Button("요청 취소") { onCancel(request) }
                            .font(.footnote)
                            .foregroundColor(MomentColor.ink.opacity(0.6))
                            .accessibilityLabel("\(request.spaceName) 참여 요청 취소")
                    }
                    .padding(Spacing.md)
                    .background(MomentColor.surfaceSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
    }
}
