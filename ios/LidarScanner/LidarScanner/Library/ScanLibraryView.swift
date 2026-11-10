import SwiftUI

struct ScanLibraryView: View {
    @ObservedObject var library: ScanLibrary
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if library.scans.isEmpty {
                ContentUnavailableView(
                    "No scans yet",
                    systemImage: "cube.transparent",
                    description: Text("Saved scans show up here, and in the Files app under On My iPhone › LiDAR Scanner.")
                )
            } else {
                List {
                    ForEach(library.scans) { scan in
                        NavigationLink(value: scan) {
                            ScanRow(scan: scan)
                        }
                    }
                    .onDelete { offsets in
                        offsets.map { library.scans[$0] }.forEach(library.delete)
                    }
                }
            }
        }
        .navigationTitle("Scans")
        .navigationDestination(for: SavedScan.self) { scan in
            ScanDetailView(scan: scan, library: library, showsDoneButton: false)
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .onAppear { library.reload() }
    }
}

private struct ScanRow: View {
    let scan: SavedScan

    var body: some View {
        HStack(spacing: 14) {
            ScanThumbnail(url: scan.thumbnailURL)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(scan.name)
                    .font(.headline)
                Text("\(scan.triangleCount.formatted(.number.notation(.compactName))) triangles"
                     + (scan.hasColor ? " · color" : ""))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ScanThumbnail: View {
    let url: URL

    var body: some View {
        if let image = UIImage(contentsOfFile: url.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Color.gray.opacity(0.2)
                Image(systemName: "cube.transparent")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
