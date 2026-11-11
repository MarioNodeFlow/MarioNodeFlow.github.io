# LiDAR Scanner (iOS)

A native iPhone/iPad app that scans the world with the LiDAR Scanner and saves a **coloured 3D mesh** that's ready for Blender, Cinema 4D, MeshLab or AR Quick Look.

## Features

- **Live mesh overlay**: watch the LiDAR wireframe build up while you walk around.
- **Vertex colours from photos**: while scanning, the app keeps up to 120 sharp, well-spaced camera frames. When you save, each vertex is coloured from the photo that sees it best, using LiDAR depth to skip views where something is in the way.
- **Exports** (all in metres, Y-up, placed on the origin):
  - `OBJ` with vertex colours, for Blender, C4D, Maya and ZBrush
  - `PLY` (binary) with normals and colours, for MeshLab and CloudCompare
  - `USDZ`, for AR Quick Look, Reality Composer and Keynote
- **Turntable preview**: Color, Clay or Wireframe looks on a Dark, Light, **green-screen** or **blue-screen** background. Screen-record it for reels.
- **View in AR**: drop the scan back into your room with AR Quick Look.
- **Files app access**: everything is under *On My iPhone › LiDAR Scanner › Scans*, so you can AirDrop it to your Mac.

## Requirements

- An iPhone 12 Pro or later **Pro** model, or an iPad Pro (2020 or later). The app needs LiDAR.
- iOS 17 or later.
- Xcode 16 or later to build it.

## Install on your iPhone

### One command (Mac)

Plug in your iPhone, then in Terminal:

```bash
bash ios/LidarScanner/install.sh
```

The script checks Xcode, finds your iPhone and your Apple ID team, then builds, installs and opens the app. If the build fails, it copies the errors to your clipboard. Run it again to update the app or renew the 7-day free signature.

One-time setup: install Xcode, open it once, and add your Apple ID in *Xcode › Settings › Accounts*. On the iPhone, turn on *Settings › Privacy & Security › Developer Mode*. After the first install, trust the app in *Settings › General › VPN & Device Management*.

### Option A: from Xcode

1. Open `ios/LidarScanner/LidarScanner.xcodeproj` in Xcode.
2. Select the **LidarScanner** target › *Signing & Capabilities* › choose your **Team** (a free Apple ID works). If Xcode complains about the bundle ID, change `com.marionodeflow.lidarscanner` to something unique.
3. Plug in your iPhone, pick it as the run destination and press **Run**.
4. On the iPhone: *Settings › General › VPN & Device Management*, then trust your developer certificate. Also turn on *Developer Mode* if iOS asks.

With a free Apple ID the app expires after 7 days. Just press Run again to reinstall it.

### Option B: without a Mac

Each push to `ios/LidarScanner/**` runs the **iOS LiDAR Scanner** GitHub Action. It compiles the app and uploads an **unsigned `.ipa`** as a build artifact. Download it from the Actions tab and sideload it with [Sideloadly](https://sideloadly.io) or AltStore (Windows or Mac), signing in with your Apple ID.

## Scanning tips

- Move **slowly** and keep the subject 0.5–3 m away. LiDAR range is about 5 m.
- Circle around the subject and also look at it from above and below, so the colour pass has a good view of every side.
- Even, diffuse light gives the cleanest colours. Avoid strong backlight.
- Shiny, black or transparent surfaces (glass, chrome, black leather) scan poorly. That's a LiDAR limit.
- Turn off the **palette** button before you start if you only want geometry. Saving is then almost instant.

## Using the exports

**Blender:** *File › Import › Wavefront (.obj)*. To see the colours, set the viewport to *Solid › Attribute* colour, or in a material plug a *Color Attribute* node into Base Color. The mesh already sits on the floor at the origin.

The LiDAR mesh is made of chunks and is fairly dense. For a cleaner model, use *Remesh (Voxel)* followed by *Decimate*. You can also run *Filters › Remeshing* in MeshLab.

## Project layout

```
LidarScanner/
├── App/              App entry point, unsupported-device screen
├── Scanning/         AR session, keyframe capture, scanner UI
├── Mesh/             Mesh merge, colouring, OBJ/PLY/USDZ export, SceneKit helpers
└── Library/          Saved scans list, detail/preview screen
```
