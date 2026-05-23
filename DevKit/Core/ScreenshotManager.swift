import Foundation
import AppKit

enum ScreenshotManager {
    static let desktopURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")

    static func scan() -> (files: [URL], totalSize: Int64) {
        let fm = FileManager.default
        do {
            let contents = try fm.contentsOfDirectory(at: desktopURL, includingPropertiesForKeys: [.fileSizeKey])
            let screenshots = contents.filter { url in
                let name = url.lastPathComponent
                return name.hasPrefix("Screenshot") && name.hasSuffix(".png")
            }
            var totalSize: Int64 = 0
            for file in screenshots {
                if let attrs = try? fm.attributesOfItem(atPath: file.path),
                   let size = attrs[.size] as? Int64 {
                    totalSize += size
                }
            }
            return (screenshots, totalSize)
        } catch {
            return ([], 0)
        }
    }

    static func trashAll(_ files: [URL]) async throws {
        await withCheckedContinuation { continuation in
            NSWorkspace.shared.recycle(files) { _, error in
                continuation.resume()
            }
        }
    }

    static func formatSize(_ bytes: Int64) -> String {
        let mb = Double(bytes) / 1_048_576.0
        if mb < 1 {
            let kb = Double(bytes) / 1024.0
            return String(format: "%.1f KB", kb)
        }
        return String(format: "%.1f MB", mb)
    }
}
