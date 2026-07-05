import SwiftUI

struct AppView: View {
    @Binding var isLoggedIn: Bool
    @Binding var hasActiveSpace: Bool

    var body: some View {
        ZStack {
            if isLoggedIn {
                if hasActiveSpace {
                    PlaceholderHomeView()
                } else {
                    PlaceholderConnectionView()
                }
            } else {
                PlaceholderLoginView(isLoggedIn: $isLoggedIn, hasActiveSpace: $hasActiveSpace)
            }
        }
    }
}

// MARK: - Placeholder Views for MVP

private struct PlaceholderLoginView: View {
    @Binding var isLoggedIn: Bool
    @Binding var hasActiveSpace: Bool

    var body: some View {
        VStack(spacing: 24) {
            Text("Moment")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.coral)

            Text("로그인이 필요해요")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.gray)

            Button(action: { isLoggedIn = true; hasActiveSpace = false }) {
                Text("Sign in with Apple (Mock)")
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.coral)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .padding(.vertical, 48)
    }
}

private struct PlaceholderConnectionView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("상대방을 초대해 보세요")
                .font(.system(size: 18, weight: .semibold))

            Text("연결 대기 중...")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.gray)

            Spacer()
        }
        .padding(.vertical, 48)
    }
}

private struct PlaceholderHomeView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("홈 (피드)")
                .font(.system(size: 24, weight: .bold))

            Text("첫 모먼트를 기다리는 중...")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.gray)

            Spacer()
        }
        .padding(.vertical, 48)
    }
}

// MARK: - Color Extension

extension Color {
    static let coral = Color(red: 0.98, green: 0.48, blue: 0.40)
}

#Preview {
    @Previewable @State var isLoggedIn = false
    @Previewable @State var hasActiveSpace = false
    AppView(isLoggedIn: $isLoggedIn, hasActiveSpace: $hasActiveSpace)
}
