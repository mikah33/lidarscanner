import Foundation
import RoomPlan

// MARK: - Room Capture Service
// Handles conversion between RoomPlan data and our models

class RoomCaptureService {

    // Convert RoomPlan CapturedRoom to our Room model
    static func convertToRoom(from capturedRoom: CapturedRoom, name: String, index: Int) -> Room {
        let metersToFeet = 3.28084

        // Get bounding box from walls
        var minX: Float = .infinity
        var maxX: Float = -.infinity
        var minZ: Float = .infinity
        var maxZ: Float = -.infinity
        var maxHeight: Float = 0

        for wall in capturedRoom.walls {
            let transform = wall.transform
            let position = SIMD3<Float>(
                transform.columns.3.x,
                transform.columns.3.y,
                transform.columns.3.z
            )
            let dimensions = wall.dimensions

            minX = min(minX, position.x - dimensions.x / 2)
            maxX = max(maxX, position.x + dimensions.x / 2)
            minZ = min(minZ, position.z - dimensions.z / 2)
            maxZ = max(maxZ, position.z + dimensions.z / 2)
            maxHeight = max(maxHeight, dimensions.y)
        }

        // Handle case where no walls detected
        if minX == .infinity {
            return Room(
                name: name,
                x: 0,
                z: 0,
                width: 12,
                length: 12,
                height: 9,
                color: RoomColors.color(for: index)
            )
        }

        let width = Double(maxX - minX) * metersToFeet
        let length = Double(maxZ - minZ) * metersToFeet
        let height = Double(maxHeight) * metersToFeet

        return Room(
            name: name,
            x: 0,
            z: 0,
            width: max(4, round(width * 2) / 2),     // Round to nearest 0.5 ft, min 4 ft
            length: max(4, round(length * 2) / 2),
            height: max(8, min(round(height * 2) / 2, 20)),  // Clamp 8-20 ft
            color: RoomColors.color(for: index)
        )
    }

    // Extract doors from CapturedRoom
    static func extractDoors(from capturedRoom: CapturedRoom) -> [Door] {
        let metersToFeet = 3.28084
        var doors: [Door] = []

        for door in capturedRoom.doors {
            let transform = door.transform
            let position = SIMD3<Float>(
                transform.columns.3.x,
                transform.columns.3.y,
                transform.columns.3.z
            )
            let dimensions = door.dimensions

            doors.append(Door(
                x: Double(position.x) * metersToFeet,
                z: Double(position.z) * metersToFeet,
                width: Double(dimensions.x) * metersToFeet,
                isExterior: false
            ))
        }

        return doors
    }

    // Extract windows from CapturedRoom
    static func extractWindows(from capturedRoom: CapturedRoom) -> [Window] {
        let metersToFeet = 3.28084
        var windows: [Window] = []

        for window in capturedRoom.windows {
            let transform = window.transform
            let position = SIMD3<Float>(
                transform.columns.3.x,
                transform.columns.3.y,
                transform.columns.3.z
            )
            let dimensions = window.dimensions

            windows.append(Window(
                x: Double(position.x) * metersToFeet,
                z: Double(position.z) * metersToFeet,
                width: Double(dimensions.x) * metersToFeet,
                height: Double(dimensions.y) * metersToFeet,
                fromFloor: Double(position.y - dimensions.y / 2) * metersToFeet
            ))
        }

        return windows
    }

    // Check if device supports RoomPlan
    static var isSupported: Bool {
        RoomCaptureSession.isSupported
    }
}

// MARK: - Scan Result
struct ScanResult {
    let room: Room
    let doors: [Door]
    let windows: [Window]
    let capturedRoom: CapturedRoom

    init(from capturedRoom: CapturedRoom, name: String, index: Int) {
        self.capturedRoom = capturedRoom
        self.room = RoomCaptureService.convertToRoom(from: capturedRoom, name: name, index: index)
        self.doors = RoomCaptureService.extractDoors(from: capturedRoom)
        self.windows = RoomCaptureService.extractWindows(from: capturedRoom)
    }
}
