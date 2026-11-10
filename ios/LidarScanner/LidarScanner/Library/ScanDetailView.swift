import QuickLook
import SwiftUI

enum Backdrop: String, CaseIterable, Identifiable {
    case dark = "Dark"
    case light = "Light"
    case greenScreen = "Green screen"
    case blueScreen = "Blue screen"

    var id: String { rawValue }

    var color: UIColor {
        switch self {
        case .dark: return UIColor(white: 0.07, alpha: 1)
        case .light: return UIColor(white: 0.96, alpha: 1)
        case .greenScreen: return UIColor(red: 0, green: 0.694, blue: 0.251, alpha: 1)  // #00B140
        case .blueScreen: return UIColor(red: 0, green: 0.278, blue: 0.733, alpha: 1)   // #0047BB
        }
    }
}

struct ScanDetailView: View {
    let scan: SavedScan
    @ObservedObject var library: ScanLibrary
    let showsDoneButton: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var mesh: ScanMesh?
    @State private var loadError: String?
    @State private var style: PreviewStyle = .color
    @State private var backdrop: Backdrop = .dark
    @State private var turntable = true
    @State private var quickLookURL: URL?
    @State private var confirmDelete = false

    var body: some View {
        VStack(spacing: 0) {
            preview
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            controls
                .padding(16)
                .background(.bar)
        }
        .navigationTitle(scan.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsDoneButton {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .confirmationDialog("Delete this scan?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                library.delete(scan)
                dismiss()
            }
        }
        .quickLookPreview($quickLookURL)
        .task { await loadMesh() }
    }

    @ViewBuilder
    private var preview: some View {
        if let mesh {
            ModelPreview(mesh: mesh, style: style, backdrop: backdrop.color, turntable: turntable)
                .ignoresSafeArea(edges: .bottom)
        } else if let loadError {
            ContentUnavailableView("Couldn't open scan", systemImage: "exclamationmark.triangle", description: Text(loadError))
        } else {
            ProgressView("Loading mesh…")
        }
    }

    private var controls: some View {
        VStack(spacing: 14) {
            Picker("Style", selection: $style) {
                ForEach(PreviewStyle.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            HStack {
                Picker("Background", selection: $backdrop) {
                    ForEach(Backdrop.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.menu)
                Spacer()
                Toggle("Turntable", isOn: $turntable)
                    .fixedSize()
            }

            Text("\(scan.vertexCount.formatted()) vertices · \(scan.triangleCount.formatted()) triangles · metres, Y up")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                ExportButton(title: "OBJ", subtitle: "Blender, C4D", url: scan.objURL)
                ExportButton(title: "PLY", subtitle: "MeshLab, CC", url: scan.plyURL)
                ExportButton(title: "USDZ", subtitle: "Apple, AR", url: scan.usdzURL)
            }

            if scan.fileExists(scan.usdzURL) {
                Button {
                    quickLookURL = scan.usdzURL
                } label: {
                    Label("View in AR", systemImage: "arkit")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func loadMesh() async {
        let url = scan.plyURL
        let result = await Task.detached(priority: .userInitiated) {
            Result { try MeshFileIO.readPLY(from: url) }
        }.value
        switch result {
        case .success(let loaded): mesh = loaded
        case .failure(let error): loadError = error.localizedDescription
        }
    }
}

private struct ExportButton: View {
    let title: String
    let subtitle: String
    let url: URL

    var body: some View {
        let available = FileManager.default.fileExists(atPath: url.path)
        ShareLink(item: url) {
            VStack(spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .disabled(!available)
        .opacity(available ? 1 : 0.4)
    }
}
