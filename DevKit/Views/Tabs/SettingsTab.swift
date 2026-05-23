import SwiftUI

struct SettingsTab: View {
    @EnvironmentObject var appState: AppState
    @State private var refreshInterval: Int = 3
    @State private var theme: String = "System"
    @State private var launchAtLogin: Bool = false
    @State private var brewPath: String = "/usr/local/bin/brew"
    @State private var statusMessage: String = ""
    @State private var isSaving: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                settingsSection
                aboutSection
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.04, blue: 0.07),
                         Color(red: 0.06, green: 0.06, blue: 0.16)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onAppear { loadSettings() }
    }

    private var settingsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 20) {
                Text("Settings")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))

                // Refresh Interval
                HStack {
                    Text("Refresh Interval")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 150, alignment: .leading)
                    Picker("", selection: $refreshInterval) {
                        Text("2 seconds").tag(2)
                        Text("3 seconds").tag(3)
                        Text("5 seconds").tag(5)
                        Text("10 seconds").tag(10)
                        Text("30 seconds").tag(30)
                        Text("60 seconds").tag(60)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 150)
                }

                // Appearance
                HStack {
                    Text("Appearance")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 150, alignment: .leading)
                    Picker("", selection: $theme) {
                        Text("System").tag("System")
                        Text("Light").tag("Light")
                        Text("Dark").tag("Dark")
                    }
                    .pickerStyle(.menu)
                    .frame(width: 150)
                }

                // Launch at Login
                HStack {
                    Text("Launch at Login")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 150, alignment: .leading)
                    Toggle("", isOn: $launchAtLogin)
                        .toggleStyle(.switch)
                }

                // Brew Path
                HStack {
                    Text("Homebrew Path")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 150, alignment: .leading)
                    GlassTextField(placeholder: "/usr/local/bin/brew", text: $brewPath, isMonospaced: true)
                }

                Divider().background(Color.white.opacity(0.1))

                HStack {
                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                    GlassButton("Save Settings", isLoading: isSaving) {
                        saveSettings()
                    }
                }
            }
        }
    }

    private var aboutSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("About")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))

                Group {
                    Text("DevKit v1.0.0")
                    Text("Bundle: com.yeris.devkitv2")
                    Text("macOS 13+ · Swift · SwiftUI")
                }
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
            }
        }
    }

    // MARK: - Actions

    private func loadSettings() {
        refreshInterval = appState.config.refreshInterval
        theme = appState.config.theme
        launchAtLogin = appState.config.launchAtLogin
        brewPath = appState.config.brewPath
    }

    private func saveSettings() {
        isSaving = true
        appState.config.refreshInterval = refreshInterval
        appState.config.theme = theme
        appState.config.launchAtLogin = launchAtLogin
        appState.config.brewPath = brewPath
        appState.saveConfig()

        // Apply appearance
        applyTheme()

        // Handle launch at login
        Task {
            do {
                if launchAtLogin {
                    try await SettingsManager.enableLaunchAtLogin()
                } else {
                    try await SettingsManager.disableLaunchAtLogin()
                }
            } catch {
                // Non-fatal — plist management can fail in dev builds
            }
            await MainActor.run {
                statusMessage = "Settings saved"
                isSaving = false
            }
        }
    }

    private func applyTheme() {
        switch theme {
        case "Light":
            NSApp.appearance = NSAppearance(named: .aqua)
        case "Dark":
            NSApp.appearance = NSAppearance(named: .darkAqua)
        default:
            NSApp.appearance = nil
        }
    }
}
