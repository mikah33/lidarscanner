import SwiftUI
import RoomPlan

struct ContentView: View {
    @EnvironmentObject var projectManager: ProjectManager
    @State private var showingNewProjectSheet = false
    @State private var showingScanner = false
    @State private var selectedProject: FloorPlanProject?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if projectManager.projects.isEmpty {
                    emptyStateView
                } else {
                    projectListView
                }
            }
            .navigationTitle("LiDAR Scanner")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewProjectSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewProjectSheet) {
                NewProjectSheet(isPresented: $showingNewProjectSheet)
            }
            .fullScreenCover(isPresented: $showingScanner) {
                if let project = selectedProject {
                    RoomScanView(project: project, isPresented: $showingScanner)
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "house.and.flag")
                .font(.system(size: 80))
                .foregroundColor(.blue.opacity(0.6))

            Text("No Floor Plans Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Create a new project to start scanning rooms with LiDAR")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: { showingNewProjectSheet = true }) {
                Label("New Project", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private var projectListView: some View {
        List {
            ForEach(projectManager.projects) { project in
                NavigationLink(destination: FloorPlanView(project: project)) {
                    ProjectRowView(project: project)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        projectManager.deleteProject(project)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    Button {
                        selectedProject = project
                        showingScanner = true
                    } label: {
                        Label("Scan", systemImage: "camera.viewfinder")
                    }
                    .tint(.blue)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Project Row View
struct ProjectRowView: View {
    let project: FloorPlanProject

    var body: some View {
        HStack(spacing: 15) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "square.split.2x2")
                        .font(.title2)
                        .foregroundColor(.blue)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.headline)

                HStack(spacing: 12) {
                    Label("\(project.rooms.count) rooms", systemImage: "rectangle.split.3x3")
                    Label("\(Int(project.totalArea)) sq ft", systemImage: "ruler")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            Text(project.dateCreated, style: .date)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - New Project Sheet
struct NewProjectSheet: View {
    @EnvironmentObject var projectManager: ProjectManager
    @Binding var isPresented: Bool
    @State private var projectName = ""
    @State private var showScanner = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Project Name", text: $projectName)
                } header: {
                    Text("Project Details")
                } footer: {
                    Text("e.g., \"123 Main St\" or \"Johnson Remodel\"")
                }

                Section {
                    Button(action: createAndScan) {
                        Label("Create & Start Scanning", systemImage: "camera.viewfinder")
                    }
                    .disabled(projectName.isEmpty)

                    Button(action: createOnly) {
                        Label("Create Empty Project", systemImage: "doc.badge.plus")
                    }
                    .disabled(projectName.isEmpty)
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showScanner) {
            if let project = projectManager.currentProject {
                RoomScanView(project: project, isPresented: $showScanner)
            }
        }
    }

    private func createAndScan() {
        _ = projectManager.createNewProject(name: projectName)
        isPresented = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showScanner = true
        }
    }

    private func createOnly() {
        _ = projectManager.createNewProject(name: projectName)
        isPresented = false
    }
}

#Preview {
    ContentView()
        .environmentObject(ProjectManager())
}
