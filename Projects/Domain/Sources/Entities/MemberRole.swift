import Foundation

/// 스페이스 안에서의 역할. 그룹에서는 방장(owner)만 이름 변경·내보내기·코드 재발급·종료를 할 수 있다.
public enum MemberRole: String, Codable, Sendable {
    case owner = "OWNER"
    case member = "MEMBER"
}
