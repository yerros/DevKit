import SwiftUI

struct ScreenshotsTab: View {
    @State private var files: [URL] = []
    @State private var totalSize: Int64 = 0
    @State private var isLoading: Bool = false
    @State private var statusMessage: String = ""

    var body: some View {
        VStack(spacing: 20) {
            GlassCard {
                VStack(spacing: 20) {
                    Text("Screenshot Cleaner")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if files.isEmpty && !isLoading {
                        emptyState
                    } else {
                        statsView
                    }

                    HStack(spacing: 12) {
                        GlassButton("Clean All →", style: .destructive, disabled: files.isEmpty || isLoading) {
                            cleanAll()
                        }
                        GlassButton("Refresh Scan ↻", isLoading: isLoading) {
                            scanScreenshots()
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scans: ~/Desktop/Screenshot*.png")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                        Text("Files are moved to Trash, not permanently deleted.")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.04, blue: 0.07),
                         Color(red: 0.06, green: 0.06, blue: 0.16)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onAppear { scanScreenshots() }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 36))
                .foregroundColor(.white.opacity(0.3))
            Text("No screenshots found on Desktop")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.vertical, 20)
    }

    private var statsView: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "photo.stack")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.7))
                Text("\(files.count) screenshots")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Text("·")
                    .foregroundColor(.white.opacity(0.4))
                Text(ScreenshotManager.formatSize(totalSize))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 12)
    }

    private func scanScreenshots() {
        isLoading = true
        let result = ScreenshotManager.scan()
        files = result.files
        totalSize = result.totalSize
        isLoading = false
        statusMessage = ""
    }

    private func cleanAll() {
        guard !files.isEmpty else { return }
        isLoading = true
        Task {
            try? await ScreenshotManager.trashAll(files)
            await MainActor.run {
                statusMessage = "Moved \(files.count) screenshots to Trash"
                scanScreenshots()
            }
        }
    }
}
