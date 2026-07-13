import Foundation

extension Date {
    public var relativeFormatted: String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self, to: Date())

        if let year = components.year, year > 0 {
            return "\(year)년 전"
        }
        if let month = components.month, month > 0 {
            return "\(month)개월 전"
        }
        if let day = components.day, day > 0 {
            return "\(day)일 전"
        }
        if let hour = components.hour, hour > 0 {
            return "\(hour)시간 전"
        }
        if let minute = components.minute, minute > 0 {
            return "\(minute)분 전"
        }
        return "방금"
    }
}
