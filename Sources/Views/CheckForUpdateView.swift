import SwiftUI
import Sparkle

struct CheckForUpdatesView: View {
    @ObservedObject private var viewModel: UpdateViewModel
    private let updater: SPUUpdater 

    init(updater: SPUUpdater) {
        self.updater = updater
        self.viewModel = UpdateViewModel(updater: updater)
    }

    var body: some View {
        Button("Check for updates", action: viewModel.checkForUpdates)
            .disabled(!viewModel.canCheckForUpdates)
            .buttonStyle(.glass)
    }
}