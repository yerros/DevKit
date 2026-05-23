import Foundation

struct DevTool: Identifiable {
    let id = UUID()
    let name: String
    var version: String?
    var path: String?
}

struct DiskPartition: Identifiable {
    let id = UUID()
    let device: String
    let mountPoint: String
    let totalBytes: Int64
    let usedBytes: Int64
    let freeBytes: Int64
    var percent: Double
}
