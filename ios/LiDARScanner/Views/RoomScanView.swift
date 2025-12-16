import SwiftUI
import RoomPlan

struct RoomScanView: View {
    @EnvironmentObject var projectManager: ProjectManager
    let project: FloorPlanProject
    @Binding var isPresented: Bool

    @StateObject private var scanController = RoomScanController()
    @State private var showingSaveDialog = false
    @State private var roomName = ""

    var body: some View {
        ZStack {
            // RoomPlan Capture View
            RoomCaptureViewContainer(controller: scanController)
                .edgesIgnoringSafeArea(.all)

            // Overlay UI
            VStack {
                // Top bar
                HStack {
                    Button(action: {
                        scanController.stopSession()
                        isPresented = false
                    }) {
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

                    // Done button to finish scanning
                    Button(action: {
                        scanController.stopSession()
                    }) {
                        Text("Done")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                .padding()

                Spacer()

                // Bottom controls
                VStack(spacing: 16) {
                    if let _ = scanController.capturedRoom {
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
                            if scanController.isScanning {
                                Text("Scanning...")
                                    .font(.headline)
                                Text("Move slowly around the room, then tap Done")
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
        scanController.resetScan()
    }

    private func saveRoom() {
        guard let captured = scanController.capturedRoom else { return }

        // Convert RoomPlan data to our Room model
        let room = convertCapturedRoom(captured, name: roomName)

        var updatedProject = project
        updatedProject.addRoom(room)
        projectManager.updateProject(updatedProject)

        // Reset for next scan or close
        scanController.resetScan()
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

        // Handle case with no walls detected
        var width: Double = 12
        var length: Double = 12
        var height: Double = 9

        if minX != .infinity {
            width = Double(maxX - minX) * metersToFeet
            length = Double(maxZ - minZ) * metersToFeet
            height = Double(maxY) * metersToFeet
        }

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

// MARK: - Room Scan Controller
class RoomScanController: ObservableObject {
    @Published var capturedRoom: CapturedRoom?
    @Published var isScanning = false

    var roomCaptureView: RoomCaptureView?
    private var sessionDelegate: RoomCaptureSessionDelegateHandler?
    private var viewDelegate: RoomCaptureViewDelegateHandler?

    func setupCaptureView() -> RoomCaptureView {
        let captureView = RoomCaptureView(frame: .zero)
        self.roomCaptureView = captureView

        // Create and set delegates
        let sessionDel = RoomCaptureSessionDelegateHandler(controller: self)
        let viewDel = RoomCaptureViewDelegateHandler(controller: self)
        self.sessionDelegate = sessionDel
        self.viewDelegate = viewDel
        captureView.captureSession.delegate = sessionDel
        captureView.delegate = viewDel

        return captureView
    }

    func startSession() {
        guard RoomCaptureSession.isSupported else { return }
        let config = RoomCaptureSession.Configuration()
        roomCaptureView?.captureSession.run(configuration: config)
    }

    func stopSession() {
        roomCaptureView?.captureSession.stop()
    }

    func resetScan() {
        capturedRoom = nil
        isScanning = false
        startSession()
    }

}

// MARK: - Session Delegate
class RoomCaptureSessionDelegateHandler: NSObject, RoomCaptureSessionDelegate {
    weak var controller: RoomScanController?

    init(controller: RoomScanController) {
        self.controller = controller
    }

    func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {
        DispatchQueue.main.async {
            self.controller?.isScanning = true
        }
    }

    func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: Error?) {
        // Session ended, process the data
    }
}

// MARK: - View Delegate
class RoomCaptureViewDelegateHandler: UIViewController, RoomCaptureViewDelegate {
    weak var controller: RoomScanController?

    init(controller: RoomScanController) {
        self.controller = controller
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
        return true
    }

    func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        DispatchQueue.main.async {
            self.controller?.capturedRoom = processedResult
            self.controller?.isScanning = false
        }
    }
}

// MARK: - RoomCaptureView Container
struct RoomCaptureViewContainer: UIViewRepresentable {
    @ObservedObject var controller: RoomScanController

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView(frame: .zero)

        // Check for LiDAR support
        guard RoomCaptureSession.isSupported else {
            let label = UILabel()
            label.text = "LiDAR not available on this device.\nRequires iPhone 12 Pro+ or iPad Pro 2020+"
            label.textAlignment = .center
            label.numberOfLines = 0
            label.textColor = .white
            label.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(label)
            containerView.backgroundColor = .black

            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                label.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 20),
                label.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -20)
            ])

            return containerView
        }

        let captureView = controller.setupCaptureView()
        captureView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(captureView)

        NSLayoutConstraint.activate([
            captureView.topAnchor.constraint(equalTo: containerView.topAnchor),
            captureView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            captureView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            captureView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])

        // Start session after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            controller.startSession()
        }

        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

#Preview {
    RoomScanView(
        project: FloorPlanProject(name: "Test Project"),
        isPresented: .constant(true)
    )
    .environmentObject(ProjectManager())
}
