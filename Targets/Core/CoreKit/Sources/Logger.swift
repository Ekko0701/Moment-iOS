import Foundation
import os.log

public final class MomentLogger: Sendable {
    public static let shared = MomentLogger()

    private let logger = os.Logger(subsystem: "com.moment", category: "App")

    private init() {}

    public func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.debug("[\(self.filename(file)):\(line) \(function)] \(message)")
    }

    public func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.info("[\(self.filename(file)):\(line) \(function)] \(message)")
    }

    public func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.warning("[\(self.filename(file)):\(line) \(function)] \(message)")
    }

    public func error(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        if let error = error {
            logger.error("[\(self.filename(file)):\(line) \(function)] \(message) - Error: \(error.localizedDescription)")
        } else {
            logger.error("[\(self.filename(file)):\(line) \(function)] \(message)")
        }
    }

    private func filename(_ path: String) -> String {
        URL(fileURLWithPath: path).lastPathComponent
    }
}
