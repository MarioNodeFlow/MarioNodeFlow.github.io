import SwiftUI

@main
struct LidarScannerApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    var body: some View {
        if ScanSession.isSupported {
            ScannerView()
        } else {
            UnsupportedDeviceView()
        }
    }
}

struct UnsupportedDeviceView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sensor.tag.radiowaves.forward")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("LiDAR Scanner required")
                .font(.title2.bold())
            Text("This app builds 3D meshes with the LiDAR Scanner. Use an iPhone 12 Pro or later Pro model, or an iPad Pro from 2020 or later.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(32)
    }
}
