import SwiftUI

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
    NavigationStack {
        ProjectListView()
    }
    .environmentObject({
        let manager = ProjectManager()
        var project = FloorPlanProject(name: "Sample House")
        project.addRoom(Room(name: "Living Room", width: 18, length: 24))
        project.addRoom(Room(name: "Kitchen", x: 20, width: 12, length: 14))
        manager.projects = [project]
        return manager
    }())
}
