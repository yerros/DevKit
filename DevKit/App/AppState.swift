import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var config: AppConfig
    @Published var menuBarIcon: String = "server.rack"

    init() {
        self.config = SettingsManager.load()
    }

    func saveConfig() {
        SettingsManager.save(config)
    }
}
