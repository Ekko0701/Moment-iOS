import SwiftUI
import AuthenticationServices

/// ASAuthorizationAppleIDButton을 직접 감싼 Apple 로그인 버튼.
///
/// SwiftUI의 SignInWithAppleButton 대신 쓰는 이유:
/// - 이 버튼은 UIKit 네이티브 뷰라 자기 자신의 cornerRadius 기준으로 로고·테두리를 그린다.
///   밖에서 clipShape(Capsule())로 잘라내면 버튼이 그린 것과 어긋나 가장자리와 로고가
///   깨져 보일 수 있다. 캡슐은 클리핑이 아니라 버튼 자체의 cornerRadius로 만든다.
/// - onRequest/onCompletion 클로저 시그니처는 SwiftUI 버전과 동일하게 유지해
///   AuthView의 기존 인증 처리 코드(nonce 구성·결과 핸들링)를 그대로 쓴다.
struct AppleSignInButton: UIViewRepresentable {
    enum Style {
        case black
        case whiteOutline
    }

    let style: Style
    let cornerRadius: CGFloat
    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>) -> Void

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(
            authorizationButtonType: .continue,
            authorizationButtonStyle: style == .black ? .black : .whiteOutline)
        button.cornerRadius = cornerRadius
        button.addTarget(context.coordinator, action: #selector(Coordinator.didTap), for: .touchUpInside)
        return button
    }

    func updateUIView(_ button: ASAuthorizationAppleIDButton, context: Context) {
        context.coordinator.parent = self
        button.cornerRadius = cornerRadius
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, ASAuthorizationControllerDelegate,
            ASAuthorizationControllerPresentationContextProviding {
        var parent: AppleSignInButton

        init(parent: AppleSignInButton) {
            self.parent = parent
        }

        @objc func didTap() {
            let request = ASAuthorizationAppleIDProvider().createRequest()
            parent.onRequest(request)
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }

        func authorizationController(
                controller: ASAuthorizationController,
                didCompleteWithAuthorization authorization: ASAuthorization) {
            parent.onCompletion(.success(authorization))
        }

        func authorizationController(
                controller: ASAuthorizationController,
                didCompleteWithError error: Error) {
            parent.onCompletion(.failure(error))
        }

        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow } ?? ASPresentationAnchor()
        }
    }
}
