import SwiftUI

struct DevToolsTab: View {
    @EnvironmentObject var appState: AppState
    @State private var tools: [DevTool] = []
    @State private var disks: [DiskPartition] = []
    @State private var isLoadingTools: Bool = false
    @State private var copiedId: UUID? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                environmentSection
                diskSection
                clipboardSection
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
            await loadTools()
            loadDisks()
        }
    }

    // MARK: - Environment

    private var environmentSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Environment")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    Spacer()
                    GlassButton("Refresh ↻", isLoading: isLoadingTools) {
                        Task { await loadTools() }
                    }
                }

                ForEach(tools) { tool in
                    HStack(spacing: 12) {
                        Text(tool.name)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 80, alignment: .leading)

                        if let version = tool.version {
                            Text(version)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 120, alignment: .leading)
                        } else {
                            Text("Not found")
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.97, green: 0.44, blue: 0.44))
                                .frame(width: 120, alignment: .leading)
                        }

                        if let path = tool.path, !path.isEmpty {
                            Text(path)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.white.opacity(0.4))
                                .lineLimit(1)
                        }

                        Spacer()

                        Circle()
                            .fill(tool.version != nil
                                  ? Color(red: 0.20, green: 0.83, blue: 0.60)
                                  : Color(red: 0.97, green: 0.44, blue: 0.44))
                            .frame(width: 8, height: 8)
                            .shadow(color: (tool.version != nil
                                            ? Color(red: 0.20, green: 0.83, blue: 0.60)
                                            : Color(red: 0.97, green: 0.44, blue: 0.44)).opacity(0.5),
                                    radius: 4, x: 0, y: 0)
                    }
                    .padding(.vertical, 2)
                }

                if tools.isEmpty && isLoadingTools {
                    HStack {
                        ProgressView().scaleEffect(0.7)
                        Text("Checking versions...")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
        }
    }

    // MARK: - Disk Usage

    private var diskSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Disk Usage")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))

                ForEach(disks) { disk in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(disk.device)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            Text("—")
                                .foregroundColor(.white.opacity(0.3))
                            Text(disk.mountPoint)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                                .lineLimit(1)
                        }

                        HStack(spacing: 12) {
                            GlowingProgress(value: disk.percent)
                            Text(String(format: "%.0f%%", disk.percent))
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 36, alignment: .trailing)
                            Text("\(DevToolsManager.formatBytes(disk.freeBytes)) free")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 90, alignment: .trailing)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if disks.isEmpty {
                    Text("No volumes found")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
    }

    // MARK: - Clipboard

    private var clipboardSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Dev Clipboard")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))

                ForEach(appState.config.clipboardSnippets) { snippet in
                    snippetRow(snippet)
                }

                Divider().background(Color.white.opacity(0.1))

                addSnippetRow
            }
        }
    }

    private func snippetRow(_ snippet: ClipboardSnippet) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(snippet.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                Spacer()
                GlassButton(copiedId == snippet.id ? "Copied!" : "Copy") {
                    copySnippet(snippet)
                }
                Button(action: { deleteSnippet(snippet) }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
                .frame(width: 20, height: 20)
            }
            Text(snippet.value)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(8)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @State private var newSnippetName: String = ""
    @State private var newSnippetValue: String = ""

    private var addSnippetRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            GlassTextField(placeholder: "Name", text: $newSnippetName)
            GlassTextField(placeholder: "Value", text: $newSnippetValue, isMonospaced: true)
            GlassButton("+ Save", disabled: newSnippetName.isEmpty || newSnippetValue.isEmpty) {
                addSnippet()
            }
        }
    }

    // MARK: - Actions

    private func loadTools() async {
        isLoadingTools = true
        tools = await DevToolsManager.checkVersions()
        isLoadingTools = false
    }

    private func loadDisks() {
        disks = DevToolsManager.getDiskUsage()
    }

    private func copySnippet(_ snippet: ClipboardSnippet) {
        ClipboardManager.copy(snippet.value)
        copiedId = snippet.id
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run { copiedId = nil }
        }
    }

    private func addSnippet() {
        let snippet = ClipboardSnippet(name: newSnippetName, value: newSnippetValue)
        appState.config.clipboardSnippets.append(snippet)
        appState.saveConfig()
        newSnippetName = ""
        newSnippetValue = ""
    }

    private func deleteSnippet(_ snippet: ClipboardSnippet) {
        appState.config.clipboardSnippets.removeAll { $0.id == snippet.id }
        appState.saveConfig()
    }
}
