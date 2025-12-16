import SwiftUI
import SceneKit

struct FloorPlan3DView: View {
    let project: FloorPlanProject

    @State private var cameraDistance: Float = 50
    @State private var cameraAngle: Float = 45

    var body: some View {
        ZStack {
            SceneKitContainer(project: project, cameraDistance: $cameraDistance, cameraAngle: $cameraAngle)
                .edgesIgnoringSafeArea(.all)

            // Overlay controls
            VStack {
                Spacer()

                HStack {
                    // Stats
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(project.rooms.count) Rooms")
                            .font(.caption)
                        Text("\(Int(project.totalArea)) sq ft")
                            .font(.caption)
                    }
                    .padding(10)
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(8)

                    Spacer()

                    // Camera controls
                    VStack(spacing: 8) {
                        Button(action: { cameraDistance = max(20, cameraDistance - 10) }) {
                            Image(systemName: "plus.magnifyingglass")
                                .frame(width: 44, height: 44)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(22)
                        }

                        Button(action: { cameraDistance = min(100, cameraDistance + 10) }) {
                            Image(systemName: "minus.magnifyingglass")
                                .frame(width: 44, height: 44)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(22)
                        }

                        Button(action: { cameraAngle = cameraAngle == 45 ? 90 : 45 }) {
                            Image(systemName: cameraAngle == 45 ? "view.3d" : "view.2d")
                                .frame(width: 44, height: 44)
                                .background(Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(22)
                        }
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - SceneKit Container
struct SceneKitContainer: UIViewRepresentable {
    let project: FloorPlanProject
    @Binding var cameraDistance: Float
    @Binding var cameraAngle: Float

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.scene = createScene()
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        sceneView.antialiasingMode = .multisampling4X

        return sceneView
    }

    func updateUIView(_ sceneView: SCNView, context: Context) {
        sceneView.scene = createScene()

        // Update camera
        if let cameraNode = sceneView.scene?.rootNode.childNode(withName: "camera", recursively: true) {
            let radians = cameraAngle * .pi / 180
            cameraNode.position = SCNVector3(
                x: 0,
                y: cameraDistance * sin(radians),
                z: cameraDistance * cos(radians)
            )
            cameraNode.look(at: SCNVector3(0, 0, 0))
        }
    }

    private func createScene() -> SCNScene {
        let scene = SCNScene()

        // Calculate center offset
        let centerX = project.rooms.map { $0.x + $0.width / 2 }.reduce(0, +) / max(1, Double(project.rooms.count))
        let centerZ = project.rooms.map { $0.z + $0.length / 2 }.reduce(0, +) / max(1, Double(project.rooms.count))

        // Add floor grid
        let gridNode = createGridNode(size: 100)
        gridNode.position = SCNVector3(0, -0.01, 0)
        scene.rootNode.addChildNode(gridNode)

        // Add rooms
        for room in project.rooms {
            let roomNode = createRoomNode(room: room, offsetX: centerX, offsetZ: centerZ)
            scene.rootNode.addChildNode(roomNode)
        }

        // Add doors
        for door in project.doors {
            let doorNode = createDoorNode(door: door, offsetX: centerX, offsetZ: centerZ)
            scene.rootNode.addChildNode(doorNode)
        }

        // Add windows
        for window in project.windows {
            let windowNode = createWindowNode(window: window, offsetX: centerX, offsetZ: centerZ)
            scene.rootNode.addChildNode(windowNode)
        }

        // Camera
        let cameraNode = SCNNode()
        cameraNode.name = "camera"
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zFar = 500
        let radians = cameraAngle * .pi / 180
        cameraNode.position = SCNVector3(
            x: 0,
            y: cameraDistance * sin(radians),
            z: cameraDistance * cos(radians)
        )
        cameraNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(cameraNode)

        // Ambient light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 500
        ambientLight.light?.color = UIColor.white
        scene.rootNode.addChildNode(ambientLight)

        // Directional light
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.intensity = 800
        directionalLight.light?.castsShadow = true
        directionalLight.position = SCNVector3(20, 40, 20)
        directionalLight.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(directionalLight)

        return scene
    }

    private func createRoomNode(room: Room, offsetX: Double, offsetZ: Double) -> SCNNode {
        let roomNode = SCNNode()

        let width = CGFloat(room.width)
        let height = CGFloat(room.height)
        let length = CGFloat(room.length)
        let wallThickness: CGFloat = 0.3

        let x = Float(room.x + room.width / 2 - offsetX)
        let z = Float(room.z + room.length / 2 - offsetZ)

        // Floor
        let floorGeometry = SCNBox(width: width, height: 0.1, length: length, chamferRadius: 0)
        let floorMaterial = SCNMaterial()
        if let uiColor = UIColor(hex: room.color) {
            floorMaterial.diffuse.contents = uiColor
        } else {
            floorMaterial.diffuse.contents = UIColor.lightGray
        }
        floorGeometry.materials = [floorMaterial]
        let floorNode = SCNNode(geometry: floorGeometry)
        floorNode.position = SCNVector3(x, 0.05, z)
        roomNode.addChildNode(floorNode)

        // Walls
        let wallMaterial = SCNMaterial()
        wallMaterial.diffuse.contents = UIColor.white
        wallMaterial.transparency = 0.85

        // Front wall (negative Z)
        let frontWall = SCNBox(width: width, height: height, length: wallThickness, chamferRadius: 0)
        frontWall.materials = [wallMaterial]
        let frontNode = SCNNode(geometry: frontWall)
        frontNode.position = SCNVector3(x, Float(height/2), z - Float(length/2))
        roomNode.addChildNode(frontNode)

        // Back wall (positive Z)
        let backWall = SCNBox(width: width, height: height, length: wallThickness, chamferRadius: 0)
        backWall.materials = [wallMaterial]
        let backNode = SCNNode(geometry: backWall)
        backNode.position = SCNVector3(x, Float(height/2), z + Float(length/2))
        roomNode.addChildNode(backNode)

        // Left wall (negative X)
        let leftWall = SCNBox(width: wallThickness, height: height, length: length, chamferRadius: 0)
        leftWall.materials = [wallMaterial]
        let leftNode = SCNNode(geometry: leftWall)
        leftNode.position = SCNVector3(x - Float(width/2), Float(height/2), z)
        roomNode.addChildNode(leftNode)

        // Right wall (positive X)
        let rightWall = SCNBox(width: wallThickness, height: height, length: length, chamferRadius: 0)
        rightWall.materials = [wallMaterial]
        let rightNode = SCNNode(geometry: rightWall)
        rightNode.position = SCNVector3(x + Float(width/2), Float(height/2), z)
        roomNode.addChildNode(rightNode)

        // Room label
        let textGeometry = SCNText(string: room.name, extrusionDepth: 0.1)
        textGeometry.font = UIFont.boldSystemFont(ofSize: 1)
        textGeometry.flatness = 0.1
        let textMaterial = SCNMaterial()
        textMaterial.diffuse.contents = UIColor.darkGray
        textGeometry.materials = [textMaterial]

        let textNode = SCNNode(geometry: textGeometry)
        let (minBound, maxBound) = textNode.boundingBox
        let textWidth = maxBound.x - minBound.x
        textNode.position = SCNVector3(x - textWidth/2, 0.2, z)
        textNode.eulerAngles = SCNVector3(-Float.pi/2, 0, 0)
        roomNode.addChildNode(textNode)

        return roomNode
    }

    private func createDoorNode(door: Door, offsetX: Double, offsetZ: Double) -> SCNNode {
        let doorGeometry = SCNBox(width: CGFloat(door.width), height: 7, length: 0.5, chamferRadius: 0)
        let material = SCNMaterial()
        material.diffuse.contents = door.isExterior ? UIColor.brown : UIColor.systemBrown.withAlphaComponent(0.8)
        doorGeometry.materials = [material]

        let doorNode = SCNNode(geometry: doorGeometry)
        doorNode.position = SCNVector3(
            Float(door.x - offsetX),
            3.5,
            Float(door.z - offsetZ)
        )

        return doorNode
    }

    private func createWindowNode(window: Window, offsetX: Double, offsetZ: Double) -> SCNNode {
        let windowGeometry = SCNBox(width: CGFloat(window.width), height: CGFloat(window.height), length: 0.3, chamferRadius: 0)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.systemBlue.withAlphaComponent(0.4)
        material.transparency = 0.6
        windowGeometry.materials = [material]

        let windowNode = SCNNode(geometry: windowGeometry)
        windowNode.position = SCNVector3(
            Float(window.x - offsetX),
            Float(window.fromFloor + window.height / 2),
            Float(window.z - offsetZ)
        )

        return windowNode
    }

    private func createGridNode(size: Float) -> SCNNode {
        let gridNode = SCNNode()

        let material = SCNMaterial()
        material.diffuse.contents = UIColor.gray.withAlphaComponent(0.3)

        let spacing: Float = 1.0 // 1 foot grid
        let halfSize = size / 2

        for i in stride(from: -halfSize, through: halfSize, by: spacing) {
            // X lines
            let xLineGeometry = SCNBox(width: CGFloat(size), height: 0.02, length: 0.02, chamferRadius: 0)
            xLineGeometry.materials = [material]
            let xLineNode = SCNNode(geometry: xLineGeometry)
            xLineNode.position = SCNVector3(0, 0, i)
            gridNode.addChildNode(xLineNode)

            // Z lines
            let zLineGeometry = SCNBox(width: 0.02, height: 0.02, length: CGFloat(size), chamferRadius: 0)
            zLineGeometry.materials = [material]
            let zLineNode = SCNNode(geometry: zLineGeometry)
            zLineNode.position = SCNVector3(i, 0, 0)
            gridNode.addChildNode(zLineNode)
        }

        return gridNode
    }
}

#Preview {
    var project = FloorPlanProject(name: "Sample House")
    project.rooms = [
        Room(name: "Living Room", x: 0, z: 0, width: 18, length: 24, height: 9),
        Room(name: "Kitchen", x: 20, z: 0, width: 12, length: 14, height: 9),
        Room(name: "Bedroom", x: 0, z: 26, width: 14, length: 12, height: 9)
    ]
    return FloorPlan3DView(project: project)
}
