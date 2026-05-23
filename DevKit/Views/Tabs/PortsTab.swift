import SwiftUI

struct PortsTab: View {
    @EnvironmentObject var appState: AppState
    @State private var ports: [PortEntry] = []
    @State private var manualPort: String = ""
    @State private var searchText: String = ""
    @State private var statusMessage: String = ""
    @State private var isLoading: Bool = false

    private var filteredPorts: [PortEntry] {
        if searchText.isEmpty { return ports }
        let query = searchText.lowercased()
        return ports.filter {
            "\($0.port)".contains(query) ||
            $0.processName.lowercased().contains(query) ||
            "\($0.pid)".contains(query)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                presetsSection
                manualKillSection
                activePortsSection
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
        .task { await refreshPorts() }
    }

    // MARK: - Presets

    private var presetsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Kill Presets")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))

                HStack(spacing: 10) {
                    ForEach(appState.config.portPresets, id: \.self) { port in
                        presetButton(port)
                    }
                }

                HStack(spacing: 4) {
                    Circle().fill(Color(red: 0.20, green: 0.83, blue: 0.60)).frame(width: 6, height: 6)
                    Text("= in use")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                    Circle().fill(Color.gray).frame(width: 6, height: 6).padding(.leading, 8)
                    Text("= free")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
    }

    private func presetButton(_ port: Int) -> some View {
        let isActive = ports.contains { $0.port == port }
        return Button(action: { killPort(port) }) {
            Text("\(port)")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
                .shadow(
                    color: isActive ? Color(red: 0.20, green: 0.83, blue: 0.60).opacity(0.4) : .clear,
                    radius: 8, x: 0, y: 0
                )
        }
        .buttonStyle(.plain)
        .disabled(!isActive)
    }

    // MARK: - Manual Kill

    private var manualKillSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Manual Kill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))

                HStack(spacing: 8) {
                    GlassTextField(placeholder: "Port number", text: $manualPort, isMonospaced: true)
                        .frame(width: 150)
                    GlassButton("Kill Port", style: .destructive, disabled: manualPort.isEmpty) {
                        if let port = Int(manualPort) {
                            killPort(port)
                            manualPort = ""
                        }
                    }
                }

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
    }

    // MARK: - Active Ports Table

    private var activePortsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Active Ports")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    Spacer()
                    GlassButton("Refresh ↻", isLoading: isLoading) {
                        Task { await refreshPorts() }
                    }
                }

                // Search/filter
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                    GlassTextField(placeholder: "Filter by port, PID, or process...", text: $searchText)
                }

                if filteredPorts.isEmpty && !isLoading {
                    Text(searchText.isEmpty ? "No listening ports found" : "No ports matching \"\(searchText)\"")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.vertical, 12)
                } else {
                    // Header
                    HStack(spacing: 0) {
                        Text("PID").frame(width: 60, alignment: .leading)
                        Text("Port").frame(width: 70, alignment: .leading)
                        Text("Process").frame(maxWidth: .infinity, alignment: .leading)
                        Text("Action").frame(width: 60, alignment: .trailing)
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.bottom, 4)

                    ForEach(filteredPorts) { entry in
                        portRow(entry)
                    }
                }
            }
        }
    }

    private func portRow(_ entry: PortEntry) -> some View {
        HStack(spacing: 0) {
            Text("\(entry.pid)")
                .font(.system(size: 12, design: .monospaced))
                .frame(width: 60, alignment: .leading)
            Text("\(entry.port)")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .frame(width: 70, alignment: .leading)
            Text(entry.processName)
                .font(.system(size: 12))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
            GlassButton("Kill", style: .destructive) {
                killPort(entry.port)
            }
            .frame(width: 60, alignment: .trailing)
        }
        .foregroundColor(.white.opacity(0.7))
        .padding(.vertical, 3)
    }

    // MARK: - Actions

    private func refreshPorts() async {
        isLoading = true
        ports = await PortManager.listPorts()
        isLoading = false
    }

    private func killPort(_ port: Int) {
        Task {
            do {
                try await PortManager.killPort(port)
                statusMessage = "Port \(port) killed"
                try? await Task.sleep(nanoseconds: 500_000_000)
                await refreshPorts()
            } catch {
                statusMessage = "Failed to kill port \(port): \(error.localizedDescription)"
            }
        }
    }
}
