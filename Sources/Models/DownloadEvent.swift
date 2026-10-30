import Foundation

enum DownloadEvent: Sendable {
    case progress(DownloadProgress)
    case log(String)
    case completed
}