import Foundation

struct HostEntry: Identifiable {
    let id = UUID()
    var ip: String
    var hostname: String
    var comment: String
    var isComment: Bool
    var rawLine: String
}

enum HostsManager {
    static let hostsPath = "/etc/hosts"

    static func readHosts() -> [HostEntry] {
        guard let content = try? String(contentsOfFile: hostsPath, encoding: .utf8) else {
            return []
        }
        var entries: [HostEntry] = []
        for line in content.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            if trimmed.hasPrefix("#") {
                entries.append(HostEntry(ip: "", hostname: "", comment: trimmed, isComment: true, rawLine: line))
                continue
            }

            let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            guard parts.count >= 2 else {
                entries.append(HostEntry(ip: "", hostname: "", comment: trimmed, isComment: true, rawLine: line))
                continue
            }

            let ip = parts[0]
            let hostname = parts[1]
            var comment = ""
            if let hashIdx = trimmed.range(of: "#") {
                comment = String(trimmed[hashIdx.upperBound...]).trimmingCharacters(in: .whitespaces)
            }

            entries.append(HostEntry(ip: ip, hostname: hostname, comment: comment, isComment: false, rawLine: line))
        }
        return entries
    }

    static func writeHosts(_ entries: [HostEntry]) async throws {
        var lines: [String] = []
        for entry in entries {
            if entry.isComment {
                lines.append(entry.rawLine.isEmpty ? entry.comment : entry.rawLine)
            } else {
                var line = "\(entry.ip)\t\(entry.hostname)"
                if !entry.comment.isEmpty {
                    line += " # \(entry.comment)"
                }
                lines.append(line)
            }
        }
        let content = lines.joined(separator: "\n") + "\n"
        let escaped = content
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\t", with: "\\t")

        let command = "printf \"\(escaped)\" > \(hostsPath)"
        _ = try await Shell.run(command, sudo: true)
    }

    static func flushDNS() async throws {
        _ = try await Shell.run("dscacheutil -flushcache; killall -HUP mDNSResponder", sudo: true)
    }
}
