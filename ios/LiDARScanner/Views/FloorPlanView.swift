import SwiftUI

struct FloorPlanView: View {
    @EnvironmentObject var projectManager: ProjectManager
    @State var project: FloorPlanProject

    @State private var selectedRoom: Room?
    @State private var showingRoomEditor = false
    @State private var showingAddRoom = false
    @State private var showingExportSheet = false
    @State private var showingScanner = false
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero

    // Scale: pixels per foot
    private let pixelsPerFoot: CGFloat = 15

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)

                // Floor plan canvas
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    floorPlanCanvas
                        .scaleEffect(scale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = min(max(value, 0.5), 3.0)
                                }
                        )
                }

                // Floating action buttons
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        floatingButtons
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: { showingScanner = true }) {
                        Label("Scan Room", systemImage: "camera.viewfinder")
                    }
                    Button(action: { showingAddRoom = true }) {
                        Label("Add Room Manually", systemImage: "plus.rectangle")
                    }
                    Divider()
                    Button(action: { showingExportSheet = true }) {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingRoomEditor) {
            if let room = selectedRoom {
                RoomEditView(room: room, project: $project) { updatedRoom in
                    updateRoom(updatedRoom)
                } onDelete: {
                    deleteRoom(room)
                }
            }
        }
        .sheet(isPresented: $showingAddRoom) {
            AddRoomSheet(project: $project)
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportSheet(project: project)
        }
        .fullScreenCover(isPresented: $showingScanner) {
            RoomScanView(project: project, isPresented: $showingScanner)
        }
        .onChange(of: projectManager.currentProject) { _, newProject in
            if let updated = newProject, updated.id == project.id {
                project = updated
            }
        }
    }

    // MARK: - Floor Plan Canvas
    private var floorPlanCanvas: some View {
        let canvasWidth = calculateCanvasWidth()
        let canvasHeight = calculateCanvasHeight()

        return ZStack(alignment: .topLeading) {
            // Grid background
            GridPattern(width: canvasWidth, height: canvasHeight, spacing: pixelsPerFoot)
                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)

            // Rooms
            ForEach(project.rooms) { room in
                RoomShape(room: room, pixelsPerFoot: pixelsPerFoot, isSelected: selectedRoom?.id == room.id)
                    .position(
                        x: CGFloat(room.x) * pixelsPerFoot + CGFloat(room.width) * pixelsPerFoot / 2 + 60,
                        y: CGFloat(room.z) * pixelsPerFoot + CGFloat(room.length) * pixelsPerFoot / 2 + 60
                    )
                    .onTapGesture {
                        selectedRoom = room
                        showingRoomEditor = true
                    }
            }

            // Scale indicator
            VStack(alignment: .leading) {
                Text("1 grid = 1 ft")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("Total: \(Int(project.totalArea)) sq ft")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(8)
            .background(Color(.systemBackground).opacity(0.9))
            .cornerRadius(6)
            .padding(10)
        }
        .frame(width: canvasWidth, height: canvasHeight)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 5)
        .padding()
    }

    // MARK: - Floating Buttons
    private var floatingButtons: some View {
        VStack(spacing: 12) {
            Button(action: { scale = min(scale * 1.2, 3.0) }) {
                Image(systemName: "plus.magnifyingglass")
                    .font(.title2)
                    .frame(width: 50, height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(25)
                    .shadow(radius: 3)
            }

            Button(action: { scale = max(scale / 1.2, 0.5) }) {
                Image(systemName: "minus.magnifyingglass")
                    .font(.title2)
                    .frame(width: 50, height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(25)
                    .shadow(radius: 3)
            }

            Button(action: { scale = 1.0 }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .frame(width: 50, height: 50)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(25)
                    .shadow(radius: 3)
            }
        }
    }

    // MARK: - Helpers
    private func calculateCanvasWidth() -> CGFloat {
        let maxX = project.rooms.map { CGFloat($0.x + $0.width) }.max() ?? 50
        return max(maxX * pixelsPerFoot + 150, 500)
    }

    private func calculateCanvasHeight() -> CGFloat {
        let maxZ = project.rooms.map { CGFloat($0.z + $0.length) }.max() ?? 40
        return max(maxZ * pixelsPerFoot + 150, 400)
    }

    private func updateRoom(_ room: Room) {
        project.updateRoom(room)
        projectManager.updateProject(project)
        selectedRoom = nil
    }

    private func deleteRoom(_ room: Room) {
        project.deleteRoom(room.id)
        projectManager.updateProject(project)
        selectedRoom = nil
        showingRoomEditor = false
    }
}

// MARK: - Room Shape
struct RoomShape: View {
    let room: Room
    let pixelsPerFoot: CGFloat
    let isSelected: Bool

    var body: some View {
        let width = CGFloat(room.width) * pixelsPerFoot
        let height = CGFloat(room.length) * pixelsPerFoot

        ZStack {
            // Room fill
            Rectangle()
                .fill(room.uiColor)
                .frame(width: width, height: height)

            // Room border
            Rectangle()
                .stroke(isSelected ? Color.blue : Color.black, lineWidth: isSelected ? 3 : 2)
                .frame(width: width, height: height)

            // Room info
            VStack(spacing: 4) {
                Text(room.name)
                    .font(.system(size: 14, weight: .bold))
                Text("\(Int(room.width))' x \(Int(room.length))'")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text("\(Int(room.area)) sq ft")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Grid Pattern
struct GridPattern: Shape {
    let width: CGFloat
    let height: CGFloat
    let spacing: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Vertical lines
        var x: CGFloat = 60
        while x <= width {
            path.move(to: CGPoint(x: x, y: 60))
            path.addLine(to: CGPoint(x: x, y: height - 60))
            x += spacing
        }

        // Horizontal lines
        var y: CGFloat = 60
        while y <= height {
            path.move(to: CGPoint(x: 60, y: y))
            path.addLine(to: CGPoint(x: width - 60, y: y))
            y += spacing
        }

        return path
    }
}

// MARK: - Add Room Sheet
struct AddRoomSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var projectManager: ProjectManager
    @Binding var project: FloorPlanProject

    @State private var roomName = ""
    @State private var width: Double = 12
    @State private var length: Double = 12
    @State private var height: Double = 9

    var body: some View {
        NavigationStack {
            Form {
                Section("Room Details") {
                    TextField("Room Name", text: $roomName)

                    HStack {
                        Text("Width")
                        Spacer()
                        TextField("", value: $width, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("ft")
                    }

                    HStack {
                        Text("Length")
                        Spacer()
                        TextField("", value: $length, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("ft")
                    }

                    HStack {
                        Text("Ceiling Height")
                        Spacer()
                        TextField("", value: $height, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("ft")
                    }
                }

                Section {
                    HStack {
                        Text("Area")
                        Spacer()
                        Text("\(Int(width * length)) sq ft")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Add Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addRoom()
                        dismiss()
                    }
                    .disabled(roomName.isEmpty)
                }
            }
            .onAppear {
                roomName = "Room \(project.rooms.count + 1)"
            }
        }
    }

    private func addRoom() {
        // Calculate position (place after existing rooms)
        let existingMaxX = project.rooms.map { $0.x + $0.width }.max() ?? 0

        let room = Room(
            name: roomName,
            x: existingMaxX > 0 ? existingMaxX + 2 : 0,
            z: 0,
            width: width,
            length: length,
            height: height,
            color: RoomColors.color(for: project.rooms.count)
        )

        project.addRoom(room)
        projectManager.updateProject(project)
    }
}

#Preview {
    NavigationStack {
        FloorPlanView(project: FloorPlanProject(name: "Sample House"))
    }
    .environmentObject(ProjectManager())
}
