import SwiftUI
import PDFKit

// MARK: - Export Manager
class ExportManager {

    // MARK: - JSON Export
    static func exportJSON(project: FloorPlanProject) -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        do {
            return try encoder.encode(project)
        } catch {
            print("JSON export error: \(error)")
            return nil
        }
    }

    // MARK: - PDF Export
    static func exportPDF(project: FloorPlanProject) -> Data? {
        let pageWidth: CGFloat = 792  // 11 inches at 72 DPI (landscape letter)
        let pageHeight: CGFloat = 612 // 8.5 inches
        let margin: CGFloat = 36      // 0.5 inch margins

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        return renderer.pdfData { context in
            context.beginPage()

            let ctx = context.cgContext

            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            let title = project.name
            title.draw(at: CGPoint(x: pageWidth / 2 - 100, y: margin), withAttributes: titleAttributes)

            // Date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateText = "Generated: \(dateFormatter.string(from: Date()))"
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.gray
            ]
            dateText.draw(at: CGPoint(x: pageWidth / 2 - 50, y: margin + 30), withAttributes: dateAttributes)

            // Calculate scale
            let maxX = project.rooms.map { $0.x + $0.width }.max() ?? 50
            let maxZ = project.rooms.map { $0.z + $0.length }.max() ?? 40
            let drawingWidth = pageWidth - margin * 2
            let drawingHeight = pageHeight - margin * 2 - 100
            let scale = min(drawingWidth / CGFloat(maxX), drawingHeight / CGFloat(maxZ)) * 0.85

            let offsetX = margin + 20
            let offsetY = margin + 80

            // Draw rooms
            for room in project.rooms {
                let x = offsetX + CGFloat(room.x) * scale
                let y = offsetY + CGFloat(room.z) * scale
                let width = CGFloat(room.width) * scale
                let height = CGFloat(room.length) * scale

                // Room rectangle
                ctx.setStrokeColor(UIColor.black.cgColor)
                ctx.setLineWidth(1.5)
                ctx.stroke(CGRect(x: x, y: y, width: width, height: height))

                // Room name
                let nameAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 10),
                    .foregroundColor: UIColor.black
                ]
                let name = room.name
                let nameSize = name.size(withAttributes: nameAttributes)
                name.draw(at: CGPoint(x: x + width/2 - nameSize.width/2, y: y + height/2 - 20), withAttributes: nameAttributes)

                // Dimensions
                let dimAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 8),
                    .foregroundColor: UIColor.darkGray
                ]
                let dimensions = "\(Int(room.width))' × \(Int(room.length))'"
                let dimSize = dimensions.size(withAttributes: dimAttributes)
                dimensions.draw(at: CGPoint(x: x + width/2 - dimSize.width/2, y: y + height/2 - 5), withAttributes: dimAttributes)

                // Area
                let area = "\(Int(room.area)) sq ft"
                let areaSize = area.size(withAttributes: dimAttributes)
                area.draw(at: CGPoint(x: x + width/2 - areaSize.width/2, y: y + height/2 + 8), withAttributes: dimAttributes)
            }

            // Total area footer
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ]
            let footer = "Total Area: \(Int(project.totalArea)) sq ft"
            footer.draw(at: CGPoint(x: margin, y: pageHeight - margin - 20), withAttributes: footerAttributes)

            // Scale note
            let scaleNote = "Scale: 1\" = \(String(format: "%.1f", 1/scale * 72))"
            scaleNote.draw(at: CGPoint(x: pageWidth - margin - 100, y: pageHeight - margin - 20), withAttributes: dateAttributes)
        }
    }

    // MARK: - PNG Export
    static func exportPNG(project: FloorPlanProject, scale: CGFloat = 2.0) -> Data? {
        let pixelsPerFoot: CGFloat = 15 * scale
        let padding: CGFloat = 60 * scale

        let maxX = project.rooms.map { $0.x + $0.width }.max() ?? 50
        let maxZ = project.rooms.map { $0.z + $0.length }.max() ?? 40
        let width = CGFloat(maxX) * pixelsPerFoot + padding * 2
        let height = CGFloat(maxZ) * pixelsPerFoot + padding * 2

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))

        let image = renderer.image { context in
            let ctx = context.cgContext

            // White background
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

            // Draw grid
            ctx.setStrokeColor(UIColor.lightGray.withAlphaComponent(0.5).cgColor)
            ctx.setLineWidth(0.5)

            var x = padding
            while x <= width - padding {
                ctx.move(to: CGPoint(x: x, y: padding))
                ctx.addLine(to: CGPoint(x: x, y: height - padding))
                x += pixelsPerFoot
            }

            var y = padding
            while y <= height - padding {
                ctx.move(to: CGPoint(x: padding, y: y))
                ctx.addLine(to: CGPoint(x: width - padding, y: y))
                y += pixelsPerFoot
            }
            ctx.strokePath()

            // Draw rooms
            for room in project.rooms {
                let roomX = padding + CGFloat(room.x) * pixelsPerFoot
                let roomY = padding + CGFloat(room.z) * pixelsPerFoot
                let roomWidth = CGFloat(room.width) * pixelsPerFoot
                let roomHeight = CGFloat(room.length) * pixelsPerFoot

                // Fill
                if let color = UIColor(hex: room.color) {
                    ctx.setFillColor(color.cgColor)
                    ctx.fill(CGRect(x: roomX, y: roomY, width: roomWidth, height: roomHeight))
                }

                // Border
                ctx.setStrokeColor(UIColor.black.cgColor)
                ctx.setLineWidth(2 * scale)
                ctx.stroke(CGRect(x: roomX, y: roomY, width: roomWidth, height: roomHeight))

                // Labels
                let fontSize = 14 * scale
                let nameAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: fontSize),
                    .foregroundColor: UIColor.black
                ]
                let name = room.name as NSString
                let nameSize = name.size(withAttributes: nameAttributes)
                name.draw(
                    at: CGPoint(x: roomX + roomWidth/2 - nameSize.width/2, y: roomY + roomHeight/2 - fontSize * 2),
                    withAttributes: nameAttributes
                )

                let dimAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: fontSize * 0.8),
                    .foregroundColor: UIColor.darkGray
                ]
                let dimensions = "\(Int(room.width))' × \(Int(room.length))'" as NSString
                let dimSize = dimensions.size(withAttributes: dimAttributes)
                dimensions.draw(
                    at: CGPoint(x: roomX + roomWidth/2 - dimSize.width/2, y: roomY + roomHeight/2),
                    withAttributes: dimAttributes
                )

                let area = "\(Int(room.area)) sq ft" as NSString
                let areaSize = area.size(withAttributes: dimAttributes)
                area.draw(
                    at: CGPoint(x: roomX + roomWidth/2 - areaSize.width/2, y: roomY + roomHeight/2 + fontSize),
                    withAttributes: dimAttributes
                )
            }
        }

        return image.pngData()
    }

    // MARK: - DXF Export
    static func exportDXF(project: FloorPlanProject) -> Data? {
        var dxf = ""

        // Header
        dxf += "0\nSECTION\n2\nHEADER\n"
        dxf += "9\n$ACADVER\n1\nAC1015\n"
        dxf += "9\n$INSUNITS\n70\n2\n"  // Units = feet
        dxf += "0\nENDSEC\n"

        // Tables (layers)
        dxf += "0\nSECTION\n2\nTABLES\n"
        dxf += "0\nTABLE\n2\nLAYER\n"

        let layers = ["WALLS", "TEXT", "DIMENSIONS"]
        for (index, layer) in layers.enumerated() {
            dxf += "0\nLAYER\n"
            dxf += "2\n\(layer)\n"
            dxf += "70\n0\n"
            dxf += "62\n\(index + 1)\n"
            dxf += "6\nCONTINUOUS\n"
        }

        dxf += "0\nENDTAB\n"
        dxf += "0\nENDSEC\n"

        // Entities
        dxf += "0\nSECTION\n2\nENTITIES\n"

        // Draw room outlines
        for room in project.rooms {
            let x1 = room.x
            let y1 = room.z
            let x2 = room.x + room.width
            let y2 = room.z + room.length

            // Four lines for room boundary
            dxf += "0\nLINE\n8\nWALLS\n"
            dxf += "10\n\(x1)\n20\n\(y1)\n30\n0\n"
            dxf += "11\n\(x2)\n21\n\(y1)\n31\n0\n"

            dxf += "0\nLINE\n8\nWALLS\n"
            dxf += "10\n\(x2)\n20\n\(y1)\n30\n0\n"
            dxf += "11\n\(x2)\n21\n\(y2)\n31\n0\n"

            dxf += "0\nLINE\n8\nWALLS\n"
            dxf += "10\n\(x2)\n20\n\(y2)\n30\n0\n"
            dxf += "11\n\(x1)\n21\n\(y2)\n31\n0\n"

            dxf += "0\nLINE\n8\nWALLS\n"
            dxf += "10\n\(x1)\n20\n\(y2)\n30\n0\n"
            dxf += "11\n\(x1)\n21\n\(y1)\n31\n0\n"

            // Room name
            let centerX = room.x + room.width / 2
            let centerY = room.z + room.length / 2
            dxf += "0\nTEXT\n8\nTEXT\n"
            dxf += "10\n\(centerX)\n20\n\(centerY)\n30\n0\n"
            dxf += "40\n1\n"
            dxf += "1\n\(room.name)\n"
            dxf += "72\n1\n73\n2\n"
            dxf += "11\n\(centerX)\n21\n\(centerY)\n31\n0\n"
        }

        dxf += "0\nENDSEC\n"
        dxf += "0\nEOF\n"

        return dxf.data(using: .utf8)
    }
}

// MARK: - UIColor Extension
extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

// MARK: - Export Sheet View
struct ExportSheet: View {
    @Environment(\.dismiss) var dismiss
    let project: FloorPlanProject

    @State private var selectedFormat: ExportFormat = .pdf
    @State private var isExporting = false
    @State private var exportedFileURL: URL?
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Export Format") {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Button(action: { selectedFormat = format }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(format.rawValue)
                                        .font(.headline)
                                    Text(formatDescription(format))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedFormat == format {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }

                Section {
                    Button(action: exportFile) {
                        HStack {
                            Spacer()
                            if isExporting {
                                ProgressView()
                            } else {
                                Label("Export \(selectedFormat.rawValue)", systemImage: "square.and.arrow.up")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isExporting)
                }
            }
            .navigationTitle("Export Floor Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private func formatDescription(_ format: ExportFormat) -> String {
        switch format {
        case .json: return "Raw data for backup or web editor"
        case .pdf: return "Printable document with dimensions"
        case .png: return "Image file for sharing"
        case .dxf: return "AutoCAD compatible format"
        }
    }

    private func exportFile() {
        isExporting = true

        DispatchQueue.global(qos: .userInitiated).async {
            var data: Data?

            switch selectedFormat {
            case .json:
                data = ExportManager.exportJSON(project: project)
            case .pdf:
                data = ExportManager.exportPDF(project: project)
            case .png:
                data = ExportManager.exportPNG(project: project)
            case .dxf:
                data = ExportManager.exportDXF(project: project)
            }

            DispatchQueue.main.async {
                isExporting = false

                if let data = data {
                    let filename = "\(project.name.replacingOccurrences(of: " ", with: "-")).\(selectedFormat.fileExtension)"
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

                    do {
                        try data.write(to: tempURL)
                        exportedFileURL = tempURL
                        showShareSheet = true
                    } catch {
                        print("Export error: \(error)")
                    }
                }
            }
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
