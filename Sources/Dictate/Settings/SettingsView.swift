import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView {
            GeneralSettingsView()
                .environment(appState)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            StyleSettingsView()
                .environment(appState)
                .tabItem {
                    Label("Styles", systemImage: "textformat")
                }

            ModelSettingsView()
                .environment(appState)
                .tabItem {
                    Label("Models", systemImage: "cpu")
                }
        }
        .frame(width: 480, height: 400)
    }
}
