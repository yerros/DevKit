import SwiftUI

struct ServicesTab: View {
    @EnvironmentObject var appState: AppState
    @State private var services: [ServiceStatus] = []
    @State private var currentDocRoot: String = "Loading..."
    @State private var statusMessage: String = ""
    @State private var lastChecked: Date = Date()
    @State private var actionInProgress: String? = nil
    @State private var newPresetName: String = ""
    @State private var newPresetPath: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                serviceMonitorSection
                docRootSection
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
        .task {
            await refreshServices()
            loadDocRoot()
            startAutoRefresh()
        }
    }

    // MARK: - Service Monitor

    private var serviceMonitorSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Services")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))

                ForEach(services) { service in
                    serviceRow(service)
                }

                if services.isEmpty {
                    Text("Checking services...")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }

                Divider().background(Color.white.opacity(0.1))

                HStack {
                    Text("Last checked: \(lastChecked, formatter: timeFormatter)")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                    if !statusMessage.isEmpty {
                        Text("·")
                            .foregroundColor(.white.opacity(0.3))
                        Text(statusMessage)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
    }

    private func serviceRow(_ service: ServiceStatus) -> some View {
        HStack(spacing: 12) {
            StatusDot(state: service.state)

            Text(service.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 60, alignment: .leading)

            Text(service.state.rawValue.capitalized)
                .font(.system(size: 12))
                .foregroundColor(stateColor(service.state))
                .frame(width: 70, alignment: .leading)

            Spacer()

            HStack(spacing: 8) {
                GlassButton("Start", disabled: service.state == .running || actionInProgress != nil) {
                    performAction("start", service: service.id)
                }
                GlassButton("Stop", disabled: service.state == .stopped || actionInProgress != nil) {
                    performAction("stop", service: service.id)
                }
                GlassButton("Restart", disabled: service.state == .stopped || actionInProgress != nil) {
                    performAction("restart", service: service.id)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - DocumentRoot

    private var docRootSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("DocumentRoot")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))

                HStack {
                    Text("Current:")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                    Text(currentDocRoot)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                }

                ForEach(appState.config.docrootPresets) { preset in
                    presetRow(preset)
                }

                Divider().background(Color.white.opacity(0.1))

                addPresetRow
            }
        }
    }

    private func presetRow(_ preset: DocRootPreset) -> some View {
        let isActive = currentDocRoot == (preset.path as NSString).expandingTildeInPath
            || currentDocRoot == preset.path

        return HStack(spacing: 12) {
            Text(preset.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 60, alignment: .leading)

            Text(preset.path)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(1)

            Spacer()

            GlassButton(isActive ? "Active ✓" : "Apply", disabled: isActive || actionInProgress != nil) {
                applyDocRoot(preset.path)
            }

            Button(action: { deletePreset(preset) }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
            .buttonStyle(.plain)
            .frame(width: 20, height: 20)
        }
        .padding(.vertical, 2)
    }

    private var addPresetRow: some View {
        HStack(spacing: 8) {
            TextField("Name", text: $newPresetName)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .padding(6)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                .frame(width: 80)

            TextField("Path", text: $newPresetPath)
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .monospaced))
                .padding(6)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.1), lineWidth: 0.5))

            Button("Browse") {
                browseFolder()
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(Color(red: 0.29, green: 0.62, blue: 1.0))

            GlassButton("+ Add", disabled: newPresetName.isEmpty || newPresetPath.isEmpty) {
                addPreset()
            }
        }
    }

    // MARK: - Actions

    private func performAction(_ action: String, service: String) {
        actionInProgress = "\(action)-\(service)"
        Task {
            do {
                switch action {
                case "start": try await ServiceManager.start(service)
                case "stop": try await ServiceManager.stop(service)
                case "restart": try await ServiceManager.restart(service)
                default: break
                }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await refreshServices()
                let displayName = service == "httpd" ? "Apache" : "MySQL"
                statusMessage = "\(displayName) \(action) successful"
            } catch {
                statusMessage = "Error: \(error.localizedDescription)"
            }
            actionInProgress = nil
        }
    }

    private func refreshServices() async {
        ServiceManager.brewPath = appState.config.brewPath
        services = await ServiceManager.getStatus()
        lastChecked = Date()
        updateMenuBarIcon()
    }

    private func updateMenuBarIcon() {
        let running = services.filter { $0.state == .running }.count
        if running == services.count && !services.isEmpty {
            appState.menuBarIcon = "server.rack"
        } else if running > 0 {
            appState.menuBarIcon = "server.rack"
        } else {
            appState.menuBarIcon = "server.rack"
        }
    }

    private func loadDocRoot() {
        if let docRoot = DocRootManager.getCurrentDocRoot() {
            currentDocRoot = docRoot
        } else {
            currentDocRoot = "Not found"
        }
    }

    private func applyDocRoot(_ path: String) {
        actionInProgress = "docroot"
        Task {
            do {
                try await DocRootManager.switchDocRoot(to: path)
                loadDocRoot()
                statusMessage = "DocumentRoot switched successfully"
            } catch {
                statusMessage = "Error: \(error.localizedDescription)"
            }
            actionInProgress = nil
        }
    }

    private func addPreset() {
        let preset = DocRootPreset(name: newPresetName, path: newPresetPath)
        appState.config.docrootPresets.append(preset)
        appState.saveConfig()
        newPresetName = ""
        newPresetPath = ""
    }

    private func deletePreset(_ preset: DocRootPreset) {
        appState.config.docrootPresets.removeAll { $0.id == preset.id }
        appState.saveConfig()
    }

    private func browseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            newPresetPath = url.path
        }
    }

    private func startAutoRefresh() {
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(appState.config.refreshInterval) * 1_000_000_000)
                await refreshServices()
            }
        }
    }

    private func stateColor(_ state: ServiceState) -> Color {
        switch state {
        case .running: return Color(red: 0.20, green: 0.83, blue: 0.60)
        case .stopped: return Color(red: 0.97, green: 0.44, blue: 0.44)
        case .starting: return Color(red: 0.98, green: 0.75, blue: 0.15)
        case .error: return Color(red: 0.97, green: 0.44, blue: 0.44)
        case .unknown: return Color(red: 0.42, green: 0.45, blue: 0.50)
        }
    }

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }
}
