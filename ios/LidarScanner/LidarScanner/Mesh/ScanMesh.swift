import ARKit
import simd

/// A single triangle mesh merged from all LiDAR mesh anchors, in metres, Y up.
struct ScanMesh {
    var positions: [SIMD3<Float>] = []
    var normals: [SIMD3<Float>] = []
    /// Per-vertex RGB. Empty when the scan has no colour.
    var colors: [SIMD3<UInt8>] = []
    var indices: [UInt32] = []

    var vertexCount: Int { positions.count }
    var triangleCount: Int { indices.count / 3 }
    var hasColor: Bool { !colors.isEmpty && colors.count == positions.count }

    init() {}

    /// Merges anchors into world space.
    init(anchors: [ARMeshAnchor]) {
        let totalVertices = anchors.reduce(0) { $0 + $1.geometry.vertices.count }
        let totalIndices = anchors.reduce(0) { $0 + $1.geometry.faces.count * 3 }
        positions.reserveCapacity(totalVertices)
        normals.reserveCapacity(totalVertices)
        indices.reserveCapacity(totalIndices)

        for anchor in anchors {
            let geometry = anchor.geometry
            let transform = anchor.transform
            let rotation = simd_float3x3(
                SIMD3(transform.columns.0.x, transform.columns.0.y, transform.columns.0.z),
                SIMD3(transform.columns.1.x, transform.columns.1.y, transform.columns.1.z),
                SIMD3(transform.columns.2.x, transform.columns.2.y, transform.columns.2.z)
            )

            let base = UInt32(positions.count)
            let vertices = geometry.vertices
            let vertexNormals = geometry.normals
            let hasNormals = vertexNormals.count == vertices.count

            for i in 0..<vertices.count {
                let local = vertices.float3(at: i)
                let world = transform * SIMD4(local, 1)
                positions.append(SIMD3(world.x, world.y, world.z))

                var normal = SIMD3<Float>(0, 1, 0)
                if hasNormals {
                    let n = rotation * vertexNormals.float3(at: i)
                    let length = simd_length(n)
                    if length > 1e-6 { normal = n / length }
                }
                normals.append(normal)
            }

            let faces = geometry.faces
            guard faces.indexCountPerPrimitive == 3 else { continue }
            let count = faces.count * 3
            let raw = faces.buffer.contents()
            switch faces.bytesPerIndex {
            case 4:
                let p = raw.assumingMemoryBound(to: UInt32.self)
                for i in 0..<count { indices.append(base + p[i]) }
            case 2:
                let p = raw.assumingMemoryBound(to: UInt16.self)
                for i in 0..<count { indices.append(base + UInt32(p[i])) }
            default:
                continue
            }
        }
    }

    var bounds: (min: SIMD3<Float>, max: SIMD3<Float>) {
        guard var lo = positions.first else { return (.zero, .zero) }
        var hi = lo
        for p in positions {
            lo = simd_min(lo, p)
            hi = simd_max(hi, p)
        }
        return (lo, hi)
    }

    /// Moves the mesh so it sits on the origin: centred in X/Z, lowest point at Y = 0.
    /// Makes it land nicely in Blender and other DCC tools.
    mutating func recenter() {
        let (lo, hi) = bounds
        let offset = SIMD3<Float>(-(lo.x + hi.x) / 2, -lo.y, -(lo.z + hi.z) / 2)
        for i in positions.indices {
            positions[i] += offset
        }
    }
}

extension ARGeometrySource {
    func float3(at index: Int) -> SIMD3<Float> {
        let p = buffer.contents()
            .advanced(by: offset + stride * index)
            .assumingMemoryBound(to: Float.self)
        return SIMD3(p[0], p[1], p[2])
    }
}
