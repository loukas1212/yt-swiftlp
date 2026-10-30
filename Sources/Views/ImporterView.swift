// Reusable folder importation button

import SwiftUI

struct FolderImporterView: View {
    @Environment(DownloadViewModel.self) private var dlmodel
    @State private var showingImporter: Bool = false
    // AppStorage
    @AppStorage("destination") private var destination: URL = .defaultDownloads

    var body: some View {
        Button("Select destination", systemImage: "folder.badge.gearshape") {
            showingImporter = true
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
                case .success(let urls):
                    if let folder = urls.first {
                        destination = folder
                    }
                case .failure(let error):
                    // Close without choosing a folder will NOT be considered as an error
                    if (error as? CocoaError)?.code != .userCancelled {
                        dlmodel.reportError(error.localizedDescription)
                    }
            }
        }
    }
}

struct CookiesImporterView: View {
    @Environment(DownloadViewModel.self) private var dlmodel
    @AppStorage("cookieSource") private var cookieSource = "none"
    @AppStorage("cookiePath") private var cookiePath = ""
    @State private var showingImporter = false

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Picker("Cookies from", selection: $cookieSource) {
                Text("None").tag("none")
                Text("Safari").tag("safari")
                Text("Chrome").tag("chrome")
                Text("Firefox").tag("firefox")
                Text("Brave").tag("brave")
                Text("Zen (profile folder)").tag("zen")
                Text("cookies.txt file").tag("file")
            }

            if cookieSource == "zen" || cookieSource == "file" {
                HStack(spacing: 5) {
                    Button(
                        cookieSource == "zen" ? "Select profile folder" : "Select cookies.txt",
                        systemImage: "folder.badge.gearshape"
                    ) {
                        showingImporter = true
                    }
                    Text(cookiePath.isEmpty ? "Nothing selected" : cookiePath)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: cookieSource == "file" ? [.plainText] : [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    cookiePath = url.path
                }
            case .failure(let error):
                if (error as? CocoaError)?.code != .userCancelled {
                    dlmodel.reportError(error.localizedDescription)
                }
            }
        }
    }
}

