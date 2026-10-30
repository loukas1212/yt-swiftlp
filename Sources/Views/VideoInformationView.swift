// View for the video information

import SwiftUI

struct VideoInformationView: View {
    let info: VideoInfo?
    let isLoading: Bool


    var body: some View {
        if isLoading {
            HStack(spacing: 10) {
                ProgressView()
                Text("Loading video info...")
                    .foregroundStyle(.secondary)
            }
        } else if let info {
            VStack(spacing: 10) {
                if let thumbnail = info.thumbnail {
                    AsyncImage(url: thumbnail) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 180)
                    }
                    .frame(maxHeight: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Text(info.title)
                    .font(.caption)
                    .lineLimit(2)
            }
        }
    }
}