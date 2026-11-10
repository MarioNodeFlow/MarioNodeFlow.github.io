import Foundation

/// One saved scan: a folder in Documents/Scans with OBJ, PLY, USDZ, a thumbnail and scan.json.
struct SavedScan: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    let date: Date
    let vertexCount: Int
    let triangleCount: Int
    let hasColor: Bool

    var folder: URL { ScanLibrary.rootURL.appendingPathComponent(id, isDirectory: true) }
    var objURL: URL { folder.appendingPathComponent("\(id).obj") }
    var plyURL: URL { folder.appendingPathComponent("\(id).ply") }
    var usdzURL: URL { folder.appendingPathComponent("\(id).usdz") }
    var thumbnailURL: URL { folder.appendingPathComponent("thumbnail.jpg") }
    var metadataURL: URL { folder.appendingPathComponent("scan.json") }

    static func makeNew(vertexCount: Int, triangleCount: Int, hasColor: Bool) -> SavedScan {
        let now = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return SavedScan(
            id: "Scan_\(formatter.string(from: now))",
            name: now.formatted(date: .abbreviated, time: .shortened),
            date: now,
            vertexCount: vertexCount,
            triangleCount: triangleCount,
            hasColor: hasColor
        )
    }

    func saveMetadata() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(self).write(to: metadataURL, options: .atomic)
    }

    func fileExists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }
}

final class ScanLibrary: ObservableObject {
    static var rootURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Scans", isDirectory: true)
    }

    @Published private(set) var scans: [SavedScan] = []

    init() {
        reload()
    }

    func reload() {
        let fm = FileManager.default
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let folders = (try? fm.contentsOfDirectory(at: Self.rootURL, includingPropertiesForKeys: nil)) ?? []
        scans = folders
            .compactMap { folder in
                guard let data = try? Data(contentsOf: folder.appendingPathComponent("scan.json")) else { return nil }
                return try? decoder.decode(SavedScan.self, from: data)
            }
            .sorted { $0.date > $1.date }
    }

    func delete(_ scan: SavedScan) {
        try? FileManager.default.removeItem(at: scan.folder)
        reload()
    }
}
