import SwiftUI

struct ScannerView: View {
    @StateObject private var scanner = ScanSession()
    @StateObject private var library = ScanLibrary()

    @State private var showLibrary = false
    @State private var openedScan: SavedScan?
    @State private var errorMessage: String?
    @State private var confirmDiscard = false

    var body: some View {
        ZStack {
            ARViewContainer(scanner: scanner)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                topBar
                if let hint = scanner.trackingHint, scanner.phase != .paused {
                    Pill(text: hint, systemImage: "exclamationmark.triangle.fill")
                        .transition(.opacity)
                }
                Spacer()
                bottomBar
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .animation(.easeInOut(duration: 0.2), value: scanner.trackingHint)

            if scanner.isSaving {
                SavingOverlay(stage: scanner.saveStage, progress: scanner.saveProgress)
            }
        }
        .sheet(isPresented: $showLibrary) {
            NavigationStack {
                ScanLibraryView(library: library)
            }
        }
        .sheet(item: $openedScan) { scan in
            NavigationStack {
                ScanDetailView(scan: scan, library: library, showsDoneButton: true)
            }
        }
        .alert("Couldn't save scan", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .confirmationDialog("Discard this scan?", isPresented: $confirmDiscard, titleVisibility: .visible) {
            Button("Discard", role: .destructive) { scanner.discard() }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 10) {
            if scanner.phase == .ready {
                Pill(text: "LiDAR ready", systemImage: "dot.radiowaves.left.and.right")
            } else {
                Pill(
                    text: "\(scanner.triangleCount.formatted(.number.notation(.compactName))) triangles"
                        + (scanner.captureColor ? " · \(scanner.keyframeCount) photos" : ""),
                    systemImage: scanner.phase == .scanning ? "record.circle" : "pause.circle"
                )
            }
            Spacer()
            CircleButton(
                systemImage: scanner.showMeshOverlay ? "square.grid.3x3.fill" : "square.grid.3x3",
                label: "Mesh overlay"
            ) {
                scanner.showMeshOverlay.toggle()
            }
            CircleButton(
                systemImage: scanner.captureColor ? "paintpalette.fill" : "paintpalette",
                label: "Capture color"
            ) {
                scanner.captureColor.toggle()
            }
            .disabled(scanner.phase != .ready)
            .opacity(scanner.phase == .ready ? 1 : 0.5)
            CircleButton(systemImage: "square.stack.3d.up.fill", label: "Saved scans") {
                showLibrary = true
            }
        }
    }

    // MARK: - Bottom bar

    @ViewBuilder
    private var bottomBar: some View {
        switch scanner.phase {
        case .ready:
            VStack(spacing: 10) {
                Text("Tap to start. Walk slowly around your subject.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.85))
                    .shadow(radius: 4)
                RecordButton(isRecording: false) { scanner.startScan() }
            }
        case .scanning:
            RecordButton(isRecording: true) { scanner.pauseScan() }
        case .paused:
            HStack(spacing: 12) {
                ActionButton(title: "Discard", systemImage: "trash", style: .secondary) {
                    confirmDiscard = true
                }
                ActionButton(title: "Resume", systemImage: "play.fill", style: .secondary) {
                    scanner.resumeScan()
                }
                ActionButton(title: "Save", systemImage: "square.and.arrow.down.fill", style: .primary) {
                    save()
                }
            }
        }
    }

    private func save() {
        scanner.save { result in
            switch result {
            case .success(let scan):
                library.reload()
                scanner.discard()
                openedScan = scan
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Components

private struct Pill: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.footnote.weight(.semibold))
            .monospacedDigit()
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
    }
}

private struct CircleButton: View {
    let systemImage: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

private struct RecordButton: View {
    let isRecording: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .strokeBorder(.white, lineWidth: 5)
                    .frame(width: 82, height: 82)
                RoundedRectangle(cornerRadius: isRecording ? 8 : 34, style: .continuous)
                    .fill(.red)
                    .frame(width: isRecording ? 32 : 66, height: isRecording ? 32 : 66)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isRecording)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isRecording ? "Stop scanning" : "Start scanning")
    }
}

private struct ActionButton: View {
    enum Style { case primary, secondary }

    let title: String
    let systemImage: String
    let style: Style
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(style == .primary ? Color.black : Color.white)
                .background {
                    if style == .primary {
                        Capsule().fill(Color.accentColor)
                    } else {
                        Capsule().fill(.ultraThinMaterial)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

private struct SavingOverlay: View {
    let stage: String
    let progress: Double

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 14) {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .frame(width: 220)
                Text(stage)
                    .font(.subheadline.weight(.medium))
                Text("Keep the app open")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}
