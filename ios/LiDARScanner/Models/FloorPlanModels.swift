import Foundation
import SwiftUI

// MARK: - Floor Plan Project
struct FloorPlanProject: Identifiable, Codable, Equatable {
    static func == (lhs: FloorPlanProject, rhs: FloorPlanProject) -> Bool {
        lhs.id == rhs.id && lhs.dateModified == rhs.dateModified
    }

    let id: UUID
    var name: String
    var dateCreated: Date
    var dateModified: Date
    var rooms: [Room]
    var doors: [Door]
    var windows: [Window]

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
        self.dateCreated = Date()
        self.dateModified = Date()
        self.rooms = []
        self.doors = []
        self.windows = []
    }

    var totalArea: Double {
        rooms.reduce(0) { $0 + $1.area }
    }

    mutating func addRoom(_ room: Room) {
        rooms.append(room)
        dateModified = Date()
    }

    mutating func updateRoom(_ room: Room) {
        if let index = rooms.firstIndex(where: { $0.id == room.id }) {
            rooms[index] = room
            dateModified = Date()
        }
    }

    mutating func deleteRoom(_ roomId: UUID) {
        rooms.removeAll { $0.id == roomId }
        dateModified = Date()
    }
}

// MARK: - Room
struct Room: Identifiable, Codable {
    let id: UUID
    var name: String
    var x: Double      // X position in feet
    var z: Double      // Z position in feet (Y in 2D view)
    var width: Double  // Width in feet
    var length: Double // Length in feet
    var height: Double // Ceiling height in feet
    var color: String  // Hex color

    init(
        id: UUID = UUID(),
        name: String,
        x: Double = 0,
        z: Double = 0,
        width: Double = 12,
        length: Double = 12,
        height: Double = 9,
        color: String = "#e8f4f8"
    ) {
        self.id = id
        self.name = name
        self.x = x
        self.z = z
        self.width = width
        self.length = length
        self.height = height
        self.color = color
    }

    var area: Double {
        width * length
    }

    var volume: Double {
        width * length * height
    }

    var uiColor: Color {
        Color(hex: color) ?? .blue.opacity(0.2)
    }
}

// MARK: - Door
struct Door: Identifiable, Codable {
    let id: UUID
    var x: Double
    var z: Double
    var width: Double
    var isExterior: Bool
    var label: String?
    var connectsRooms: [UUID] // IDs of connected rooms

    init(
        id: UUID = UUID(),
        x: Double,
        z: Double,
        width: Double = 3,
        isExterior: Bool = false,
        label: String? = nil,
        connectsRooms: [UUID] = []
    ) {
        self.id = id
        self.x = x
        self.z = z
        self.width = width
        self.isExterior = isExterior
        self.label = label
        self.connectsRooms = connectsRooms
    }
}

// MARK: - Window
struct Window: Identifiable, Codable {
    let id: UUID
    var x: Double
    var z: Double
    var width: Double
    var height: Double
    var fromFloor: Double
    var roomId: UUID?

    init(
        id: UUID = UUID(),
        x: Double,
        z: Double,
        width: Double = 4,
        height: Double = 5,
        fromFloor: Double = 3,
        roomId: UUID? = nil
    ) {
        self.id = id
        self.x = x
        self.z = z
        self.width = width
        self.height = height
        self.fromFloor = fromFloor
        self.roomId = roomId
    }
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else { return "#000000" }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - Room Colors
struct RoomColors {
    static let palette: [String] = [
        "#e8f4f8", "#f8f4e8", "#f4f8e8", "#e8e8f8", "#f8e8f4",
        "#f8e8e8", "#e8f8e8", "#e8f8f4", "#f4e8f8", "#f8f8e8"
    ]

    static func color(for index: Int) -> String {
        palette[index % palette.count]
    }
}

// MARK: - Export Format
enum ExportFormat: String, CaseIterable {
    case json = "JSON"
    case pdf = "PDF"
    case png = "PNG"
    case dxf = "DXF"

    var fileExtension: String {
        rawValue.lowercased()
    }

    var mimeType: String {
        switch self {
        case .json: return "application/json"
        case .pdf: return "application/pdf"
        case .png: return "image/png"
        case .dxf: return "application/dxf"
        }
    }
}
