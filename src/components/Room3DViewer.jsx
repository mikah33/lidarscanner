import { Canvas } from '@react-three/fiber';
import { OrbitControls, PerspectiveCamera, Text, Line } from '@react-three/drei';
import { useMemo } from 'react';

// Single wall mesh with features (doors/windows as cutouts visually represented)
function Wall({ start, end, height, features = [], isXAligned }) {
  const length = isXAligned
    ? Math.abs(end.x - start.x)
    : Math.abs(end.z - start.z);

  const position = [
    (start.x + end.x) / 2,
    height / 2,
    (start.z + end.z) / 2
  ];

  const rotation = isXAligned ? [0, 0, 0] : [0, Math.PI / 2, 0];

  return (
    <group>
      {/* Main wall */}
      <mesh position={position} rotation={rotation}>
        <boxGeometry args={[length, height, 0.5]} />
        <meshStandardMaterial color="#d4c4b0" />
      </mesh>

      {/* Feature indicators (doors/windows) */}
      {features.map((feature, idx) => {
        const featureX = isXAligned
          ? start.x + feature.x + feature.width / 2
          : start.x;
        const featureZ = isXAligned
          ? start.z
          : start.z - feature.x - feature.width / 2;

        const featureColor = feature.type === 'door' ? '#8B4513' : '#87CEEB';

        return (
          <mesh
            key={idx}
            position={[featureX, feature.fromFloor + feature.height / 2, featureZ]}
            rotation={rotation}
          >
            <boxGeometry args={[feature.width, feature.height, 0.6]} />
            <meshStandardMaterial color={featureColor} transparent opacity={0.7} />
          </mesh>
        );
      })}
    </group>
  );
}

// Floor with grid
function Floor({ width, length }) {
  return (
    <group>
      <mesh rotation={[-Math.PI / 2, 0, 0]} position={[width / 2, 0, length / 2]}>
        <planeGeometry args={[width, length]} />
        <meshStandardMaterial color="#f5f5dc" />
      </mesh>
      {/* Grid lines */}
      <gridHelper
        args={[Math.max(width, length) + 4, Math.max(width, length) + 4, '#888888', '#cccccc']}
        position={[width / 2, 0.01, length / 2]}
      />
    </group>
  );
}

// Dimension line component
function DimensionLine({ start, end, label, offset = 2 }) {
  const midPoint = [
    (start[0] + end[0]) / 2,
    (start[1] + end[1]) / 2 + 0.5,
    (start[2] + end[2]) / 2
  ];

  return (
    <group>
      <Line
        points={[start, end]}
        color="#ff4444"
        lineWidth={2}
      />
      {/* End caps */}
      <Line
        points={[
          [start[0], start[1] - 0.3, start[2]],
          [start[0], start[1] + 0.3, start[2]]
        ]}
        color="#ff4444"
        lineWidth={2}
      />
      <Line
        points={[
          [end[0], end[1] - 0.3, end[2]],
          [end[0], end[1] + 0.3, end[2]]
        ]}
        color="#ff4444"
        lineWidth={2}
      />
      <Text
        position={midPoint}
        fontSize={0.8}
        color="#ff4444"
        anchorX="center"
        anchorY="bottom"
      >
        {label}
      </Text>
    </group>
  );
}

export default function Room3DViewer({ roomData, showDimensions = true }) {
  const { dimensions, walls } = roomData;

  return (
    <div style={{ width: '100%', height: '100%', background: '#1a1a2e' }}>
      <Canvas shadows>
        <PerspectiveCamera makeDefault position={[30, 20, 30]} fov={50} />
        <OrbitControls
          enablePan={true}
          enableZoom={true}
          enableRotate={true}
          target={[dimensions.width / 2, dimensions.height / 2, dimensions.length / 2]}
        />

        {/* Lighting */}
        <ambientLight intensity={0.5} />
        <directionalLight position={[10, 20, 10]} intensity={1} castShadow />
        <pointLight position={[dimensions.width / 2, dimensions.height - 1, dimensions.length / 2]} intensity={0.5} />

        {/* Floor */}
        <Floor width={dimensions.width} length={dimensions.length} />

        {/* Walls */}
        {walls.map((wall) => {
          const isXAligned = wall.start.z === wall.end.z;
          return (
            <Wall
              key={wall.id}
              start={wall.start}
              end={wall.end}
              height={dimensions.height}
              features={wall.features}
              isXAligned={isXAligned}
            />
          );
        })}

        {/* Dimension lines */}
        {showDimensions && (
          <>
            {/* Width dimension */}
            <DimensionLine
              start={[0, 0.1, -2]}
              end={[dimensions.width, 0.1, -2]}
              label={`${dimensions.width}' 0"`}
            />
            {/* Length dimension */}
            <DimensionLine
              start={[-2, 0.1, 0]}
              end={[-2, 0.1, dimensions.length]}
              label={`${dimensions.length}' 0"`}
            />
            {/* Height dimension */}
            <DimensionLine
              start={[-2, 0, -2]}
              end={[-2, dimensions.height, -2]}
              label={`${dimensions.height}' 0"`}
            />
          </>
        )}

        {/* Room label */}
        <Text
          position={[dimensions.width / 2, dimensions.height + 1, dimensions.length / 2]}
          fontSize={1.5}
          color="#ffffff"
          anchorX="center"
        >
          {roomData.name}
        </Text>
      </Canvas>
    </div>
  );
}
