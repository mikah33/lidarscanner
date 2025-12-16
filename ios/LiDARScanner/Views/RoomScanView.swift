import SwiftUI
import RoomPlan

struct RoomScanView: View {
    @EnvironmentObject var projectManager: ProjectManager
    let project: FloorPlanProject
    @Binding var isPresented: Bool

    @State private var capturedRoom: CapturedRoom?
    @State private var isScanning = false
    @State private var showingSaveDialog = false
    @State private var roomName = ""

    var body: some View {
        ZStack {
            // RoomPlan Capture View
            RoomCaptureViewRepresentable(
                capturedRoom: $capturedRoom,
                isScanning: $isScanning
            )
            .edgesIgnoringSafeArea(.all)

            // Overlay UI
            VStack {
                // Top bar
                HStack {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .shadow(radius: 3)
                    }

                    Spacer()

                    Text(project.name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .shadow(radius: 3)

                    Spacer()

                    // Placeholder for symmetry
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.clear)
                }
                .padding()

                Spacer()

                // Bottom controls
                VStack(spacing: 16) {
                    if let room = capturedRoom {
                        // Room captured - show save button
                        VStack(spacing: 12) {
                            Text("Room Captured!")
                                .font(.headline)
                                .foregroundColor(.white)

                            HStack(spacing: 20) {
                                Button(action: resetScan) {
                                    Label("Rescan", systemImage: "arrow.counterclockwise")
                                        .padding()
                                        .background(Color.gray.opacity(0.8))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }

                                Button(action: { showingSaveDialog = true }) {
                                    Label("Save Room", systemImage: "checkmark.circle.fill")
                                        .padding()
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(16)
                    } else {
                        // Scanning instructions
                        VStack(spacing: 8) {
                            if isScanning {
                                Text("Scanning...")
                                    .font(.headline)
                                Text("Move slowly around the room")
                                    .font(.subheadline)
                            } else {
                                Text("Point at the room to start")
                                    .font(.headline)
                                Text("The scan will begin automatically")
                                    .font(.subheadline)
                            }
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(16)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .alert("Save Room", isPresented: $showingSaveDialog) {
            TextField("Room Name", text: $roomName)
            Button("Save") {
                saveRoom()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter a name for this room")
        }
        .onAppear {
            roomName = "Room \(project.rooms.count + 1)"
        }
    }

    private func resetScan() {
        capturedRoom = nil
        isScanning = false
    }

    private func saveRoom() {
        guard let captured = capturedRoom else { return }

        // Convert RoomPlan data to our Room model
        let room = convertCapturedRoom(captured, name: roomName)

        var updatedProject = project
        updatedProject.addRoom(room)
        projectManager.updateProject(updatedProject)

        // Reset for next scan or close
        capturedRoom = nil
        roomName = "Room \(updatedProject.rooms.count + 1)"
    }

    private func convertCapturedRoom(_ captured: CapturedRoom, name: String) -> Room {
        // Get room dimensions from RoomPlan
        // Note: RoomPlan uses meters, we convert to feet
        let metersToFeet = 3.28084

        // Calculate bounding box from walls
        var minX: Float = .infinity
        var maxX: Float = -.infinity
        var minZ: Float = .infinity
        var maxZ: Float = -.infinity
        var maxY: Float = 0

        for wall in captured.walls {
            let transform = wall.transform
            let position = SIMD3<Float>(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            let dimensions = wall.dimensions

            minX = min(minX, position.x - dimensions.x / 2)
            maxX = max(maxX, position.x + dimensions.x / 2)
            minZ = min(minZ, position.z - dimensions.z / 2)
            maxZ = max(maxZ, position.z + dimensions.z / 2)
            maxY = max(maxY, dimensions.y)
        }

        let width = Double(maxX - minX) * metersToFeet
        let length = Double(maxZ - minZ) * metersToFeet
        let height = Double(maxY) * metersToFeet

        // Find position for new room (place after existing rooms)
        let existingMaxX = project.rooms.map { $0.x + $0.width }.max() ?? 0

        return Room(
            name: name,
            x: existingMaxX > 0 ? existingMaxX + 2 : 0,
            z: 0,
            width: max(4, width),  // Minimum 4 feet
            length: max(4, length),
            height: max(8, min(height, 20)), // Clamp height 8-20 feet
            color: RoomColors.color(for: project.rooms.count)
        )
    }
}

// MARK: - RoomPlan UIKit Integration
struct RoomCaptureViewRepresentable: UIViewControllerRepresentable {
    @Binding var capturedRoom: CapturedRoom?
    @Binding var isScanning: Bool

    func makeUIViewController(context: Context) -> RoomCaptureViewController {
        let controller = RoomCaptureViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: RoomCaptureViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, RoomCaptureViewDelegate, RoomCaptureSessionDelegate {
        var parent: RoomCaptureViewRepresentable

        init(_ parent: RoomCaptureViewRepresentable) {
            self.parent = parent
        }

        func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
            return true
        }

        func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
            DispatchQueue.main.async {
                self.parent.capturedRoom = processedResult
                self.parent.isScanning = false
            }
        }

        func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {
            DispatchQueue.main.async {
                self.parent.isScanning = true
            }
        }
    }
}

// MARK: - RoomCapture ViewController
class RoomCaptureViewController: UIViewController {
    var delegate: (RoomCaptureViewDelegate & RoomCaptureSessionDelegate)?

    private var roomCaptureView: RoomCaptureView?
    private var roomCaptureSession: RoomCaptureSession?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Check for LiDAR support
        guard RoomCaptureSession.isSupported else {
            showUnsupportedAlert()
            return
        }

        setupRoomCapture()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }

    private func setupRoomCapture() {
        let captureView = RoomCaptureView(frame: view.bounds)
        captureView.captureSession.delegate = delegate
        captureView.delegate = delegate
        captureView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        view.addSubview(captureView)
        self.roomCaptureView = captureView
        self.roomCaptureSession = captureView.captureSession
    }

    private func startSession() {
        let config = RoomCaptureSession.Configuration()
        roomCaptureSession?.run(configuration: config)
    }

    private func stopSession() {
        roomCaptureSession?.stop()
    }

    private func showUnsupportedAlert() {
        let alert = UIAlertController(
            title: "LiDAR Not Available",
            message: "This device doesn't have a LiDAR scanner. You need an iPhone 12 Pro or newer, or iPad Pro 2020 or newer.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

#Preview {
    RoomScanView(
        project: FloorPlanProject(name: "Test Project"),
        isPresented: .constant(true)
    )
    .environmentObject(ProjectManager())
}
