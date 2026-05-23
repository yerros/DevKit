import Foundation

enum DocRootManager {
    static let configPath = "/usr/local/etc/httpd/httpd.conf"

    static func getCurrentDocRoot() -> String? {
        guard let content = try? String(contentsOfFile: configPath, encoding: .utf8) else {
            return nil
        }
        for line in content.components(separatedBy: "\n") {
            if let match = line.range(of: #"^DocumentRoot\s+"(.+)""#, options: .regularExpression) {
                let fullMatch = String(line[match])
                if let quoteStart = fullMatch.firstIndex(of: "\""),
                   let quoteEnd = fullMatch.lastIndex(of: "\""),
                   quoteStart != quoteEnd {
                    let startIdx = fullMatch.index(after: quoteStart)
                    return String(fullMatch[startIdx..<quoteEnd])
                }
            }
        }
        return nil
    }

    static func switchDocRoot(to path: String) async throws {
        let expandedPath = (path as NSString).expandingTildeInPath
        let fm = FileManager.default
        guard fm.fileExists(atPath: expandedPath) else {
            throw DocRootError.directoryNotFound(expandedPath)
        }

        try await backupConfig()

        let sedDocRoot = "sed -i '' 's#^DocumentRoot .*#DocumentRoot \"\(expandedPath)\"#' \(configPath)"
        let sedDirectory = "sed -i '' 's#^<Directory .*#<Directory \"\(expandedPath)\">#' \(configPath)"
        _ = try await Shell.run("\(sedDocRoot) && \(sedDirectory)", sudo: true)

        try await ServiceManager.restart("httpd")
    }

    static func backupConfig() async throws {
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let backupPath = "\(configPath).bak.\(timestamp)"
        _ = try await Shell.run("cp \(configPath) \(backupPath)", sudo: true)
    }
}

enum DocRootError: LocalizedError {
    case directoryNotFound(String)
    case configNotFound

    var errorDescription: String? {
        switch self {
        case .directoryNotFound(let path):
            return "Directory not found: \(path)"
        case .configNotFound:
            return "httpd.conf not found at expected path"
        }
    }
}
