// Tabbar to switch between view

import SwiftUI
import Sparkle

struct ContentView: View {
    let updater: SPUUpdater

    var body: some View {
        TabView {
            Tab("Home", systemImage: "arrow.down.circle.dotted") {
                HomeView()
            }

            Tab("About", systemImage: "info.app") {
                AboutView()
            }

            Tab("Settings", systemImage: "gearshape") {
                SettingsView(updater: updater)
            }
        }
    }
}