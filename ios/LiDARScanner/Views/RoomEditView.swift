import SwiftUI

struct RoomEditView: View {
    @Environment(\.dismiss) var dismiss
    @State var room: Room
    @Binding var project: FloorPlanProject

    let onSave: (Room) -> Void
    let onDelete: () -> Void

    @State private var showingDeleteAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Room Details") {
                    TextField("Room Name", text: $room.name)
                }

                Section("Dimensions") {
                    dimensionRow(label: "Width", value: $room.width, unit: "ft")
                    dimensionRow(label: "Length", value: $room.length, unit: "ft")
                    dimensionRow(label: "Ceiling Height", value: $room.height, unit: "ft")
                }

                Section("Position") {
                    dimensionRow(label: "X Position", value: $room.x, unit: "ft")
                    dimensionRow(label: "Y Position", value: $room.z, unit: "ft")
                }

                Section {
                    HStack {
                        Text("Area")
                        Spacer()
                        Text("\(Int(room.area)) sq ft")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Volume")
                        Spacer()
                        Text("\(Int(room.volume)) cu ft")
                            .foregroundColor(.secondary)
                    }
                }

                Section("Color") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(RoomColors.palette, id: \.self) { colorHex in
                                Circle()
                                    .fill(Color(hex: colorHex) ?? .gray)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(room.color == colorHex ? Color.blue : Color.clear, lineWidth: 3)
                                    )
                                    .onTapGesture {
                                        room.color = colorHex
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Delete Room", systemImage: "trash")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(room)
                        dismiss()
                    }
                }
            }
            .alert("Delete Room?", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    onDelete()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently remove \"\(room.name)\" from the floor plan.")
            }
        }
    }

    private func dimensionRow(label: String, value: Binding<Double>, unit: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("", value: value, format: .number.precision(.fractionLength(1)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 70)
            Text(unit)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Project List View (for reference)
struct ProjectListView: View {
    @EnvironmentObject var projectManager: ProjectManager

    var body: some View {
        List {
            ForEach(projectManager.projects) { project in
                NavigationLink(destination: FloorPlanView(project: project)) {
                    VStack(alignment: .leading) {
                        Text(project.name)
                            .font(.headline)
                        Text("\(project.rooms.count) rooms • \(Int(project.totalArea)) sq ft")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    projectManager.deleteProject(projectManager.projects[index])
                }
            }
        }
        .navigationTitle("Projects")
    }
}

#Preview {
    RoomEditView(
        room: Room(name: "Living Room", width: 18, length: 24, height: 9),
        project: .constant(FloorPlanProject(name: "Test")),
        onSave: { _ in },
        onDelete: {}
    )
}
