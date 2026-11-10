import ARKit
import RealityKit
import SwiftUI

enum ScanError: LocalizedError {
    case emptyScan

    var errorDescription: String? {
        switch self {
        case .emptyScan:
            return "No mesh was captured yet. Scan a little longer and move around the subject."
        }
    }
}

/// Owns the AR session: runs LiDAR scene reconstruction, collects mesh anchors and
/// colour keyframes, and hands everything to `ScanExporter` when the user saves.
final class ScanSession: NSObject, ObservableObject, ARSessionDelegate {

    enum Phase {
        case ready      // camera running, nothing being recorded
        case scanning   // LiDAR mesh is being built
        case paused     // session frozen, mesh kept, ready to save
    }

    static var isSupported: Bool {
        ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
    }

    @Published private(set) var phase: Phase = .ready
    @Published private(set) var triangleCount = 0
    @Published private(set) var keyframeCount = 0
    @Published private(set) var trackingHint: String?

    @Published var showMeshOverlay = true {
        didSet { applyDebugOptions() }
    }
    /// Captures camera photos while scanning so the exported mesh gets vertex colours.
    @Published var captureColor = true

    @Published private(set) var isSaving = false
    @Published private(set) var saveProgress: Double = 0
    @Published private(set) var saveStage = ""

    private weak var arView: ARView?
    private var meshAnchors: [UUID: ARMeshAnchor] = [:]
    private let keyframes = KeyframeStore()
    private var lastStatsUpdate: TimeInterval = 0

    // MARK: - Setup

    func attach(to view: ARView) {
        arView = view
        view.session.delegate = self
        applyDebugOptions()
        runReadyConfiguration()
    }

    private func applyDebugOptions() {
        guard let view = arView else { return }
        if showMeshOverlay {
            view.debugOptions.insert(.showSceneUnderstanding)
        } else {
            view.debugOptions.remove(.showSceneUnderstanding)
        }
    }

    private func makeScanConfiguration() -> ARWorldTrackingConfiguration {
        let config = ARWorldTrackingConfiguration()
        config.sceneReconstruction = .mesh
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            // Used to reject occluded photos when colouring the mesh.
            config.frameSemantics.insert(.sceneDepth)
        }
        config.environmentTexturing = .none
        return config
    }

    private func runReadyConfiguration() {
        arView?.session.run(ARWorldTrackingConfiguration(), options: [.resetTracking, .removeExistingAnchors])
    }

    // MARK: - Controls

    func startScan() {
        guard let view = arView else { return }
        meshAnchors.removeAll()
        keyframes.removeAll()
        keyframeCount = 0
        updateStats(force: true)
        phase = .scanning
        view.session.run(makeScanConfiguration(), options: [.removeExistingAnchors])
        UIApplication.shared.isIdleTimerDisabled = true
    }

    func pauseScan() {
        arView?.session.pause()
        phase = .paused
        updateStats(force: true)
        UIApplication.shared.isIdleTimerDisabled = false
    }

    func resumeScan() {
        phase = .scanning
        arView?.session.run(makeScanConfiguration())
        UIApplication.shared.isIdleTimerDisabled = true
    }

    func discard() {
        meshAnchors.removeAll()
        keyframes.removeAll()
        keyframeCount = 0
        triangleCount = 0
        phase = .ready
        trackingHint = nil
        UIApplication.shared.isIdleTimerDisabled = false
        runReadyConfiguration()
    }

    func save(completion: @escaping (Result<SavedScan, Error>) -> Void) {
        let anchors = Array(meshAnchors.values)
        guard !anchors.isEmpty else {
            completion(.failure(ScanError.emptyScan))
            return
        }
        if phase == .scanning { pauseScan() }

        let frames = captureColor ? keyframes.snapshot() : []
        isSaving = true
        saveProgress = 0
        saveStage = "Building mesh"

        DispatchQueue.global(qos: .userInitiated).async {
            let report: (String, Double) -> Void = { stage, value in
                DispatchQueue.main.async {
                    self.saveStage = stage
                    self.saveProgress = value
                }
            }
            let result = Result {
                try ScanExporter.export(anchors: anchors, keyframes: frames, progress: report)
            }
            DispatchQueue.main.async {
                self.isSaving = false
                completion(result)
            }
        }
    }

    // MARK: - ARSessionDelegate

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        ingest(anchors)
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        ingest(anchors)
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        for case let anchor as ARMeshAnchor in anchors {
            meshAnchors[anchor.identifier] = nil
        }
        updateStats(force: false)
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard phase == .scanning, captureColor else { return }
        if keyframes.shouldCapture(frame) {
            keyframes.capture(frame)
            keyframeCount = keyframes.count
        }
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .normal:
            trackingHint = nil
        case .notAvailable:
            trackingHint = "Tracking unavailable"
        case .limited(let reason):
            switch reason {
            case .initializing:
                trackingHint = "Getting ready… move your iPhone slowly"
            case .excessiveMotion:
                trackingHint = "Slow down"
            case .insufficientFeatures:
                trackingHint = "Point at more detailed surfaces or add light"
            case .relocalizing:
                trackingHint = "Relocalizing… return to where you were"
            @unknown default:
                trackingHint = "Tracking limited"
            }
        }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        trackingHint = error.localizedDescription
    }

    // MARK: - Helpers

    private func ingest(_ anchors: [ARAnchor]) {
        guard phase == .scanning else { return }
        for case let anchor as ARMeshAnchor in anchors {
            meshAnchors[anchor.identifier] = anchor
        }
        updateStats(force: false)
    }

    private func updateStats(force: Bool) {
        let now = CACurrentMediaTime()
        guard force || now - lastStatsUpdate > 0.5 else { return }
        lastStatsUpdate = now
        triangleCount = meshAnchors.values.reduce(0) { $0 + $1.geometry.faces.count }
    }
}
