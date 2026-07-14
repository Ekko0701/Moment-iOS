import Foundation

/// 라이브 의존성 제공자.
/// Networking 모듈의 라이브 구현(Alamofire 기반)을 노출한다 (POP + 단일 세션 공유).
/// Repository DI는 Domain 모듈에서 선언되며, App이 시작 시 주입한다.
public enum NetworkingLive {
    public static let tokenStore = KeychainTokenStore()
    public static let apiClient = MomentAPIClient(tokenStore: tokenStore)
}
