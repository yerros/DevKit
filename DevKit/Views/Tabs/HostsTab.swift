import SwiftUI

struct HostsTab: View {
    @State private var entries: [HostEntry] = []
    @State private var newIP: String = ""
    @State private var newHostname: String = ""
    @State private var newComment: String = ""
    @State private var statusMessage: String = ""
    @State private var isSaving: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                hostsSection
                dnsSection
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
        .onAppear { loadHosts() }
    }

    // MARK: - Hosts Section

    private var hostsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("/etc/hosts")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    Spacer()
                    GlassButton("Save Changes", disabled: isSaving, isLoading: isSaving) {
                        saveHosts()
                    }
                }

                // Table header
                HStack(spacing: 0) {
                    Text("IP Address").frame(width: 130, alignment: .leading)
                    Text("Hostname").frame(width: 160, alignment: .leading)
                    Text("Comment").frame(maxWidth: .infinity, alignment: .leading)
                    Text("").frame(width: 30)
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.4))

                ForEach(entries) { entry in
                    hostRow(entry)
                }

                Divider().background(Color.white.opacity(0.1))

                addEntryRow

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
    }

    private func hostRow(_ entry: HostEntry) -> some View {
        Group {
            if entry.isComment {
                Text(entry.comment)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 2)
            } else {
                HStack(spacing: 0) {
                    Text(entry.ip)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(width: 130, alignment: .leading)
                    Text(entry.hostname)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(width: 160, alignment: .leading)
                    Text(entry.comment)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button(action: { deleteEntry(entry) }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                    .frame(width: 30)
                }
                .foregroundColor(.white.opacity(0.7))
                .padding(.vertical, 2)
            }
        }
    }

    private var addEntryRow: some View {
        HStack(spacing: 8) {
            GlassTextField(placeholder: "IP Address", text: $newIP, isMonospaced: true)
                .frame(width: 130)
            GlassTextField(placeholder: "Hostname", text: $newHostname, isMonospaced: true)
                .frame(width: 160)
            GlassTextField(placeholder: "Comment", text: $newComment)
                .frame(maxWidth: .infinity)
            GlassButton("Add", disabled: newIP.isEmpty || newHostname.isEmpty) {
                addEntry()
            }
        }
    }

    // MARK: - DNS Section

    private var dnsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("DNS Cache")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))

                GlassButton("Flush DNS Cache") {
                    flushDNS()
                }
            }
        }
    }

    // MARK: - Actions

    private func loadHosts() {
        entries = HostsManager.readHosts()
    }

    private func addEntry() {
        let entry = HostEntry(ip: newIP, hostname: newHostname, comment: newComment, isComment: false, rawLine: "")
        entries.append(entry)
        newIP = ""
        newHostname = ""
        newComment = ""
    }

    private func deleteEntry(_ entry: HostEntry) {
        entries.removeAll { $0.id == entry.id }
    }

    private func saveHosts() {
        isSaving = true
        Task {
            do {
                try await HostsManager.writeHosts(entries)
                await MainActor.run {
                    statusMessage = "Hosts file saved successfully"
                    loadHosts()
                }
            } catch let error as ShellError where error == .privilegeEscalationCancelled {
                await MainActor.run { statusMessage = "Save cancelled" }
            } catch {
                await MainActor.run { statusMessage = "Error: \(error.localizedDescription)" }
            }
            await MainActor.run { isSaving = false }
        }
    }

    private func flushDNS() {
        Task {
            do {
                try await HostsManager.flushDNS()
                await MainActor.run { statusMessage = "DNS cache flushed successfully" }
            } catch let error as ShellError where error == .privilegeEscalationCancelled {
                await MainActor.run { statusMessage = "Flush cancelled" }
            } catch {
                await MainActor.run { statusMessage = "Error: \(error.localizedDescription)" }
            }
        }
    }
}

extension ShellError: Equatable {
    static func == (lhs: ShellError, rhs: ShellError) -> Bool {
        switch (lhs, rhs) {
        case (.privilegeEscalationCancelled, .privilegeEscalationCancelled): return true
        case (.nonZeroExit(let a, _), .nonZeroExit(let b, _)): return a == b
        default: return false
        }
    }
}
