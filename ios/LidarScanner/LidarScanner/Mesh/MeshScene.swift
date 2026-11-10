import SceneKit
import UIKit
import simd

enum PreviewStyle: String, CaseIterable, Identifiable {
    case color = "Color"
    case clay = "Clay"
    case wireframe = "Wireframe"

    var id: String { rawValue }
}

/// Builds SceneKit scenes from a `ScanMesh` for the in-app preview, USDZ export and thumbnails.
enum MeshScene {

    static func makeGeometry(_ mesh: ScanMesh, style: PreviewStyle) -> SCNGeometry {
        let vertices = SCNGeometrySource(vertices: mesh.positions.map { SCNVector3(x: $0.x, y: $0.y, z: $0.z) })
        let normals = SCNGeometrySource(normals: mesh.normals.map { SCNVector3(x: $0.x, y: $0.y, z: $0.z) })
        var sources = [vertices, normals]

        let useColor = style != .clay && mesh.hasColor
        if useColor {
            var floats = [Float]()
            floats.reserveCapacity(mesh.colors.count * 3)
            for c in mesh.colors {
                floats.append(Float(c.x) / 255)
                floats.append(Float(c.y) / 255)
                floats.append(Float(c.z) / 255)
            }
            let data = floats.withUnsafeBufferPointer { Data(buffer: $0) }
            sources.append(SCNGeometrySource(
                data: data,
                semantic: .color,
                vectorCount: mesh.colors.count,
                usesFloatComponents: true,
                componentsPerVector: 3,
                bytesPerComponent: MemoryLayout<Float>.size,
                dataOffset: 0,
                dataStride: MemoryLayout<Float>.size * 3
            ))
        }

        let element = SCNGeometryElement(indices: mesh.indices, primitiveType: .triangles)
        let geometry = SCNGeometry(sources: sources, elements: [element])

        let material = SCNMaterial()
        material.isDoubleSided = true
        switch style {
        case .color:
            // Captured colours already contain the real-world lighting.
            material.lightingModel = useColor ? .constant : .blinn
            material.diffuse.contents = useColor ? UIColor.white : UIColor(white: 0.8, alpha: 1)
        case .clay:
            material.lightingModel = .blinn
            material.diffuse.contents = UIColor(white: 0.82, alpha: 1)
            material.specular.contents = UIColor(white: 0.15, alpha: 1)
        case .wireframe:
            material.lightingModel = .constant
            material.fillMode = .lines
            material.diffuse.contents = useColor ? UIColor.white : UIColor.cyan
        }
        geometry.materials = [material]
        return geometry
    }

    /// Returns the scene and a pivot node at the origin that can be spun for a turntable.
    static func makeScene(_ mesh: ScanMesh, style: PreviewStyle) -> (scene: SCNScene, pivot: SCNNode, model: SCNNode) {
        let scene = SCNScene()
        let pivot = SCNNode()
        pivot.name = "pivot"
        let model = SCNNode(geometry: makeGeometry(mesh, style: style))
        model.name = "scan"
        pivot.addChildNode(model)
        scene.rootNode.addChildNode(pivot)
        return (scene, pivot, model)
    }

    static func center(of mesh: ScanMesh) -> SCNVector3 {
        let (lo, hi) = mesh.bounds
        let c = (lo + hi) / 2
        return SCNVector3(x: c.x, y: c.y, z: c.z)
    }

    static func makeCameraNode(for mesh: ScanMesh) -> SCNNode {
        let (lo, hi) = mesh.bounds
        let center = (lo + hi) / 2
        let radius = max(0.05, simd_length(hi - lo) / 2)

        let camera = SCNCamera()
        camera.fieldOfView = 40
        let distance = radius / sin(Float(camera.fieldOfView / 2) * .pi / 180) * 1.05
        camera.zNear = Double(max(0.01, distance - radius * 2))
        camera.zFar = Double(distance + radius * 4)

        let node = SCNNode()
        node.camera = camera
        let direction = simd_normalize(SIMD3<Float>(0, 0.55, 1))
        let position = center + direction * distance
        node.position = SCNVector3(x: position.x, y: position.y, z: position.z)
        node.look(at: SCNVector3(x: center.x, y: center.y, z: center.z))
        return node
    }

    static func writeUSDZ(_ mesh: ScanMesh, to url: URL) -> Bool {
        let (scene, _, _) = makeScene(mesh, style: .color)
        return scene.write(to: url, options: nil, delegate: nil, progressHandler: nil)
    }

    static func renderThumbnail(_ mesh: ScanMesh, size: CGSize = CGSize(width: 600, height: 600)) -> UIImage? {
        guard let device = MTLCreateSystemDefaultDevice() else { return nil }
        let (scene, _, _) = makeScene(mesh, style: .color)
        let camera = makeCameraNode(for: mesh)
        scene.rootNode.addChildNode(camera)
        scene.background.contents = UIColor(white: 0.09, alpha: 1)

        let renderer = SCNRenderer(device: device, options: nil)
        renderer.scene = scene
        renderer.pointOfView = camera
        renderer.autoenablesDefaultLighting = true
        return renderer.snapshot(atTime: 0, with: size, antialiasingMode: .multisampling4X)
    }
}
