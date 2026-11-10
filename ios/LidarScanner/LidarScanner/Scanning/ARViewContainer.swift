import ARKit
import RealityKit
import SwiftUI

struct ARViewContainer: UIViewRepresentable {
    let scanner: ScanSession

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        view.renderOptions.insert(.disableMotionBlur)

        let coaching = ARCoachingOverlayView()
        coaching.session = view.session
        coaching.goal = .tracking
        coaching.activatesAutomatically = true
        coaching.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coaching.frame = view.bounds
        view.addSubview(coaching)

        scanner.attach(to: view)
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}
