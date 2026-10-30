// View for Settings, "Settings" tab

import SwiftUI
import Sparkle

struct SettingsView: View {
    @Environment(DownloadViewModel.self) private var dlmodel
    // AppStorage
    @AppStorage("destination") private var destination: URL = .defaultDownloads
    @AppStorage("cookieSource") private var cookieSource = "none"
    @AppStorage("cookiePath") private var cookiePath = ""
    @AppStorage("allowNsfw") private var isAllowNsfw: Bool = false

    // Var
    var checkIsOn: Bool = false

    // For CheckForUpdates()
    let updater: SPUUpdater

    var body: some View {
        VStack(spacing: 10) {

            Label("Settings", systemImage: "gearshape").font(.title).padding(15)

            HStack(spacing: 5) {
                FolderImporterView()
                Text(destination.path)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            CookiesImporterView()
            
            Toggle("Disable URL check", isOn: $isAllowNsfw)
                .tint(.red)
                .toggleStyle(.switch)

            Divider().frame(width: 350)
            
            DownloadSettingsView()

            CheckForUpdatesView(updater: updater)
        }
        .padding()
        .frame(minWidth: 750, minHeight: 500)
    }
}