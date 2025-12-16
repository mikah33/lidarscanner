# LiDAR Scanner

iOS app for creating floor plans using LiDAR scanning and manual CAD input.

## Features

- **LiDAR Room Scanning** - Use Apple's RoomPlan framework to scan rooms with LiDAR (iPhone 12 Pro+ / iPad Pro 2020+)
- **Manual CAD Input** - Enter room dimensions manually without LiDAR
- **2D Floor Plan View** - Interactive 2D floor plan with zoom/pan
- **3D Floor Plan View** - SceneKit-based 3D visualization with camera controls
- **Room Editing** - Edit dimensions, position, and colors
- **Export Options** - Export to JSON, PDF, PNG, or DXF (AutoCAD)

## Requirements

- iOS 16.0+
- Xcode 15+
- Device with LiDAR (for scanning) or any iOS device (for manual input)

## Getting Started

1. Open `ios/LiDARScanner.xcodeproj` in Xcode
2. Select your target device
3. Build and run (Cmd+R)

## Usage

1. **Create a Project** - Tap "New Project" and enter a name
2. **Add Rooms**:
   - "Create & Start Scanning" to use LiDAR
   - "Create Empty Project" then add rooms manually via the menu
3. **View Floor Plan** - Toggle between 2D and 3D views with the cube icon
4. **Edit Rooms** - Tap any room to edit dimensions
5. **Export** - Use the menu to export in various formats

## Project Structure

```
ios/LiDARScanner/
├── LiDARScannerApp.swift    # App entry point & ProjectManager
├── ContentView.swift         # Main navigation & project list
├── Models/
│   └── FloorPlanModels.swift # Data models (Room, Door, Window, Project)
├── Views/
│   ├── FloorPlanView.swift   # 2D floor plan canvas
│   ├── FloorPlan3DView.swift # 3D SceneKit viewer
│   ├── RoomScanView.swift    # LiDAR scanning UI
│   ├── RoomEditView.swift    # Room editing form
│   └── ProjectListView.swift # Project list component
└── Services/
    └── ExportManager.swift   # Export to JSON/PDF/PNG/DXF
```

## License

MIT
