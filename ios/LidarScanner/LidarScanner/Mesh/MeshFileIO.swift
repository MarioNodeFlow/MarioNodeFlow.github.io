import Foundation
import simd

enum MeshFileError: LocalizedError {
    case unreadable(String)

    var errorDescription: String? {
        switch self {
        case .unreadable(let reason): return "Couldn't read mesh: \(reason)"
        }
    }
}

/// Writes OBJ and binary PLY files (both keep vertex colours) and reads the PLY back for the preview.
enum MeshFileIO {

    // MARK: - PLY

    static func writePLY(_ mesh: ScanMesh, to url: URL) throws {
        let hasColor = mesh.hasColor
        var header = """
        ply
        format binary_little_endian 1.0
        comment LiDAR Scanner export, units: metres, Y up
        element vertex \(mesh.vertexCount)
        property float x
        property float y
        property float z
        property float nx
        property float ny
        property float nz

        """
        if hasColor {
            header += "property uchar red\nproperty uchar green\nproperty uchar blue\n"
        }
        header += "element face \(mesh.triangleCount)\nproperty list uchar int vertex_indices\nend_header\n"

        let headerBytes = Array(header.utf8)
        let vertexStride = 24 + (hasColor ? 3 : 0)
        let faceStride = 1 + 12
        let total = headerBytes.count + mesh.vertexCount * vertexStride + mesh.triangleCount * faceStride

        var bytes = [UInt8](repeating: 0, count: total)
        bytes.withUnsafeMutableBytes { raw in
            var o = 0
            for b in headerBytes {
                raw[o] = b
                o += 1
            }
            for i in 0..<mesh.vertexCount {
                let p = mesh.positions[i]
                let n = mesh.normals[i]
                raw.storeBytes(of: p.x, toByteOffset: o, as: Float.self)
                raw.storeBytes(of: p.y, toByteOffset: o + 4, as: Float.self)
                raw.storeBytes(of: p.z, toByteOffset: o + 8, as: Float.self)
                raw.storeBytes(of: n.x, toByteOffset: o + 12, as: Float.self)
                raw.storeBytes(of: n.y, toByteOffset: o + 16, as: Float.self)
                raw.storeBytes(of: n.z, toByteOffset: o + 20, as: Float.self)
                o += 24
                if hasColor {
                    let c = mesh.colors[i]
                    raw[o] = c.x
                    raw[o + 1] = c.y
                    raw[o + 2] = c.z
                    o += 3
                }
            }
            for t in 0..<mesh.triangleCount {
                raw[o] = 3
                o += 1
                for k in 0..<3 {
                    raw.storeBytes(of: Int32(mesh.indices[t * 3 + k]), toByteOffset: o, as: Int32.self)
                    o += 4
                }
            }
        }
        try Data(bytes).write(to: url, options: .atomic)
    }

    static func readPLY(from url: URL) throws -> ScanMesh {
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        guard let end = data.range(of: Data("end_header\n".utf8)) else {
            throw MeshFileError.unreadable("missing PLY header")
        }
        let header = String(decoding: data[data.startIndex..<end.upperBound], as: UTF8.self)
        guard header.contains("binary_little_endian") else {
            throw MeshFileError.unreadable("only binary little-endian PLY is supported")
        }

        var vertexCount = 0
        var faceCount = 0
        for line in header.split(separator: "\n") {
            let parts = line.split(separator: " ")
            if parts.count == 3, parts[0] == "element" {
                if parts[1] == "vertex" { vertexCount = Int(parts[2]) ?? 0 }
                if parts[1] == "face" { faceCount = Int(parts[2]) ?? 0 }
            }
        }
        let hasNormals = header.contains("property float nx")
        let hasColor = header.contains("property uchar red")
        let vertexStride = 12 + (hasNormals ? 12 : 0) + (hasColor ? 3 : 0)
        let bodyStart = end.upperBound - data.startIndex
        guard data.count >= bodyStart + vertexCount * vertexStride + faceCount * 13 else {
            throw MeshFileError.unreadable("file is truncated")
        }

        var mesh = ScanMesh()
        mesh.positions.reserveCapacity(vertexCount)
        mesh.normals.reserveCapacity(vertexCount)
        if hasColor { mesh.colors.reserveCapacity(vertexCount) }
        mesh.indices.reserveCapacity(faceCount * 3)

        try data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            var o = bodyStart
            func float() -> Float {
                defer { o += 4 }
                return raw.loadUnaligned(fromByteOffset: o, as: Float.self)
            }
            for _ in 0..<vertexCount {
                mesh.positions.append(SIMD3(float(), float(), float()))
                mesh.normals.append(hasNormals ? SIMD3(float(), float(), float()) : SIMD3(0, 1, 0))
                if hasColor {
                    mesh.colors.append(SIMD3(raw[o], raw[o + 1], raw[o + 2]))
                    o += 3
                }
            }
            for _ in 0..<faceCount {
                guard raw[o] == 3 else { throw MeshFileError.unreadable("only triangle meshes are supported") }
                o += 1
                for _ in 0..<3 {
                    let index = raw.loadUnaligned(fromByteOffset: o, as: Int32.self)
                    mesh.indices.append(UInt32(max(0, index)))
                    o += 4
                }
            }
        }
        return mesh
    }

    // MARK: - OBJ

    /// OBJ with per-vertex colours as `v x y z r g b` (read by Blender, MeshLab, ZBrush, CloudCompare).
    static func writeOBJ(_ mesh: ScanMesh, to url: URL) throws {
        FileManager.default.createFile(atPath: url.path, contents: nil)
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }

        let hasColor = mesh.hasColor
        let colorStrings = (0...255).map { String(format: "%.4f", Double($0) / 255) }
        var buffer = ""
        buffer.reserveCapacity(1 << 21)

        func flushIfNeeded(force: Bool = false) throws {
            if force || buffer.utf8.count > 1 << 20 {
                try handle.write(contentsOf: Data(buffer.utf8))
                buffer.removeAll(keepingCapacity: true)
            }
        }

        buffer += "# LiDAR Scanner export\n# units: metres, Y up\n"
        buffer += "# vertices: \(mesh.vertexCount)  triangles: \(mesh.triangleCount)\no scan\n"

        for i in 0..<mesh.vertexCount {
            let p = mesh.positions[i]
            buffer += "v \(rounded(p.x)) \(rounded(p.y)) \(rounded(p.z))"
            if hasColor {
                let c = mesh.colors[i]
                buffer += " \(colorStrings[Int(c.x)]) \(colorStrings[Int(c.y)]) \(colorStrings[Int(c.z)])"
            }
            buffer += "\n"
            try flushIfNeeded()
        }
        for n in mesh.normals {
            buffer += "vn \(rounded(n.x)) \(rounded(n.y)) \(rounded(n.z))\n"
            try flushIfNeeded()
        }
        for t in 0..<mesh.triangleCount {
            let a = mesh.indices[t * 3] + 1
            let b = mesh.indices[t * 3 + 1] + 1
            let c = mesh.indices[t * 3 + 2] + 1
            buffer += "f \(a)//\(a) \(b)//\(b) \(c)//\(c)\n"
            try flushIfNeeded()
        }
        try flushIfNeeded(force: true)
    }

    private static func rounded(_ value: Float) -> Float {
        (value * 100_000).rounded() / 100_000
    }
}
