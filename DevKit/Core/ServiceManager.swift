import Foundation

enum ServiceManager {
    static var brewPath: String = "/usr/local/bin/brew"

    static func getStatus() async -> [ServiceStatus] {
        do {
            let output = try await Shell.run("\(brewPath) services list")
            return parseServiceList(output)
        } catch {
            return [
                ServiceStatus(id: "httpd", name: "Apache", state: .unknown),
                ServiceStatus(id: "mysql", name: "MySQL", state: .unknown)
            ]
        }
    }

    static func start(_ service: String) async throws {
        _ = try await Shell.run("\(brewPath) services start \(service)")
    }

    static func stop(_ service: String) async throws {
        _ = try await Shell.run("\(brewPath) services stop \(service)")
    }

    static func restart(_ service: String) async throws {
        _ = try await Shell.run("\(brewPath) services restart \(service)")
    }

    private static func parseServiceList(_ output: String) -> [ServiceStatus] {
        let lines = output.components(separatedBy: "\n")
        var results: [ServiceStatus] = []

        let serviceMap: [String: String] = ["httpd": "Apache", "mysql": "MySQL"]

        for line in lines {
            let columns = line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
            guard columns.count >= 2 else { continue }
            let serviceName = columns[0]
            guard let displayName = serviceMap[serviceName] else { continue }

            let state: ServiceState
            if columns.contains("started") || columns.contains("running") {
                state = .running
            } else if columns.contains("stopped") || columns.contains("none") {
                state = .stopped
            } else if columns.contains("error") {
                state = .error
            } else {
                state = .stopped
            }

            results.append(ServiceStatus(id: serviceName, name: displayName, state: state))
        }

        for (id, name) in serviceMap where !results.contains(where: { $0.id == id }) {
            results.append(ServiceStatus(id: id, name: name, state: .unknown))
        }

        return results.sorted { $0.id < $1.id }
    }
}
