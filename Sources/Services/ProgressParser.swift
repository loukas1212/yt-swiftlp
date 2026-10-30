// Parse the progression of YT-DLP from DownloadModels.swift and DownloadService.swift

import Foundation

enum ProgressParser {
    static func parse(_ line: String) -> DownloadProgress? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("download:") else { return nil }

        let payload = trimmed.dropFirst("download:".count)
        let fields = payload.split(separator: "|", omittingEmptySubsequences: false)

        guard fields.count >= 5, let downloaded = parseBytes(fields[0]) else {
            return nil
        }

        // Attempt getting exact size, then estimate or return 0
        let candidates = [parseBytes(fields[1]), parseBytes(fields[2])]

        guard let total = candidates.compactMap({ $0 }).first(where: { $0 > 0 }) else {
            return nil // This guard is used to find the first usable total
        }

        // Calculate the fraction, give smth between 0.0 and 1.0
        let fraction = min(max(Double(downloaded) / Double(total), 0), 1)
        return DownloadProgress(
            fraction: fraction,
            downloadedBytes: downloaded,
            totalBytes: total,
            status: String(fields[3]),
            streamID: String(fields[4])
        )
    }
    
    // Accept Full or Decimal number, however, refuse "NA"
    private static func parseBytes(_ value: Substring) -> Int64? {
        let text = value.trimmingCharacters(in: .whitespaces)
        guard text != "NA",
            let number = Double(text),
            number.isFinite,
            number >= 0,
            number < Double(Int64.max) else {
            return nil
        }
        return Int64(number.rounded())
    }
}