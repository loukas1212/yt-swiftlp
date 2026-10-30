// Reusable download settings view

import SwiftUI
import Foundation

struct DownloadSettingsView: View {
    @AppStorage("videoQuality") private var videoQuality: VideoQuality = .p1080
    @AppStorage("isAudioOnly") private var isAudioOnly: Bool = false
    @AppStorage("isEmbedMetadata") private var isEmbedMetadata: Bool = false

    var body: some View {
        VStack(spacing: 10) {
            Picker("Quality", selection: $videoQuality) {
                ForEach(VideoQuality.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }

            Toggle("Audio only", isOn: $isAudioOnly).toggleStyle(.switch)

            Toggle("Embed metadata", isOn: $isEmbedMetadata).toggleStyle(.switch)

            Text("Output format selection is comming next update.")
        }
    }
}