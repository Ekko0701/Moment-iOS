import SwiftUI
import UIKit

/// 값을 클립보드에 복사하고, 잠시 "복사됨" 상태를 보여 주는 버튼.
/// 복사되면 가벼운 햅틱과 함께 VoiceOver에도 알린다.
public struct MomentCopyButton<Label: View>: View {
    let value: String
    let announcement: String
    let label: (_ copied: Bool) -> Label

    @State private var copied = false
    @State private var resetTask: Task<Void, Never>?

    public init(
        value: String,
        announcement: String = "복사했어요",
        @ViewBuilder label: @escaping (_ copied: Bool) -> Label
    ) {
        self.value = value
        self.announcement = announcement
        self.label = label
    }

    public var body: some View {
        Button {
            UIPasteboard.general.string = value
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            UIAccessibility.post(notification: .announcement, argument: announcement)
            withAnimation(.easeOut(duration: 0.15)) { copied = true }
            resetTask?.cancel()
            resetTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.5))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.2)) { copied = false }
            }
        } label: {
            label(copied)
        }
        .onDisappear { resetTask?.cancel() }
    }
}
