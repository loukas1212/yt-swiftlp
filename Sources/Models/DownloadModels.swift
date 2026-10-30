import Foundation

enum DownloadStatus {
    case idle
    case checking
    case downloading
    case completed
    case cancelled
    case failed(String)

    var message: String {
        switch self {
            case .idle: 
                return "Ready for download"
            case .checking:
                return "Checking for YT-DLP..."
            case .downloading:
                return "Downloading..."
            case .completed:
                return "Download finished"
            case .cancelled:
                return "Download cancelled"
            case .failed(let message):
                return "Error : \(message)"
        }
    }
}

struct DownloadProgress: Sendable {
    let fraction: Double
    let downloadedBytes: Int64
    let totalBytes: Int64
    let status: String
    let streamID: String

    var percent: Int {
        Int((fraction * 100).rounded())
    }
}

struct VideoInfo: Decodable, Sendable { // Information about the video, fetched using getInfo() in DownloadService
    let title: String
    let thumbnail: URL?
}