import Foundation
import Observation

@MainActor
@Observable
final class DownloadViewModel {
    var urlText = ""

    private(set) var status: DownloadStatus = .idle
    private(set) var progress: DownloadProgress?
    private(set) var info: VideoInfo?
    private(set) var isLoadingInfo = false
    private var infoTask: Task<Void, Never>?
    private var downloadTask: Task<Void, Never>?
    private let runner = DownloadService()
    private var streams: [String: (downloaded: Int64, total: Int64)] = [:]
    private var lastFraction = 0.0

    var isBusy: Bool { downloadTask != nil }

    // Load information about the video
    func loadInfo(cookieArguments: [String] = []) {
        infoTask?.cancel()
        info = nil
        isLoadingInfo = false

        guard let url = try? DownloadService.validateURL(urlText) else {
            return
        }

        isLoadingInfo = true

        infoTask = Task {
            defer {
                if !Task.isCancelled {
                    isLoadingInfo = false
                }
            }

            do {
                let result = try await DownloadService.getInfo(
                    url: url,
                    cookieArguments: cookieArguments
                )

                try Task.checkCancellation()
                info = result

            } catch is CancellationError {
                // The request was cancelled.
            } catch {
                if !Task.isCancelled {
                    status = .failed(error.localizedDescription)
                    isLoadingInfo = false
                }
            }
        }
    }

    // Start the download process
    func start(
        destination: URL,
        quality: VideoQuality,
        videoFormat: VideoOutputFormat,
        cookieArguments: [String] = []
    ) {
        guard downloadTask == nil else { return }

        let url: URL
        do {
            url = try DownloadService.validateURL(urlText)
        } catch {
            status = .failed(error.localizedDescription)
            return
        }

        progress = nil
        streams = [:]
        lastFraction = 0
        status = .downloading

        downloadTask = Task {
            defer {
                downloadTask = nil
                progress = nil
                streams = [:]
                lastFraction = 0
            }

            var completed = false

            do {
                let events = runner.events(
                    url: url,
                    destination: destination,
                    qualitySelector: quality.qualitySelector,
                    videoOutputFormat: videoFormat.videoFormatSelector,
                    cookieArguments: cookieArguments
                )
                for try await event in events {
                    switch event {
                    case .progress(let value):
                        streams[value.streamID] = (value.downloadedBytes, value.totalBytes)

                        let downloaded = streams.values.reduce(0) { $0 + $1.downloaded }
                        let total = streams.values.reduce(0) { $0 + $1.total }

                        // Each stream counts for half of the bar
                        let done = streams.values.reduce(0.0) {
                            $0 + Double($1.downloaded) / Double(max($1.total, 1))
                        }
                        let fraction = min(max(lastFraction, done / 2), 1)
                        lastFraction = fraction

                        progress = DownloadProgress(
                            fraction: fraction,
                            downloadedBytes: downloaded,
                            totalBytes: total,
                            status: value.status,
                            streamID: value.streamID
                        )
                    case .log(let message):
                        print("YT-DLP:", message)
                    case .completed:
                        completed = true
                    }
                }

                if Task.isCancelled {
                    status = .cancelled
                } else if completed {
                    status = .completed
                } else {
                    status = .failed("Unknown Error. No result from process")
                }
            } catch {
                status = Task.isCancelled
                    ? .cancelled
                    : .failed(error.localizedDescription)
            }
        }
    }

    // Cancel the current download (terminates the Task and the process stream)
    func cancel() {
        downloadTask?.cancel()
        infoTask?.cancel()
        isLoadingInfo = false
    }

    func reportError(_ message: String) {
        status = .failed(message)
    }
}