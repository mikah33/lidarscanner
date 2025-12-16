import { useRef, useState, useEffect, useCallback } from 'react';

const SCALE = 15; // pixels per foot
const PADDING = 60;
const HANDLE_SIZE = 8;

export default function FloorPlan2D({
  floorPlanData,
  onRoomUpdate,
  onRoomSelect,
  onRoomDoubleClick,
  selectedRoomId,
  editMode = false
}) {
  const canvasRef = useRef(null);
  const [measureMode, setMeasureMode] = useState(false);
  const [measureStart, setMeasureStart] = useState(null);
  const [measureEnd, setMeasureEnd] = useState(null);
  const [measurements, setMeasurements] = useState([]);
  const [hoveredRoom, setHoveredRoom] = useState(null);

  // Drag state
  const [dragState, setDragState] = useState(null); // { type: 'move' | 'resize', roomId, handle?, startX, startY, originalRoom }
  const [cursorStyle, setCursorStyle] = useState('default');

  // Calculate canvas dimensions with some extra space for editing
  const maxX = Math.max(...floorPlanData.rooms.map(r => r.x + r.width), 50) + 10;
  const maxZ = Math.max(...floorPlanData.rooms.map(r => r.z + r.length), 40) + 10;
  const canvasWidth = maxX * SCALE + PADDING * 2;
  const canvasHeight = maxZ * SCALE + PADDING * 2;

  // Convert room coordinates to canvas coordinates
  const toCanvas = (x, z) => ({
    x: x * SCALE + PADDING,
    y: z * SCALE + PADDING
  });

  // Convert canvas coordinates to room coordinates (feet)
  const toRoom = (canvasX, canvasY) => ({
    x: (canvasX - PADDING) / SCALE,
    z: (canvasY - PADDING) / SCALE
  });

  // Snap to grid (0.5 ft increments)
  const snapToGrid = (value) => Math.round(value * 2) / 2;

  // Check if point is on a resize handle
  const getResizeHandle = (room, canvasX, canvasY) => {
    const { x, y } = toCanvas(room.x, room.z);
    const width = room.width * SCALE;
    const height = room.length * SCALE;

    const handles = [
      { name: 'nw', x: x, y: y },
      { name: 'ne', x: x + width, y: y },
      { name: 'sw', x: x, y: y + height },
      { name: 'se', x: x + width, y: y + height },
      { name: 'n', x: x + width/2, y: y },
      { name: 's', x: x + width/2, y: y + height },
      { name: 'w', x: x, y: y + height/2 },
      { name: 'e', x: x + width, y: y + height/2 },
    ];

    for (const handle of handles) {
      if (Math.abs(canvasX - handle.x) < HANDLE_SIZE && Math.abs(canvasY - handle.y) < HANDLE_SIZE) {
        return handle.name;
      }
    }
    return null;
  };

  // Get cursor for resize handle
  const getCursorForHandle = (handle) => {
    const cursors = {
      'nw': 'nw-resize', 'ne': 'ne-resize', 'sw': 'sw-resize', 'se': 'se-resize',
      'n': 'n-resize', 's': 's-resize', 'w': 'w-resize', 'e': 'e-resize'
    };
    return cursors[handle] || 'default';
  };

  useEffect(() => {
    const canvas = canvasRef.current;
    const ctx = canvas.getContext('2d');

    // Clear canvas
    ctx.fillStyle = '#ffffff';
    ctx.fillRect(0, 0, canvasWidth, canvasHeight);

    // Draw grid
    ctx.strokeStyle = '#e0e0e0';
    ctx.lineWidth = 0.5;
    for (let x = PADDING; x <= canvasWidth - PADDING; x += SCALE) {
      ctx.beginPath();
      ctx.moveTo(x, PADDING);
      ctx.lineTo(x, canvasHeight - PADDING);
      ctx.stroke();
    }
    for (let y = PADDING; y <= canvasHeight - PADDING; y += SCALE) {
      ctx.beginPath();
      ctx.moveTo(PADDING, y);
      ctx.lineTo(canvasWidth - PADDING, y);
      ctx.stroke();
    }

    // Draw rooms
    floorPlanData.rooms.forEach(room => {
      const { x, y } = toCanvas(room.x, room.z);
      const width = room.width * SCALE;
      const height = room.length * SCALE;

      // Room fill
      const isSelected = room.id === selectedRoomId;
      const isHovered = room.id === hoveredRoom;
      ctx.fillStyle = isSelected ? '#b8d4ff' : isHovered ? '#d0e8ff' : room.color;
      ctx.fillRect(x, y, width, height);

      // Room outline
      ctx.strokeStyle = isSelected ? '#2196F3' : '#333333';
      ctx.lineWidth = isSelected ? 3 : 2;
      ctx.strokeRect(x, y, width, height);

      // Room name
      ctx.fillStyle = '#333333';
      ctx.font = 'bold 14px Arial';
      ctx.textAlign = 'center';
      ctx.fillText(room.name, x + width / 2, y + height / 2 - 10);

      // Room dimensions
      ctx.font = '12px Arial';
      ctx.fillStyle = '#666666';
      ctx.fillText(
        `${room.width}' x ${room.length}'`,
        x + width / 2,
        y + height / 2 + 10
      );

      // Area
      ctx.font = '11px Arial';
      ctx.fillStyle = '#888888';
      ctx.fillText(
        `${room.width * room.length} sq ft`,
        x + width / 2,
        y + height / 2 + 25
      );

      // Draw resize handles for selected room in edit mode
      if (editMode && isSelected) {
        ctx.fillStyle = '#2196F3';
        const handles = [
          { x: x, y: y },
          { x: x + width, y: y },
          { x: x, y: y + height },
          { x: x + width, y: y + height },
          { x: x + width/2, y: y },
          { x: x + width/2, y: y + height },
          { x: x, y: y + height/2 },
          { x: x + width, y: y + height/2 },
        ];
        handles.forEach(h => {
          ctx.fillRect(h.x - HANDLE_SIZE/2, h.y - HANDLE_SIZE/2, HANDLE_SIZE, HANDLE_SIZE);
        });
      }
    });

    // Draw doors
    ctx.fillStyle = '#8B4513';
    floorPlanData.doors?.forEach(door => {
      const { x, y } = toCanvas(door.x, door.z);
      ctx.fillRect(x - 2, y - door.width * SCALE / 2, 4, door.width * SCALE);

      // Door swing arc
      ctx.strokeStyle = '#8B4513';
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.arc(x, y, door.width * SCALE * 0.7, -Math.PI / 2, 0);
      ctx.stroke();
    });

    // Draw exterior doors
    floorPlanData.exteriorDoors?.forEach(door => {
      const { x, y } = toCanvas(door.x, door.z);
      ctx.fillStyle = '#654321';
      ctx.fillRect(x - 3, y - door.width * SCALE / 2, 6, door.width * SCALE);

      // Label
      ctx.fillStyle = '#654321';
      ctx.font = '10px Arial';
      ctx.textAlign = 'left';
      ctx.fillText(door.label, x + 10, y + 4);
    });

    // Draw windows
    ctx.strokeStyle = '#4169E1';
    ctx.lineWidth = 3;
    floorPlanData.windows?.forEach(window => {
      const { x, y } = toCanvas(window.x, window.z);
      ctx.beginPath();
      ctx.moveTo(x - window.width * SCALE / 2, y);
      ctx.lineTo(x + window.width * SCALE / 2, y);
      ctx.stroke();
    });

    // Draw measurements
    ctx.strokeStyle = '#ff4444';
    ctx.fillStyle = '#ff4444';
    ctx.lineWidth = 2;
    measurements.forEach(m => {
      const start = toCanvas(m.start.x, m.start.z);
      const end = toCanvas(m.end.x, m.end.z);

      // Line
      ctx.beginPath();
      ctx.moveTo(start.x, start.y);
      ctx.lineTo(end.x, end.y);
      ctx.stroke();

      // End caps
      ctx.beginPath();
      ctx.arc(start.x, start.y, 4, 0, Math.PI * 2);
      ctx.fill();
      ctx.beginPath();
      ctx.arc(end.x, end.y, 4, 0, Math.PI * 2);
      ctx.fill();

      // Distance label
      const midX = (start.x + end.x) / 2;
      const midY = (start.y + end.y) / 2;
      const distance = Math.sqrt(
        Math.pow(m.end.x - m.start.x, 2) + Math.pow(m.end.z - m.start.z, 2)
      );

      ctx.fillStyle = '#ffffff';
      ctx.fillRect(midX - 30, midY - 10, 60, 20);
      ctx.fillStyle = '#ff4444';
      ctx.font = 'bold 12px Arial';
      ctx.textAlign = 'center';
      ctx.fillText(`${distance.toFixed(1)}'`, midX, midY + 4);
    });

    // Draw active measurement
    if (measureStart && measureEnd) {
      const start = toCanvas(measureStart.x, measureStart.z);
      const end = toCanvas(measureEnd.x, measureEnd.z);

      ctx.setLineDash([5, 5]);
      ctx.strokeStyle = '#ff4444';
      ctx.beginPath();
      ctx.moveTo(start.x, start.y);
      ctx.lineTo(end.x, end.y);
      ctx.stroke();
      ctx.setLineDash([]);

      const distance = Math.sqrt(
        Math.pow(measureEnd.x - measureStart.x, 2) +
        Math.pow(measureEnd.z - measureStart.z, 2)
      );

      const midX = (start.x + end.x) / 2;
      const midY = (start.y + end.y) / 2;
      ctx.fillStyle = '#ff4444';
      ctx.font = 'bold 14px Arial';
      ctx.fillText(`${distance.toFixed(2)}'`, midX, midY - 10);
    }

    // Draw scale indicator
    ctx.fillStyle = '#333333';
    ctx.font = '12px Arial';
    ctx.textAlign = 'left';
    ctx.fillText('Scale: 1 grid = 1 foot', 10, canvasHeight - 10);

    // Total area
    ctx.textAlign = 'right';
    const totalArea = floorPlanData.rooms.reduce((sum, r) => sum + r.width * r.length, 0);
    ctx.fillText(
      `Total Area: ${totalArea} sq ft`,
      canvasWidth - 10,
      canvasHeight - 10
    );

  }, [floorPlanData, hoveredRoom, measurements, measureStart, measureEnd, selectedRoomId, editMode, canvasWidth, canvasHeight]);

  const handleMouseDown = (e) => {
    const rect = canvasRef.current.getBoundingClientRect();
    const canvasX = e.clientX - rect.left;
    const canvasY = e.clientY - rect.top;
    const roomCoords = toRoom(canvasX, canvasY);

    if (measureMode) {
      setMeasureStart(roomCoords);
      setMeasureEnd(null);
      return;
    }

    if (editMode) {
      // Check if clicking on a resize handle of selected room
      if (selectedRoomId) {
        const selectedRoom = floorPlanData.rooms.find(r => r.id === selectedRoomId);
        if (selectedRoom) {
          const handle = getResizeHandle(selectedRoom, canvasX, canvasY);
          if (handle) {
            setDragState({
              type: 'resize',
              roomId: selectedRoomId,
              handle,
              startX: canvasX,
              startY: canvasY,
              originalRoom: { ...selectedRoom }
            });
            return;
          }
        }
      }

      // Check if clicking inside a room to move it
      const clickedRoom = floorPlanData.rooms.find(r =>
        roomCoords.x >= r.x && roomCoords.x <= r.x + r.width &&
        roomCoords.z >= r.z && roomCoords.z <= r.z + r.length
      );

      if (clickedRoom) {
        onRoomSelect?.(clickedRoom.id);
        setDragState({
          type: 'move',
          roomId: clickedRoom.id,
          startX: canvasX,
          startY: canvasY,
          offsetX: roomCoords.x - clickedRoom.x,
          offsetZ: roomCoords.z - clickedRoom.z,
          originalRoom: { ...clickedRoom }
        });
      } else {
        onRoomSelect?.(null);
      }
    }
  };

  const handleMouseMove = (e) => {
    const rect = canvasRef.current.getBoundingClientRect();
    const canvasX = e.clientX - rect.left;
    const canvasY = e.clientY - rect.top;
    const roomCoords = toRoom(canvasX, canvasY);

    // Handle dragging
    if (dragState && editMode) {
      const room = floorPlanData.rooms.find(r => r.id === dragState.roomId);
      if (!room) return;

      if (dragState.type === 'move') {
        const newX = snapToGrid(roomCoords.x - dragState.offsetX);
        const newZ = snapToGrid(roomCoords.z - dragState.offsetZ);
        onRoomUpdate?.({
          ...room,
          x: Math.max(0, newX),
          z: Math.max(0, newZ)
        });
      } else if (dragState.type === 'resize') {
        const orig = dragState.originalRoom;
        const handle = dragState.handle;
        let newX = orig.x;
        let newZ = orig.z;
        let newWidth = orig.width;
        let newLength = orig.length;

        const dx = snapToGrid(roomCoords.x) - snapToGrid(toRoom(dragState.startX, 0).x);
        const dz = snapToGrid(roomCoords.z) - snapToGrid(toRoom(0, dragState.startY).z);

        if (handle.includes('e')) {
          newWidth = Math.max(2, orig.width + dx);
        }
        if (handle.includes('w')) {
          newWidth = Math.max(2, orig.width - dx);
          newX = orig.x + (orig.width - newWidth);
        }
        if (handle.includes('s')) {
          newLength = Math.max(2, orig.length + dz);
        }
        if (handle.includes('n')) {
          newLength = Math.max(2, orig.length - dz);
          newZ = orig.z + (orig.length - newLength);
        }

        onRoomUpdate?.({
          ...room,
          x: Math.max(0, newX),
          z: Math.max(0, newZ),
          width: newWidth,
          length: newLength
        });
      }
      return;
    }

    // Update cursor based on what we're hovering over
    if (editMode && selectedRoomId) {
      const selectedRoom = floorPlanData.rooms.find(r => r.id === selectedRoomId);
      if (selectedRoom) {
        const handle = getResizeHandle(selectedRoom, canvasX, canvasY);
        if (handle) {
          setCursorStyle(getCursorForHandle(handle));
        } else if (
          roomCoords.x >= selectedRoom.x && roomCoords.x <= selectedRoom.x + selectedRoom.width &&
          roomCoords.z >= selectedRoom.z && roomCoords.z <= selectedRoom.z + selectedRoom.length
        ) {
          setCursorStyle('move');
        } else {
          setCursorStyle('default');
        }
      }
    } else if (measureMode) {
      setCursorStyle('crosshair');
    } else {
      setCursorStyle('default');
    }

    // Check for room hover
    const room = floorPlanData.rooms.find(r =>
      roomCoords.x >= r.x && roomCoords.x <= r.x + r.width &&
      roomCoords.z >= r.z && roomCoords.z <= r.z + r.length
    );
    setHoveredRoom(room?.id || null);

    if (measureMode && measureStart) {
      setMeasureEnd(roomCoords);
    }
  };

  const handleMouseUp = () => {
    if (measureMode && measureStart && measureEnd) {
      setMeasurements([...measurements, { start: measureStart, end: measureEnd }]);
      setMeasureStart(null);
      setMeasureEnd(null);
    }
    setDragState(null);
  };

  const handleDoubleClick = (e) => {
    if (!editMode) return;

    const rect = canvasRef.current.getBoundingClientRect();
    const canvasX = e.clientX - rect.left;
    const canvasY = e.clientY - rect.top;
    const roomCoords = toRoom(canvasX, canvasY);

    const clickedRoom = floorPlanData.rooms.find(r =>
      roomCoords.x >= r.x && roomCoords.x <= r.x + r.width &&
      roomCoords.z >= r.z && roomCoords.z <= r.z + r.length
    );

    if (clickedRoom) {
      onRoomDoubleClick?.(clickedRoom);
    }
  };

  const clearMeasurements = () => {
    setMeasurements([]);
    setMeasureStart(null);
    setMeasureEnd(null);
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <div style={{
        padding: '10px',
        background: '#f0f0f0',
        borderBottom: '1px solid #ccc',
        display: 'flex',
        gap: '10px',
        alignItems: 'center',
        flexWrap: 'wrap'
      }}>
        <button
          onClick={() => { setMeasureMode(!measureMode); if (!measureMode) onRoomSelect?.(null); }}
          style={{
            padding: '8px 16px',
            background: measureMode ? '#ff4444' : '#4CAF50',
            color: 'white',
            border: 'none',
            borderRadius: '4px',
            cursor: 'pointer',
            fontWeight: 'bold'
          }}
        >
          {measureMode ? 'Measuring...' : 'Measure'}
        </button>
        <button
          onClick={clearMeasurements}
          style={{
            padding: '8px 16px',
            background: '#666',
            color: 'white',
            border: 'none',
            borderRadius: '4px',
            cursor: 'pointer'
          }}
        >
          Clear Measurements
        </button>
        <span style={{ marginLeft: 'auto', color: '#666', fontSize: '13px' }}>
          {measureMode
            ? 'Click and drag to measure'
            : editMode
              ? 'Click room to select, drag to move, drag handles to resize, double-click to edit'
              : 'Enable Edit Mode to modify rooms'
          }
        </span>
      </div>
      <div style={{
        flex: 1,
        overflow: 'auto',
        background: '#e8e8e8',
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'flex-start',
        padding: '20px'
      }}>
        <canvas
          ref={canvasRef}
          width={canvasWidth}
          height={canvasHeight}
          style={{
            background: 'white',
            boxShadow: '0 2px 10px rgba(0,0,0,0.2)',
            cursor: cursorStyle
          }}
          onMouseDown={handleMouseDown}
          onMouseMove={handleMouseMove}
          onMouseUp={handleMouseUp}
          onMouseLeave={handleMouseUp}
          onDoubleClick={handleDoubleClick}
        />
      </div>
    </div>
  );
}
