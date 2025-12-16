import SwiftUI

@main
struct LiDARScannerApp: App {
    @StateObject private var projectManager = ProjectManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(projectManager)
        }
    }
}

// MARK: - Project Manager
class ProjectManager: ObservableObject {
    @Published var projects: [FloorPlanProject] = []
    @Published var currentProject: FloorPlanProject?

    private let saveKey = "SavedProjects"

    init() {
        loadProjects()
    }

    func createNewProject(name: String) -> FloorPlanProject {
        let project = FloorPlanProject(name: name)
        projects.append(project)
        currentProject = project
        saveProjects()
        return project
    }

    func deleteProject(_ project: FloorPlanProject) {
        projects.removeAll { $0.id == project.id }
        if currentProject?.id == project.id {
            currentProject = nil
        }
        saveProjects()
    }

    func saveProjects() {
        if let encoded = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    func loadProjects() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([FloorPlanProject].self, from: data) {
            projects = decoded
        }
    }

    func updateProject(_ project: FloorPlanProject) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
            if currentProject?.id == project.id {
                currentProject = project
            }
            saveProjects()
        }
    }
}
