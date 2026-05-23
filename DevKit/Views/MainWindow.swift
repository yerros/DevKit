import SwiftUI

struct MainWindow: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            ServicesTab()
                .tabItem { Label("Services", systemImage: "server.rack") }
            PortsTab()
                .tabItem { Label("Ports", systemImage: "network") }
            ScreenshotsTab()
                .tabItem { Label("Screenshots", systemImage: "photo.on.rectangle") }
            HostsTab()
                .tabItem { Label("Hosts", systemImage: "globe") }
            DevToolsTab()
                .tabItem { Label("Dev Tools", systemImage: "wrench.and.screwdriver") }
            SettingsTab()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .frame(width: 780, height: 580)
        .background(
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.04, blue: 0.07),
                         Color(red: 0.06, green: 0.06, blue: 0.16)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .preferredColorScheme(.dark)
    }
}
