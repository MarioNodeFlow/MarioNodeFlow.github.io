import Foundation
import simd

/// Gives every mesh vertex a colour by projecting it into the best keyframe photo:
/// one that sees the vertex face-on, close up, near the image centre and not hidden
/// behind something else (checked against the LiDAR depth of that frame).
enum MeshColorizer {

    static let fallbackColor = SIMD3<UInt8>(150, 150, 150)

    static func colorize(_ mesh: inout ScanMesh, keyframes: [Keyframe], progress: (Double) -> Void) {
        let count = mesh.positions.count
        var colors = [SIMD3<UInt8>](repeating: fallbackColor, count: count)
        guard !keyframes.isEmpty, count > 0 else {
            mesh.colors = colors
            return
        }

        let positions = mesh.positions
        let normals = mesh.normals
        let chunkSize = 4096
        let chunkCount = (count + chunkSize - 1) / chunkSize
        let lock = NSLock()
        var finished = 0

        colors.withUnsafeMutableBufferPointer { buffer in
            let out = buffer // plain pointer copy: each chunk writes its own range
            DispatchQueue.concurrentPerform(iterations: chunkCount) { chunk in
                let start = chunk * chunkSize
                let end = min(count, start + chunkSize)
                for i in start..<end {
                    if let color = bestColor(position: positions[i], normal: normals[i], keyframes: keyframes) {
                        out[i] = color
                    }
                }
                lock.lock()
                finished += 1
                let value = Double(finished) / Double(chunkCount)
                progress(value)
                lock.unlock()
            }
        }
        mesh.colors = colors
    }

    private static func bestColor(position p: SIMD3<Float>, normal n: SIMD3<Float>, keyframes: [Keyframe]) -> SIMD3<UInt8>? {
        var bestScore: Float = 0
        var best: SIMD3<UInt8>?

        for frame in keyframes {
            let camera = frame.worldToCamera * SIMD4(p, 1)
            let z = -camera.z // ARKit cameras look down -Z
            if z < 0.05 || z > 6 { continue }

            let u = frame.fx * camera.x / z + frame.cx
            let v = frame.fy * -camera.y / z + frame.cy
            if u < 1 || v < 1 || u >= Float(frame.width - 1) || v >= Float(frame.height - 1) { continue }

            let toCamera = frame.position - p
            let distance = simd_length(toCamera)
            let facing = simd_dot(n, toCamera) / max(distance, 1e-4)
            if facing < 0.2 { continue }

            if !frame.depth.isEmpty {
                let du = min(frame.depthWidth - 1, Int(u * Float(frame.depthWidth) / Float(frame.width)))
                let dv = min(frame.depthHeight - 1, Int(v * Float(frame.depthHeight) / Float(frame.height)))
                let measured = frame.depth[dv * frame.depthWidth + du]
                if measured > 0, z > measured + max(0.04, 0.03 * z) { continue } // occluded
            }

            let nu = u / Float(frame.width) - 0.5
            let nv = v / Float(frame.height) - 0.5
            let centred = 1 - 1.5 * (nu * nu + nv * nv)
            let score = facing * centred / (0.3 + z)
            if score > bestScore {
                bestScore = score
                let index = (Int(v) * frame.width + Int(u)) * 3
                best = SIMD3(frame.rgb[index], frame.rgb[index + 1], frame.rgb[index + 2])
            }
        }
        return best
    }
}
