import Foundation

enum ShellError: LocalizedError {
    case nonZeroExit(Int32, String)
    case privilegeEscalationCancelled

    var errorDescription: String? {
        switch self {
        case .nonZeroExit(let code, let output):
            return "Command failed (exit \(code)): \(output)"
        case .privilegeEscalationCancelled:
            return "Administrator permission was cancelled"
        }
    }
}

enum Shell {
    static func run(_ command: String, sudo: Bool = false) async throws -> String {
        if sudo {
            return try await runWithPrivileges(command)
        }
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                let pipe = Pipe()
                process.executableURL = URL(fileURLWithPath: "/bin/zsh")
                process.arguments = ["-l", "-c", command]
                process.standardOutput = pipe
                process.standardError = pipe
                var env = ProcessInfo.processInfo.environment
                let brewPaths = "/usr/local/bin:/usr/local/sbin"
                if let path = env["PATH"] {
                    if !path.contains("/usr/local/bin") {
                        env["PATH"] = brewPaths + ":" + path
                    }
                } else {
                    env["PATH"] = brewPaths + ":/usr/bin:/bin:/usr/sbin:/sbin"
                }
                process.environment = env
                do {
                    try process.run()
                    process.waitUntilExit()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    if process.terminationStatus != 0 {
                        continuation.resume(throwing: ShellError.nonZeroExit(process.terminationStatus, output))
                    } else {
                        continuation.resume(returning: output)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    static func runWithPrivileges(_ command: String) async throws -> String {
        let escaped = command
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let script = "do shell script \"\(escaped)\" with administrator privileges"
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                let pipe = Pipe()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
                process.arguments = ["-e", script]
                process.standardOutput = pipe
                process.standardError = pipe
                do {
                    try process.run()
                    process.waitUntilExit()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    if process.terminationStatus != 0 {
                        if output.contains("User canceled") || output.contains("-128") {
                            continuation.resume(throwing: ShellError.privilegeEscalationCancelled)
                        } else {
                            continuation.resume(throwing: ShellError.nonZeroExit(process.terminationStatus, output))
                        }
                    } else {
                        continuation.resume(returning: output)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
