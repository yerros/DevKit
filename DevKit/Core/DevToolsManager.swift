import Foundation

enum DevToolsManager {
    private static let tools: [(name: String, command: String)] = [
        ("Node.js", "node -v"),
        ("npm", "npm -v"),
        ("PHP", "php -v"),
        ("Python 3", "python3 --version"),
        ("Git", "git --version"),
        ("Composer", "composer --version"),
        ("Homebrew", "brew --version")
    ]

    static func checkVersions() async -> [DevTool] {
        await withTaskGroup(of: DevTool.self) { group in
            for tool in tools {
                group.addTask {
                    await checkTool(name: tool.name, command: tool.command)
                }
            }
            var results: [DevTool] = []
            for await result in group {
                results.append(result)
            }
            let order = tools.map { $0.name }
            return results.sorted { order.firstIndex(of: $0.name) ?? 0 < order.firstIndex(of: $1.name) ?? 0 }
        }
    }

    private static func checkTool(name: String, command: String) async -> DevTool {
        do {
            let output = try await Shell.run(command)
            let version = parseVersion(output, tool: name)
            let path = try? await Shell.run("which \(command.split(separator: " ").first ?? "")")
            return DevTool(name: name, version: version, path: path)
        } catch {
            return DevTool(name: name, version: nil, path: nil)
        }
    }

    private static func parseVersion(_ output: String, tool: String) -> String {
        let firstLine = output.components(separatedBy: "\n").first ?? output
        switch tool {
        case "PHP":
            if let match = firstLine.range(of: #"\d+\.\d+\.\d+"#, options: .regularExpression) {
                return String(firstLine[match])
            }
        case "Git":
            return firstLine.replacingOccurrences(of: "git version ", with: "")
        case "Composer":
            if let match = firstLine.range(of: #"\d+\.\d+\.\d+"#, options: .regularExpression) {
                return String(firstLine[match])
            }
        case "Homebrew":
            return firstLine.replacingOccurrences(of: "Homebrew ", with: "")
        case "Python 3":
            return firstLine.replacingOccurrences(of: "Python ", with: "")
        default:
            return firstLine.trimmingCharacters(in: .whitespaces)
        }
        return firstLine
    }

    static func getDiskUsage() -> [DiskPartition] {
        let fm = FileManager.default
        var partitions: [DiskPartition] = []

        guard let mountedVolumes = fm.mountedVolumeURLs(includingResourceValuesForKeys: [
            .volumeNameKey, .volumeTotalCapacityKey, .volumeAvailableCapacityKey
        ], options: [.skipHiddenVolumes]) else {
            return []
        }

        for volume in mountedVolumes {
            do {
                let values = try volume.resourceValues(forKeys: [
                    .volumeTotalCapacityKey, .volumeAvailableCapacityKey, .volumeNameKey
                ])
                guard let total = values.volumeTotalCapacity,
                      let available = values.volumeAvailableCapacity else { continue }

                let totalBytes = Int64(total)
                let freeBytes = Int64(available)
                let usedBytes = totalBytes - freeBytes
                let percent = totalBytes > 0 ? Double(usedBytes) / Double(totalBytes) * 100.0 : 0

                partitions.append(DiskPartition(
                    device: volume.lastPathComponent,
                    mountPoint: volume.path,
                    totalBytes: totalBytes,
                    usedBytes: usedBytes,
                    freeBytes: freeBytes,
                    percent: percent
                ))
            } catch {
                continue
            }
        }

        return partitions
    }

    static func formatBytes(_ bytes: Int64) -> String {
        let gb = Double(bytes) / 1_073_741_824.0
        if gb >= 1 {
            return String(format: "%.1f GB", gb)
        }
        let mb = Double(bytes) / 1_048_576.0
        return String(format: "%.1f MB", mb)
    }
}
