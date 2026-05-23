import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openWindow) private var openWindow
    @State private var services: [ServiceStatus] = []
    @State private var actionInProgress: String? = nil

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("DevKit")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Button("Open App") {
                    openWindow(id: "main")
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(red: 0.29, green: 0.62, blue: 1.0))
            }

            Divider().background(Color.white.opacity(0.1))

            VStack(spacing: 8) {
                ForEach(services) { service in
                    menuServiceRow(service)
                }
                if services.isEmpty {
                    Text("Checking services...")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.vertical, 8)
                }
            }

            Divider().background(Color.white.opacity(0.1))

            if let docRoot = DocRootManager.getCurrentDocRoot() {
                HStack {
                    Text("DocRoot:")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                    Text(docRoot)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Divider().background(Color.white.opacity(0.1))
            }

            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Text("Quit DevKit")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(width: 300)
        .preferredColorScheme(.dark)
        .task {
            await refreshServices()
            startAutoRefresh()
        }
    }

    private func menuServiceRow(_ service: ServiceStatus) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                StatusDot(state: service.state)
                Text(service.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                Text(service.state.rawValue.capitalized)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
            }
            HStack(spacing: 6) {
                menuActionButton("Start", disabled: service.state == .running) {
                    performAction("start", service: service.id)
                }
                menuActionButton("Stop", disabled: service.state == .stopped) {
                    performAction("stop", service: service.id)
                }
                menuActionButton("Restart", disabled: service.state == .stopped) {
                    performAction("restart", service: service.id)
                }
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }

    private func menuActionButton(_ title: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(disabled ? .white.opacity(0.3) : .white.opacity(0.8))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .disabled(disabled || actionInProgress != nil)
    }

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
            } catch {}
            actionInProgress = nil
        }
    }

    private func refreshServices() async {
        ServiceManager.brewPath = appState.config.brewPath
        services = await ServiceManager.getStatus()
    }

    private func startAutoRefresh() {
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(appState.config.refreshInterval) * 1_000_000_000)
                await refreshServices()
            }
        }
    }
}
