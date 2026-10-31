import Foundation

public enum InfluxError: LocalizedError, Equatable {
    case networkError(String)
    case authError(String)
    case notFoundError(String)
    case queryError(String)

    public var errorDescription: String? {
        switch self {
        case .networkError(let msg):
            return "Network Error: \(msg)"
        case .authError(let msg):
            return "Authentication Error: \(msg)"
        case .notFoundError(let msg):
            return "Not Found: \(msg)"
        case .queryError(let msg):
            return "Query Error: \(msg)"
        }
    }
}
