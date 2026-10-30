// Runner for YT-DLP and Getting progress state and video information

import Foundation

struct DownloadService: Sendable {
    static func validateURL(_ text: String) throws -> URL {
        // Get user settings from "AppStorage"
        let isAllowNsfw = UserDefaults.standard.bool(forKey: "allowNsfw")

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if the URL is valid
        guard let url = URL(string: trimmed),
            let scheme = url.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            let host = url.host?.lowercased() else {
                throw ToolError.invalidURL
            }

        if isAllowNsfw == false {
            // Check if NSFW download is authorized
            let unauthorizedDomain = ["rule34.xxx", "rule34video.com", "pornhub.com", "xhamster.com", "xvideos.com"] // Not a full list, need improvment
            guard !unauthorizedDomain.contains(where: { domain in
                host == domain || host.hasSuffix("." + domain)
            }) else {
                throw ToolError.unauthorized
            }
        }


        return url
    }

    // Get information from the video (Title, thumbnail)
    static func getInfo(url: URL, cookieArguments: [String] = []) async throws -> VideoInfo {
        guard let executable = YtdlpLocator.findExecutable() else {
            throw ToolError.notFound
        }

        var arguments = [
            "--dump-single-json",
            "--no-playlist",
            "--no-warnings"
        ]

        // Add cookies and URL to the arguments
        arguments += cookieArguments
        arguments.append(url.absoluteString)

        let result = try await ProcessRunner.run(
            executable: executable,
            arguments: arguments,
            environment: YtdlpLocator.processEnvironment()
        )

        guard result.status == 0 else {
            throw ToolError.failed(result.status, result.errorText)
        }

        return try JSONDecoder().decode(VideoInfo.self, from: Data(result.output.utf8))
    }


    // Creating the arguments
    static func makeArguments(
        url: URL,
        destination: URL,
        qualitySelector: String?,
        cookieArguments: [String] = []
    ) -> [String] {
        // Getting settings from "AppStorage"
        let isAudioOnly = UserDefaults.standard.bool(forKey: "isAudioOnly")
        let isEmbedMetadata = UserDefaults.standard.bool(forKey: "isEmbedMetadata")

        var arguments = [
            "--no-playlist",
            "--newline",
            "--progress",
            "--progress-template", "download:download:%(progress.downloaded_bytes)s|%(progress.total_bytes)s|%(progress.total_bytes_estimate)s|%(progress.status)s|%(info.format_id)s",
            "--merge-output-format", "mp4",
            "-P", destination.path,
            "-o", "%(title)s.%(ext)s"
        ]

        if let qualitySelector {
            arguments += ["-f", qualitySelector]
        }

        if isAudioOnly == true { // For "audio only" setting
            arguments += ["-x", "--audio-format", "mp3"]
        }

        if isEmbedMetadata == true { // For "embed metadata" setting
            arguments += ["--embed-metadata", "--embed-thumbnail"]
        }

        arguments += cookieArguments
        arguments.append(url.absoluteString)
        print("ARGS:", arguments)
        return arguments
    }

    // Events
    func events(
        url: URL,
        destination: URL,
        qualitySelector: String? = nil,
        cookieArguments: [String] = []
    ) -> AsyncThrowingStream<DownloadEvent, Error> {
        AsyncThrowingStream { continuation in
            guard let executable = YtdlpLocator.findExecutable() else {
                continuation.finish(throwing: ToolError.notFound)
                return
            }

            let process = Process()
            process.executableURL = executable
            process.arguments = Self.makeArguments(
                url: url,
                destination: destination,
                qualitySelector: qualitySelector,
                cookieArguments: cookieArguments
            )
            process.environment = YtdlpLocator.processEnvironment()
            process.standardInput = FileHandle.nullDevice

            let stdout = Pipe()
            let stderr = Pipe()
            process.standardOutput = stdout
            process.standardError = stderr

            // Install before run() to avoid missing Process() ending
            let (exitCodes, exitContinuation) = AsyncStream.makeStream(of: Int32.self)
            process.terminationHandler = { finished in
                exitContinuation.yield(finished.terminationStatus)
                exitContinuation.finish()
            }

            let outHandle = stdout.fileHandleForReading
            let errHandle = stderr.fileHandleForReading

            let stdoutTask = Task.detached {
                for await line in lines(from: outHandle) {
                    if let progress = ProgressParser.parse(line) {
                        continuation.yield(.progress(progress))
                    } else {
                        continuation.yield(.log(line))
                    }
                }
            }

            let stderrTask = Task.detached { () -> [String] in
                var tail: [String] = []
                for await line in lines(from: errHandle) {
                    tail.append(line)
                    if tail.count > 20 { tail.removeFirst() }
                    continuation.yield(.log(line))
                }
                return tail
            }

            do { // Run YT-DLP Process() from ProcessRunner.swift
                try process.run()
            } catch {
                stdout.fileHandleForWriting.closeFile()
                stderr.fileHandleForWriting.closeFile()

                let launchError = ToolError.launchFailed(error.localizedDescription)
                Task {
                    await stdoutTask.value
                    _ = await stderrTask.value
                    continuation.finish(throwing: launchError)
                }
                return
            }

            stdout.fileHandleForWriting.closeFile()
            stderr.fileHandleForWriting.closeFile()

            // Termination for when a user Cancel the download process
            // Terminate Process and Flow
            let handle = ProcessHandle(process)
            continuation.onTermination = { _ in handle.terminateIfRunning() }

            // Result (the result is dependant of an exit code, not a "100%")
            Task {
                var status: Int32 = -1
                for await code in exitCodes { status = code }
                await stdoutTask.value
                let tail = await stderrTask.value

                if status == 0 {
                    continuation.yield(.completed)
                    continuation.finish()
                } else {
                    continuation.finish(throwing: ToolError.failed(status, tail.joined(separator: "\n")))
                }
            }
        }
    }
}

// Make process a "Sendable"
private final class ProcessHandle: @unchecked Sendable {
    private let lock = NSLock()
    private let process: Process

    init(_ process: Process) {
        self.process = process
    }

    func terminateIfRunning() {
        lock.lock()
        defer { lock.unlock() }
        if process.isRunning {
            process.terminate()
        }
    }
}

private func lines(from handle: FileHandle) -> AsyncStream<String> {
    AsyncStream { continuation in
        Task.detached {
            var buffer = Data()
            while true {
                let chunk = handle.availableData   // blocks until data or EOF
                if chunk.isEmpty { break }         // EOF
                buffer.append(chunk)
                // split on \n or \r (yt-dlp can use \r for progress)
                while let i = buffer.firstIndex(where: { $0 == 0x0A || $0 == 0x0D }) {
                    let lineData = buffer[buffer.startIndex..<i]
                    buffer.removeSubrange(buffer.startIndex...i)
                    if !lineData.isEmpty {
                        continuation.yield(String(decoding: lineData, as: UTF8.self))
                    }
                }
            }
            if !buffer.isEmpty {
                continuation.yield(String(decoding: buffer, as: UTF8.self))
            }
            continuation.finish()
        }
    }
}