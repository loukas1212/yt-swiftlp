// ToolError is the way to return an Error when YT-DLP or URL fail

import Foundation

enum ToolError: LocalizedError {
    case notFound
    case invalidURL
    case unauthorized
    case launchFailed(String)
    case failed(Int32, String)

    var errorDescription: String? {
        switch self {
            case .notFound:
                return "YT-DLP can't be found. Please (re)install it."
            case .invalidURL:
                return "The URL is invalid."
            case .unauthorized:
                return "URL not authorized, please disable URL check in settings."
            case .launchFailed(let detail):
                return "YT-DLP execution error : \(detail)"
            case .failed(let exitCode, let detail):
                return "YT-DLP process failed : (exit code : \(exitCode)) (\(detail))"
        }
    }
}
