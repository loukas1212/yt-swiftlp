import Foundation

enum YtdlpLocator {
    static func candidatePaths() -> [String] {
        var paths = [ // YT-DLP Possible path list
            "/opt/homebrew/bin/yt-dlp",
            "/usr/local/bin/yt-dlp",
            "/usr/bin/yt-dlp"
        ]

        if let path = ProcessInfo.processInfo.environment["PATH"] {
            paths += path.split(separator: ":").map { folder in "\(folder)/yt-dlp"} // Split path and put them into a MAP
        }

        var seen = Set<String>()
        return paths.filter { seen.insert($0).inserted }
    }

    static func findExecutable() -> URL? { // Check if paths are executable
        return candidatePaths()
            .map { URL(fileURLWithPath: $0 ) } // Transform String into a valid URL
            .first { FileManager.default.isExecutableFile(atPath: $0.path) } // Check if the URL in the MAP are executable
    }

    // Environment passed to the Process
    // Gives yt-dlp a PATH that lets it find ffmpeg and ffprobe by itself
    static func processEnvironment() -> [String: String] {
        var environment = ProcessInfo.processInfo.environment

        let current = (environment["PATH"] ?? "").split(separator: ":").map(String.init)

        let common = ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin"]

        var seen = Set<String>()
        environment["PATH"] = (common + current)
            .filter { seen.insert($0).inserted }
            .joined(separator: ":")
        
        return environment
    }
}