import { useState, useRef, useCallback } from 'react';
import Room3DViewer from './components/Room3DViewer';
import FloorPlan2D from './components/FloorPlan2D';
import { AddRoomModal, EditRoomModal, AddDoorModal, AddWindowModal } from './components/RoomEditor';
import { mockRoom, mockFloorPlan } from './data/mockRoomData';
import { exportAsPNG, exportAsPDF, exportAsDXF, exportAsJSON } from './utils/exportUtils';
import './App.css';

// Create editable floor plan from mock data
const createEditableFloorPlan = () => ({
  ...mockFloorPlan,
  rooms: [...mockFloorPlan.rooms],
  doors: [...(mockFloorPlan.doors || [])],
  exteriorDoors: [...(mockFloorPlan.exteriorDoors || [])],
  windows: [...(mockFloorPlan.windows || [])],
});

function App() {
  const [activeView, setActiveView] = useState('2d');
  const [showDimensions, setShowDimensions] = useState(true);
  const [selectedRoomId, setSelectedRoomId] = useState(null);
  const [editMode, setEditMode] = useState(false);

  // Editable floor plan state
  const [floorPlan, setFloorPlan] = useState(createEditableFloorPlan);

  // Modal states
  const [showAddRoom, setShowAddRoom] = useState(false);
  const [showEditRoom, setShowEditRoom] = useState(false);
  const [showAddDoor, setShowAddDoor] = useState(false);
  const [showAddWindow, setShowAddWindow] = useState(false);
  const [editingRoom, setEditingRoom] = useState(null);

  // Undo/Redo history
  const [history, setHistory] = useState([]);
  const [historyIndex, setHistoryIndex] = useState(-1);

  // Save state for undo
  const saveToHistory = useCallback((newFloorPlan) => {
    const newHistory = history.slice(0, historyIndex + 1);
    newHistory.push(JSON.stringify(newFloorPlan));
    if (newHistory.length > 50) newHistory.shift(); // Keep max 50 states
    setHistory(newHistory);
    setHistoryIndex(newHistory.length - 1);
  }, [history, historyIndex]);

  // Calculate total area
  const totalArea = floorPlan.rooms.reduce((sum, r) => sum + r.width * r.length, 0);

  // Room operations
  const handleAddRoom = (newRoom) => {
    const updated = {
      ...floorPlan,
      rooms: [...floorPlan.rooms, newRoom]
    };
    setFloorPlan(updated);
    saveToHistory(updated);
  };

  const handleUpdateRoom = (updatedRoom) => {
    const updated = {
      ...floorPlan,
      rooms: floorPlan.rooms.map(r => r.id === updatedRoom.id ? updatedRoom : r)
    };
    setFloorPlan(updated);
  };

  const handleSaveRoom = (updatedRoom) => {
    const updated = {
      ...floorPlan,
      rooms: floorPlan.rooms.map(r => r.id === updatedRoom.id ? updatedRoom : r)
    };
    setFloorPlan(updated);
    saveToHistory(updated);
  };

  const handleDeleteRoom = (roomId) => {
    const updated = {
      ...floorPlan,
      rooms: floorPlan.rooms.filter(r => r.id !== roomId)
    };
    setFloorPlan(updated);
    saveToHistory(updated);
    setSelectedRoomId(null);
  };

  const handleRoomDoubleClick = (room) => {
    setEditingRoom(room);
    setShowEditRoom(true);
  };

  // Door operations
  const handleAddDoor = (door) => {
    if (door.type === 'exterior') {
      const updated = {
        ...floorPlan,
        exteriorDoors: [...floorPlan.exteriorDoors, door]
      };
      setFloorPlan(updated);
      saveToHistory(updated);
    } else {
      const updated = {
        ...floorPlan,
        doors: [...floorPlan.doors, door]
      };
      setFloorPlan(updated);
      saveToHistory(updated);
    }
  };

  // Window operations
  const handleAddWindow = (window) => {
    const updated = {
      ...floorPlan,
      windows: [...floorPlan.windows, window]
    };
    setFloorPlan(updated);
    saveToHistory(updated);
  };

  // Undo/Redo
  const canUndo = historyIndex > 0;
  const canRedo = historyIndex < history.length - 1;

  const handleUndo = () => {
    if (canUndo) {
      setHistoryIndex(historyIndex - 1);
      setFloorPlan(JSON.parse(history[historyIndex - 1]));
    }
  };

  const handleRedo = () => {
    if (canRedo) {
      setHistoryIndex(historyIndex + 1);
      setFloorPlan(JSON.parse(history[historyIndex + 1]));
    }
  };

  // New floor plan
  const handleNewFloorPlan = () => {
    if (confirm('Start a new floor plan? This will clear all current rooms.')) {
      const newPlan = {
        name: "New Floor Plan",
        scanDate: new Date().toISOString().split('T')[0],
        rooms: [],
        doors: [],
        exteriorDoors: [],
        windows: [],
      };
      setFloorPlan(newPlan);
      setHistory([JSON.stringify(newPlan)]);
      setHistoryIndex(0);
      setSelectedRoomId(null);
    }
  };

  // Import JSON
  const handleImport = (e) => {
    const file = e.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (event) => {
      try {
        const imported = JSON.parse(event.target.result);
        setFloorPlan(imported);
        saveToHistory(imported);
        setSelectedRoomId(null);
      } catch (err) {
        alert('Error importing file: ' + err.message);
      }
    };
    reader.readAsText(file);
    e.target.value = ''; // Reset input
  };

  // Export handlers
  const handleExport = (format) => {
    const exportData = { ...floorPlan, totalArea };
    switch (format) {
      case 'png':
        const canvas = document.querySelector('canvas');
        if (canvas) exportAsPNG(canvas, `${floorPlan.name.replace(/\s+/g, '-')}.png`);
        break;
      case 'pdf':
        exportAsPDF(exportData, `${floorPlan.name.replace(/\s+/g, '-')}.pdf`);
        break;
      case 'dxf':
        exportAsDXF(exportData, `${floorPlan.name.replace(/\s+/g, '-')}.dxf`);
        break;
      case 'json':
        exportAsJSON(exportData, `${floorPlan.name.replace(/\s+/g, '-')}.json`);
        break;
    }
  };

  const selectedRoom = floorPlan.rooms.find(r => r.id === selectedRoomId);

  return (
    <div className="app">
      {/* Header */}
      <header className="header">
        <div className="header-left">
          <h1>LiDAR Floor Plan</h1>
          <span className="scan-info">
            {floorPlan.name} - {floorPlan.scanDate}
          </span>
        </div>
        <div className="header-right">
          <div className="view-toggle">
            <button
              className={activeView === '2d' ? 'active' : ''}
              onClick={() => setActiveView('2d')}
            >
              2D Plan
            </button>
            <button
              className={activeView === '3d' ? 'active' : ''}
              onClick={() => setActiveView('3d')}
            >
              3D View
            </button>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <div className="main-content">
        {/* Sidebar */}
        <aside className="sidebar">
          {/* Edit Mode Toggle */}
          <div className="sidebar-section">
            <button
              onClick={() => setEditMode(!editMode)}
              className={`edit-mode-btn ${editMode ? 'active' : ''}`}
            >
              {editMode ? 'Exit Edit Mode' : 'Edit Mode'}
            </button>
          </div>

          {/* Edit Tools (when in edit mode) */}
          {editMode && (
            <div className="sidebar-section">
              <h3>Tools</h3>
              <div className="tool-buttons">
                <button onClick={() => setShowAddRoom(true)} className="tool-btn">
                  + Add Room
                </button>
                <button onClick={() => setShowAddDoor(true)} className="tool-btn">
                  + Add Door
                </button>
                <button onClick={() => setShowAddWindow(true)} className="tool-btn">
                  + Add Window
                </button>
              </div>
              <div className="tool-buttons" style={{ marginTop: '8px' }}>
                <button onClick={handleUndo} disabled={!canUndo} className="tool-btn small">
                  Undo
                </button>
                <button onClick={handleRedo} disabled={!canRedo} className="tool-btn small">
                  Redo
                </button>
              </div>
              <div className="tool-buttons" style={{ marginTop: '8px' }}>
                <button onClick={handleNewFloorPlan} className="tool-btn small danger">
                  New Plan
                </button>
              </div>
            </div>
          )}

          {/* Summary */}
          <div className="sidebar-section">
            <h3>Summary</h3>
            <div className="stat">
              <span>Total Area</span>
              <strong>{totalArea} sq ft</strong>
            </div>
            <div className="stat">
              <span>Rooms</span>
              <strong>{floorPlan.rooms.length}</strong>
            </div>
            <div className="stat">
              <span>Doors</span>
              <strong>{(floorPlan.doors?.length || 0) + (floorPlan.exteriorDoors?.length || 0)}</strong>
            </div>
            <div className="stat">
              <span>Windows</span>
              <strong>{floorPlan.windows?.length || 0}</strong>
            </div>
          </div>

          {/* Rooms */}
          <div className="sidebar-section">
            <h3>Rooms</h3>
            <ul className="room-list">
              {floorPlan.rooms.map(room => (
                <li
                  key={room.id}
                  className={selectedRoomId === room.id ? 'selected' : ''}
                  onClick={() => setSelectedRoomId(room.id)}
                  onDoubleClick={() => editMode && handleRoomDoubleClick(room)}
                >
                  <span className="room-color" style={{ background: room.color }}></span>
                  <div className="room-info">
                    <strong>{room.name}</strong>
                    <span>{room.width}' x {room.length}' ({room.width * room.length} sq ft)</span>
                  </div>
                </li>
              ))}
            </ul>
            {floorPlan.rooms.length === 0 && (
              <p style={{ color: '#888', fontSize: '13px', textAlign: 'center', padding: '10px' }}>
                No rooms yet. Enable Edit Mode to add rooms.
              </p>
            )}
          </div>

          {/* Selected Room Details */}
          {selectedRoom && editMode && (
            <div className="sidebar-section">
              <h3>Selected Room</h3>
              <div className="selected-room-details">
                <p><strong>{selectedRoom.name}</strong></p>
                <p>Position: ({selectedRoom.x}', {selectedRoom.z}')</p>
                <p>Size: {selectedRoom.width}' x {selectedRoom.length}'</p>
                <p>Area: {selectedRoom.width * selectedRoom.length} sq ft</p>
                <button
                  onClick={() => handleRoomDoubleClick(selectedRoom)}
                  className="tool-btn"
                  style={{ marginTop: '8px', width: '100%' }}
                >
                  Edit Room
                </button>
              </div>
            </div>
          )}

          {/* Options */}
          <div className="sidebar-section">
            <h3>Options</h3>
            <label className="checkbox-option">
              <input
                type="checkbox"
                checked={showDimensions}
                onChange={(e) => setShowDimensions(e.target.checked)}
              />
              Show Dimensions
            </label>
          </div>

          {/* Export */}
          <div className="sidebar-section">
            <h3>Export</h3>
            <div className="export-buttons">
              <button onClick={() => handleExport('png')} className="export-btn">
                PNG Image
              </button>
              <button onClick={() => handleExport('pdf')} className="export-btn">
                PDF Document
              </button>
              <button onClick={() => handleExport('dxf')} className="export-btn">
                DXF (AutoCAD)
              </button>
              <button onClick={() => handleExport('json')} className="export-btn">
                JSON Data
              </button>
            </div>
          </div>

          {/* Import */}
          <div className="sidebar-section">
            <h3>Import</h3>
            <label className="import-btn">
              Import JSON
              <input
                type="file"
                accept=".json"
                onChange={handleImport}
                style={{ display: 'none' }}
              />
            </label>
          </div>
        </aside>

        {/* Viewer Area */}
        <main className="viewer">
          {activeView === '2d' ? (
            <FloorPlan2D
              floorPlanData={floorPlan}
              editMode={editMode}
              selectedRoomId={selectedRoomId}
              onRoomSelect={setSelectedRoomId}
              onRoomUpdate={handleUpdateRoom}
              onRoomDoubleClick={handleRoomDoubleClick}
            />
          ) : (
            <Room3DViewer roomData={mockRoom} showDimensions={showDimensions} />
          )}
        </main>
      </div>

      {/* Footer */}
      <footer className="footer">
        <span>LiDAR Floor Plan - CAD Editor</span>
        <span>{editMode ? 'Edit Mode Active' : 'View Mode'}</span>
      </footer>

      {/* Modals */}
      <AddRoomModal
        isOpen={showAddRoom}
        onClose={() => setShowAddRoom(false)}
        onAdd={handleAddRoom}
        existingRooms={floorPlan.rooms}
      />

      <EditRoomModal
        isOpen={showEditRoom}
        room={editingRoom}
        onClose={() => { setShowEditRoom(false); setEditingRoom(null); }}
        onSave={handleSaveRoom}
        onDelete={handleDeleteRoom}
      />

      <AddDoorModal
        isOpen={showAddDoor}
        onClose={() => setShowAddDoor(false)}
        onAdd={handleAddDoor}
        rooms={floorPlan.rooms}
      />

      <AddWindowModal
        isOpen={showAddWindow}
        onClose={() => setShowAddWindow(false)}
        onAdd={handleAddWindow}
        rooms={floorPlan.rooms}
      />
    </div>
  );
}

export default App;
