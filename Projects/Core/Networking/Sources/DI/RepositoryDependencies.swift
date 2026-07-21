import Foundation

/// 라이브 의존성 제공자.
/// Networking 모듈의 라이브 구현(Alamofire 기반)을 노출한다 (POP + 단일 세션 공유).
/// Repository DI는 Domain 모듈에서 선언되며, App이 시작 시 주입한다.
public enum NetworkingLive {
    /// 로컬 개발 서버 주소.
    /// - 시뮬레이터: localhost가 곧 Mac이므로 그대로 사용.
    /// - 실기기: localhost는 기기 자신을 가리키므로, 같은 Wi-Fi에 있는 Mac의
    ///   Bonjour 호스트명(.local)으로 접속한다. ATS의 NSAllowsLocalNetworking이
    ///   .local 도메인을 커버하므로 별도 예외가 필요 없다.
    ///   Mac 호스트명이 다르면 `scutil --get LocalHostName` 결과로 바꿔줄 것.
    private static let devServerURL: URL = {
        #if targetEnvironment(simulator)
        return URL(string: "http://localhost:8080")!
        #else
        return URL(string: "http://Kimui-MacBookAir.local:8080")!
        #endif
    }()

    public static let tokenStore = KeychainTokenStore()
    public static let apiClient = MomentAPIClient(baseURL: devServerURL, tokenStore: tokenStore)
}
