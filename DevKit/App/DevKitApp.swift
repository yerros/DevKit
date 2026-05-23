import SwiftUI

@main
struct DevKitApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
        } label: {
            Image(systemName: appState.menuBarIcon)
            Text("DevKit")
        }
        .menuBarExtraStyle(.window)

        Window("DevKit", id: "main") {
            MainWindow()
                .environmentObject(appState)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 780, height: 580)
        .windowResizability(.contentSize)
    }
}
