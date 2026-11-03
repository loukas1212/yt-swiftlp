// Homeview, main page of the app

import Foundation
import SwiftUI

struct HomeView: View {
    @Environment(DownloadViewModel.self) private var dlmodel
    // AppStorage
    @AppStorage("destination") private var destination: URL = .defaultDownloads
    @AppStorage("cookieSource") private var cookieSource = "none"
    @AppStorage("cookiePath") private var cookiePath = ""
    @AppStorage("videoQuality") private var quality: VideoQuality = .p1080
    @AppStorage("videoFormat") private var videoFormat: VideoOutputFormat = .mp4

    var body: some View {
        @Bindable var dlmodel = dlmodel

        VStack(spacing: 30) {
            Label("Welcome to YT-SwiftLP", systemImage: "house.fill").font(.title)

            Text(dlmodel.status.message).font(.title3) // The status

            if dlmodel.isLoadingInfo { // Show video information
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Loading video details...").foregroundStyle(.secondary)
                }.transition(.opacity.combined(with: .move(edge: .top)))
            } else if let info = dlmodel.info {
                VideoInformationView(
                    info: info,
                    isLoading: false
                ).transition(.opacity.combined(with: .move(edge: .top)))
            }

            if let progress = dlmodel.progress { // Progressbar, show video download progress
                ProgressView(value: progress.fraction, total: 1) {
                    Text(
                        ByteCountFormatter.string(
                            fromByteCount: progress.downloadedBytes,
                            countStyle: .file
                        ) + " downloaded"
                    )
                } currentValueLabel: {
                    Text("\(progress.percent)%").contentTransition(.numericText()).animation(.smooth(duration: 0.3), value: progress.percent)
                }.frame(width: 300).transition(.opacity.combined(with: .scale(scale: 0.4)))
            } else if dlmodel.isBusy {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Progress is unknown for now").foregroundStyle(.secondary)
                }
            }

            if dlmodel.progress == nil { // URL input field
                TextField("Video URL here", text: $dlmodel.urlText).frame(width: 300).transition(.opacity.combined(with: .scale(scale: 0.4)))
            }

            HStack(spacing: 10) { // The buttons
                Button("Download", systemImage: dlmodel.isBusy ? "arrow.down.circle.fill" : "arrow.down.circle") {
                    dlmodel.start( // Start the download
                        destination: destination,
                        quality: quality,
                        videoFormat: videoFormat,
                        cookieArguments: makeCookieArguments(source: cookieSource, path: cookiePath)
                    )
                    dlmodel.loadInfo(cookieArguments: makeCookieArguments(source: cookieSource, path: cookiePath)) // Get info about the video 
                }.disabled(dlmodel.isBusy).buttonStyle(.glass).contentTransition(.symbolEffect(.replace))

                Button("Cancel", systemImage: "xmark") { // Cancel download and infoTask()
                    dlmodel.cancel()
                }.buttonStyle(.glass).disabled(dlmodel.isBusy == false)
            }
        }
        .padding()
        .frame(minWidth: 750, minHeight: 500)
        // Animations
        .animation(.easeInOut(duration: 0.3), value: dlmodel.progress == nil)
        .animation(.smooth(duration: 0.3), value: dlmodel.info == nil)
    }
}