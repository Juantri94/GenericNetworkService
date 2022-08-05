import Foundation

public enum APIError: Error {

    case wrongUrl(description: String)
    case urlComponentsFailure(description: String)
    case requestFailed(description: String)
    case jsonConversionFailure(description: String)
    case responseUnsuccessful(description: String)
    case noInternet
    case notAuthorized
    case serverError
    
    var customDescription: String {
        switch self {
        case let .wrongUrl(description): return "URL -> \(description)"
        case let .urlComponentsFailure(description): return "URL components -> \(description)"
        case let .requestFailed(description): return "Request Failed error -> \(description)"
        case let .jsonConversionFailure(description): return "JSON Conversion Failure -> \(description)"
        case let .responseUnsuccessful(description): return "Response Unsuccessful error -> \(description)"
        case .noInternet: return "No internet connection"
        case .notAuthorized: return ""
        case .serverError: return "Server error"
        }
    }
}
