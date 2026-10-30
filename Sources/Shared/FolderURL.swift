import Foundation

extension URL {
    static let defaultDownloads =
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
}