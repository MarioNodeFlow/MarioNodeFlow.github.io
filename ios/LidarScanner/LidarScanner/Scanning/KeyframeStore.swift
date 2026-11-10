import ARKit
import simd

/// A downsampled camera photo plus everything needed to project world points into it.
struct Keyframe {
    let width: Int
    let height: Int
    /// Tightly packed RGB, row 0 = top of the sensor image (same orientation as the intrinsics).
    let rgb: [UInt8]

    let depthWidth: Int
    let depthHeight: Int
    /// LiDAR depth in metres, same orientation as `rgb`. Empty if unavailable.
    let depth: [Float]

    let worldToCamera: simd_float4x4
    let position: SIMD3<Float>
    let forward: SIMD3<Float>

    // Intrinsics scaled to `width` x `height`.
    let fx: Float
    let fy: Float
    let cx: Float
    let cy: Float
}

/// Picks well-spaced, sharp camera frames during a scan and keeps a bounded set of them.
final class KeyframeStore {
    private(set) var frames: [Keyframe] = []
    var count: Int { frames.count }

    private let maxFrames = 120
    private let targetWidth = 480

    private var lastCaptureTime: TimeInterval = 0
    private var previousTransform: simd_float4x4?
    private var previousTime: TimeInterval = 0

    func removeAll() {
        frames.removeAll()
        lastCaptureTime = 0
        previousTransform = nil
    }

    func snapshot() -> [Keyframe] { frames }

    func shouldCapture(_ frame: ARFrame) -> Bool {
        let transform = frame.camera.transform
        defer {
            previousTransform = transform
            previousTime = frame.timestamp
        }

        guard case .normal = frame.camera.trackingState else { return false }
        guard frame.timestamp - lastCaptureTime > 0.3 else { return false }

        // Skip frames taken while turning fast: they are motion blurred.
        if let previous = previousTransform, frame.timestamp > previousTime {
            let dt = Float(frame.timestamp - previousTime)
            let angle = Self.angle(between: Self.forward(of: previous), and: Self.forward(of: transform))
            if angle / dt > 1.2 { return false }
        }

        guard let last = frames.last else { return true }
        let moved = simd_distance(Self.position(of: transform), last.position)
        let turned = Self.angle(between: Self.forward(of: transform), and: last.forward)
        return moved > 0.08 || turned > 0.15
    }

    func capture(_ frame: ARFrame) {
        lastCaptureTime = frame.timestamp
        guard let image = Self.downsampleRGB(frame.capturedImage, targetWidth: targetWidth) else { return }

        let resolution = frame.camera.imageResolution
        let sx = Float(image.width) / Float(resolution.width)
        let sy = Float(image.height) / Float(resolution.height)
        let k = frame.camera.intrinsics

        var depth: [Float] = []
        var depthWidth = 0
        var depthHeight = 0
        if let map = frame.sceneDepth?.depthMap {
            (depth, depthWidth, depthHeight) = Self.copyDepth(map)
        }

        let transform = frame.camera.transform
        frames.append(Keyframe(
            width: image.width,
            height: image.height,
            rgb: image.rgb,
            depthWidth: depthWidth,
            depthHeight: depthHeight,
            depth: depth,
            worldToCamera: transform.inverse,
            position: Self.position(of: transform),
            forward: Self.forward(of: transform),
            fx: k[0][0] * sx,
            fy: k[1][1] * sy,
            cx: k[2][0] * sx,
            cy: k[2][1] * sy
        ))

        if frames.count > maxFrames { dropMostRedundantFrame() }
    }

    /// Removes the frame whose viewpoint is closest to another one, keeping coverage spread out.
    private func dropMostRedundantFrame() {
        guard frames.count > 2 else { return }
        var dropIndex = 0
        var smallest = Float.greatestFiniteMagnitude
        for i in 0..<(frames.count - 1) { // never drop the newest frame
            var nearest = Float.greatestFiniteMagnitude
            for j in 0..<frames.count where j != i {
                let d = simd_distance(frames[i].position, frames[j].position)
                    + (1 - simd_dot(frames[i].forward, frames[j].forward))
                nearest = min(nearest, d)
            }
            if nearest < smallest {
                smallest = nearest
                dropIndex = i
            }
        }
        frames.remove(at: dropIndex)
    }

    // MARK: - Pixel helpers

    /// Converts the camera's bi-planar YCbCr image to a small RGB buffer.
    static func downsampleRGB(_ buffer: CVPixelBuffer, targetWidth: Int) -> (rgb: [UInt8], width: Int, height: Int)? {
        guard CVPixelBufferGetPlaneCount(buffer) >= 2 else { return nil }
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }

        guard let yBase = CVPixelBufferGetBaseAddressOfPlane(buffer, 0),
              let cBase = CVPixelBufferGetBaseAddressOfPlane(buffer, 1) else { return nil }

        let srcW = CVPixelBufferGetWidthOfPlane(buffer, 0)
        let srcH = CVPixelBufferGetHeightOfPlane(buffer, 0)
        let chromaW = CVPixelBufferGetWidthOfPlane(buffer, 1)
        let chromaH = CVPixelBufferGetHeightOfPlane(buffer, 1)
        let yStride = CVPixelBufferGetBytesPerRowOfPlane(buffer, 0)
        let cStride = CVPixelBufferGetBytesPerRowOfPlane(buffer, 1)
        guard srcW > 0, srcH > 0, chromaW > 0, chromaH > 0 else { return nil }

        let videoRange = CVPixelBufferGetPixelFormatType(buffer) == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        let w = min(targetWidth, srcW)
        let h = max(1, srcH * w / srcW)
        let yPlane = yBase.assumingMemoryBound(to: UInt8.self)
        let cPlane = cBase.assumingMemoryBound(to: UInt8.self)

        var rgb = [UInt8](repeating: 0, count: w * h * 3)
        rgb.withUnsafeMutableBufferPointer { out in
            for y in 0..<h {
                let sy = min(srcH - 1, (y * srcH + srcH / 2) / h)
                let cy = min(chromaH - 1, sy * chromaH / srcH)
                for x in 0..<w {
                    let sx = min(srcW - 1, (x * srcW + srcW / 2) / w)
                    let cx = min(chromaW - 1, sx * chromaW / srcW)

                    var luma = Float(yPlane[sy * yStride + sx])
                    var cb = Float(cPlane[cy * cStride + cx * 2]) - 128
                    var cr = Float(cPlane[cy * cStride + cx * 2 + 1]) - 128
                    if videoRange {
                        luma = (luma - 16) * 1.164
                        cb *= 1.138
                        cr *= 1.138
                    }

                    let r = luma + 1.402 * cr
                    let g = luma - 0.344136 * cb - 0.714136 * cr
                    let b = luma + 1.772 * cb

                    let o = (y * w + x) * 3
                    out[o] = UInt8(clamping: Int(r.rounded()))
                    out[o + 1] = UInt8(clamping: Int(g.rounded()))
                    out[o + 2] = UInt8(clamping: Int(b.rounded()))
                }
            }
        }
        return (rgb, w, h)
    }

    static func copyDepth(_ map: CVPixelBuffer) -> ([Float], Int, Int) {
        guard CVPixelBufferGetPixelFormatType(map) == kCVPixelFormatType_DepthFloat32 else { return ([], 0, 0) }
        CVPixelBufferLockBaseAddress(map, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(map, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(map) else { return ([], 0, 0) }

        let w = CVPixelBufferGetWidth(map)
        let h = CVPixelBufferGetHeight(map)
        let stride = CVPixelBufferGetBytesPerRow(map)
        var out = [Float](repeating: 0, count: w * h)
        for y in 0..<h {
            let row = base.advanced(by: y * stride).assumingMemoryBound(to: Float.self)
            for x in 0..<w {
                out[y * w + x] = row[x]
            }
        }
        return (out, w, h)
    }

    // MARK: - Pose helpers

    static func position(of t: simd_float4x4) -> SIMD3<Float> {
        SIMD3(t.columns.3.x, t.columns.3.y, t.columns.3.z)
    }

    static func forward(of t: simd_float4x4) -> SIMD3<Float> {
        -SIMD3(t.columns.2.x, t.columns.2.y, t.columns.2.z)
    }

    static func angle(between a: SIMD3<Float>, and b: SIMD3<Float>) -> Float {
        acos(min(1, max(-1, simd_dot(a, b))))
    }
}
