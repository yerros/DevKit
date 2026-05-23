import Foundation

enum ServiceState: String {
    case running
    case stopped
    case unknown
    case starting
    case error
}

struct ServiceStatus: Identifiable {
    let id: String
    let name: String
    var state: ServiceState
}
