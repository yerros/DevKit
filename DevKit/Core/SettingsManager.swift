import Foundation

enum SettingsManager {
    private static let configDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".devkit")
    private static let configFile = configDir.appendingPathComponent("config.json")

    static func load() -> AppConfig {
        ensureConfigExists()
        do {
            let data = try Data(contentsOf: configFile)
            return try JSONDecoder().decode(AppConfig.self, from: data)
        } catch {
            return AppConfig()
        }
    }

    static func save(_ config: AppConfig) {
        ensureConfigExists()
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(config)
            try data.write(to: configFile, options: .atomic)
        } catch {
            print("Failed to save config: \(error)")
        }
    }

    // MARK: - Launch at Login

    private static let plistPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/LaunchAgents/com.yeris.devkit.plist")

    static func enableLaunchAtLogin() async throws {
        let appPath = Bundle.main.bundlePath + "/Contents/MacOS/DevKit"
        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.yeris.devkit</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(appPath)</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
        </dict>
        </plist>
        """

        let launchAgentsDir = plistPath.deletingLastPathComponent()
        let fm = FileManager.default
        if !fm.fileExists(atPath: launchAgentsDir.path) {
            try fm.createDirectory(at: launchAgentsDir, withIntermediateDirectories: true)
        }
        try plistContent.write(to: plistPath, atomically: true, encoding: .utf8)
        _ = try await Shell.run("launchctl load \(plistPath.path)")
    }

    static func disableLaunchAtLogin() async throws {
        _ = try? await Shell.run("launchctl unload \(plistPath.path)")
        try? FileManager.default.removeItem(at: plistPath)
    }

    // MARK: - Private

    private static func ensureConfigExists() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: configDir.path) {
            try? fm.createDirectory(at: configDir, withIntermediateDirectories: true)
        }
        if !fm.fileExists(atPath: configFile.path) {
            save(AppConfig())
        }
    }
}
