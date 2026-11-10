import SceneKit
import SwiftUI

/// Orbit-able SceneKit preview of a scan with an optional turntable spin.
/// Drag to orbit, pinch to zoom, two fingers to pan.
struct ModelPreview: UIViewRepresentable {
    let mesh: ScanMesh
    let style: PreviewStyle
    let backdrop: UIColor
    let turntable: Bool

    final class Coordinator {
        var style: PreviewStyle?
        var pivot: SCNNode?
        var model: SCNNode?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = true
        view.antialiasingMode = .multisampling4X

        let (scene, pivot, model) = MeshScene.makeScene(mesh, style: style)
        let camera = MeshScene.makeCameraNode(for: mesh)
        scene.rootNode.addChildNode(camera)
        view.scene = scene
        view.pointOfView = camera
        view.defaultCameraController.target = MeshScene.center(of: mesh)

        context.coordinator.style = style
        context.coordinator.pivot = pivot
        context.coordinator.model = model
        updateUIView(view, context: context)
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        view.backgroundColor = backdrop
        view.scene?.background.contents = backdrop

        let coordinator = context.coordinator
        if coordinator.style != style {
            coordinator.model?.geometry = MeshScene.makeGeometry(mesh, style: style)
            coordinator.style = style
        }

        guard let pivot = coordinator.pivot else { return }
        if turntable {
            if pivot.action(forKey: "turntable") == nil {
                let spin = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 14)
                pivot.runAction(.repeatForever(spin), forKey: "turntable")
            }
        } else {
            pivot.removeAction(forKey: "turntable")
        }
    }
}
