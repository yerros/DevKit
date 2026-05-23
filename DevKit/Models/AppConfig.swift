import Foundation

struct DocRootPreset: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var path: String
}

struct ClipboardSnippet: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var value: String
}

struct AppConfig: Codable {
    var refreshInterval: Int = 3
    var theme: String = "System"
    var brewPath: String = "/usr/local/bin/brew"
    var launchAtLogin: Bool = false
    var docrootPresets: [DocRootPreset] = [
        DocRootPreset(name: "www", path: "~/Desktop/www"),
        DocRootPreset(name: "IVS", path: "~/Desktop/IVS/public")
    ]
    var portPresets: [Int] = [3000, 5173, 8000, 8080, 4200]
    var clipboardSnippets: [ClipboardSnippet] = []
}
