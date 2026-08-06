#if DEBUG
import Foundation
import Alamofire
import os

/// DEBUG 빌드 전용 네트워크 로거.
/// Session의 EventMonitor로 동작해 모든 API 요청/응답 전문을 os.Logger로 출력한다.
/// - 인터셉터(adapt)가 부착한 Authorization 헤더까지 포함된 최종 요청이 잡힌다.
/// - Xcode 콘솔 외에 Console.app에서도 subsystem `com.ekko.moment`로 필터해 볼 수 있다.
/// - 토큰·비밀번호류 값은 출력 전에 마스킹한다 — 로그 공유/스크린샷을 통한 유출 방지.
final class NetworkDebugLogger: EventMonitor {
    let queue = DispatchQueue(label: "com.ekko.moment.network-debug-logger")

    private let logger = Logger(subsystem: "com.ekko.moment", category: "Network")

    func requestDidResume(_ request: Request) {
        guard let urlRequest = request.request else { return }
        let method = urlRequest.httpMethod ?? "?"
        let url = urlRequest.url?.absoluteString ?? "?"

        var lines = ["[→] \(method) \(url)"]
        for (key, value) in (urlRequest.allHTTPHeaderFields ?? [:]).sorted(by: { $0.key < $1.key }) {
            lines.append("    \(key): \(Self.maskedHeaderValue(key: key, value: value))")
        }
        if let body = urlRequest.httpBody {
            lines.append("    body:")
            lines.append(Self.indented(Self.maskedPrettyJSON(body)))
        }
        // privacy: .public — DEBUG 전용 코드이므로 Console.app에서 <private>로 가려지지 않게 한다
        logger.debug("\(lines.joined(separator: "\n"), privacy: .public)")
    }

    func request<Value>(_ request: DataRequest, didParseResponse response: DataResponse<Value, AFError>) {
        let url = request.request?.url?.absoluteString ?? "?"
        let durationText = response.metrics.map { String(format: "%.0fms", $0.taskInterval.duration * 1000) } ?? "?"

        var lines: [String]
        if let status = response.response?.statusCode {
            lines = ["[←] \(status) \(url) (\(durationText))"]
        } else {
            lines = ["[←] FAILED \(url) — \(response.error?.localizedDescription ?? "unknown error")"]
        }
        if let data = response.data, !data.isEmpty {
            lines.append("    body:")
            lines.append(Self.indented(Self.maskedPrettyJSON(data)))
        }
        logger.debug("\(lines.joined(separator: "\n"), privacy: .public)")
    }

    // MARK: - Masking

    /// 값 전체를 마스킹할 JSON 키 (소문자 비교)
    private static let maskedKeys: Set<String> = [
        "accesstoken", "refreshtoken", "identitytoken", "password", "authorizationcode",
    ]

    private static func maskedHeaderValue(key: String, value: String) -> String {
        guard key.lowercased() == "authorization" else { return value }
        return value.hasPrefix("Bearer ") ? "Bearer ***" : "***"
    }

    private static func maskedPrettyJSON(_ data: Data) -> String {
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(
                  withJSONObject: masked(object),
                  options: [.prettyPrinted, .sortedKeys]
              ),
              let string = String(data: pretty, encoding: .utf8) else {
            return String(data: data, encoding: .utf8) ?? "<non-UTF8, \(data.count) bytes>"
        }
        return string
    }

    private static func masked(_ object: Any) -> Any {
        if let dictionary = object as? [String: Any] {
            return dictionary.reduce(into: [String: Any]()) { result, entry in
                result[entry.key] = maskedKeys.contains(entry.key.lowercased()) ? "***" : masked(entry.value)
            }
        }
        if let array = object as? [Any] {
            return array.map(masked)
        }
        return object
    }

    private static func indented(_ text: String) -> String {
        text.split(separator: "\n", omittingEmptySubsequences: false)
            .map { "    \($0)" }
            .joined(separator: "\n")
    }
}
#endif
