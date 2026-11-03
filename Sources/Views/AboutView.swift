// Information View, "About" tab

import SwiftUI
import AppKit

private var appVersion: String {
    let info = Bundle.main.infoDictionary
    let version = info?["CFBundleShortVersionString"] as? String ?? "?"
    let build = info?["CFBundleVersion"] as? String ?? "?"
    return "Version \(version) (\(build))"
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 30) {
            Label("About this app", systemImage: "info.app").font(.title)

            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 128, height: 128)
            
            Text(appVersion).font(.title)


            Text("Made with ♥ by Loukas").font(.title2)

        Link(destination: URL(string: "https://github.com/loukas1212/yt-swiftlp")!) {
            HStack {
                Image(systemName: "link.circle").font(.title3)
                Text("Open the repository").font(.title3)
            }
        }


            VStack(alignment: .center, spacing: 5) {
                Label("This is the first release, bugs and errors can occur.", systemImage: "exclamationmark.triangle")
                Text("not all the functions are here, please wait for the next updates.")
            }
        }
        .frame(minWidth: 750, minHeight: 500)
    }
}