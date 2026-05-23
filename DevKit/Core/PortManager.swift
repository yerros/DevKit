import Foundation

struct PortEntry: Identifiable {
    let id = UUID()
    let pid: Int
    let port: Int
    let processName: String
}

enum PortManager {
    static func listPorts() async -> [PortEntry] {
        do {
            let output = try await Shell.run("lsof -i -P -n | grep LISTEN")
            return parseLsofOutput(output)
        } catch {
            return []
        }
    }

    static func killPort(_ port: Int) async throws {
        let pidOutput = try await Shell.run("lsof -ti :\(port)")
        let pids = pidOutput.components(separatedBy: "\n").filter { !$0.isEmpty }
        for pid in pids {
            _ = try? await Shell.run("kill -9 \(pid)")
        }
    }

    private static func parseLsofOutput(_ output: String) -> [PortEntry] {
        var entries: [PortEntry] = []
        var seen = Set<String>()

        for line in output.components(separatedBy: "\n") {
            let cols = line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
            guard cols.count >= 9 else { continue }

            let processName = cols[0]
            guard let pid = Int(cols[1]) else { continue }

            let nameCol = cols[8]
            guard let portStr = nameCol.split(separator: ":").last,
                  let port = Int(portStr.replacingOccurrences(of: " (LISTEN)", with: "")) else { continue }

            let key = "\(pid)-\(port)"
            guard !seen.contains(key) else { continue }
            seen.insert(key)

            entries.append(PortEntry(pid: pid, port: port, processName: processName))
        }

        return entries.sorted { $0.port < $1.port }
    }
}
