import ARKit
import UIKit

/// Turns raw LiDAR anchors + keyframes into a saved scan folder with OBJ, PLY, USDZ and a thumbnail.
enum ScanExporter {

    static func export(anchors: [ARMeshAnchor], keyframes: [Keyframe], progress: (String, Double) -> Void) throws -> SavedScan {
        progress("Building mesh", 0.02)
        var mesh = ScanMesh(anchors: anchors)
        guard mesh.triangleCount > 0 else { throw ScanError.emptyScan }

        if !keyframes.isEmpty {
            let stage = "Coloring from \(keyframes.count) photos"
            progress(stage, 0.05)
            MeshColorizer.colorize(&mesh, keyframes: keyframes) { value in
                progress(stage, 0.05 + 0.6 * value)
            }
        }

        mesh.recenter()

        let scan = SavedScan.makeNew(vertexCount: mesh.vertexCount, triangleCount: mesh.triangleCount, hasColor: mesh.hasColor)
        try FileManager.default.createDirectory(at: scan.folder, withIntermediateDirectories: true)

        progress("Writing PLY", 0.68)
        try MeshFileIO.writePLY(mesh, to: scan.plyURL)

        progress("Writing OBJ", 0.75)
        try MeshFileIO.writeOBJ(mesh, to: scan.objURL)

        progress("Writing USDZ", 0.86)
        _ = MeshScene.writeUSDZ(mesh, to: scan.usdzURL)

        progress("Rendering thumbnail", 0.95)
        if let image = MeshScene.renderThumbnail(mesh), let jpeg = image.jpegData(compressionQuality: 0.85) {
            try? jpeg.write(to: scan.thumbnailURL)
        }

        try scan.saveMetadata()
        progress("Done", 1)
        return scan
    }
}
