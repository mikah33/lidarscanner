import { useState } from 'react';

// Color palette for rooms
const ROOM_COLORS = [
  '#e8f4f8', '#f8f4e8', '#f4f8e8', '#e8e8f8', '#f8e8f4',
  '#f8e8e8', '#e8f8e8', '#e8f8f4', '#f4e8f8', '#f8f8e8'
];

export function AddRoomModal({ isOpen, onClose, onAdd, existingRooms }) {
  const [roomData, setRoomData] = useState({
    name: '',
    width: 12,
    length: 12,
    height: 9,
    x: 0,
    z: 0,
  });

  if (!isOpen) return null;

  const handleSubmit = (e) => {
    e.preventDefault();
    const newRoom = {
      id: `room-${Date.now()}`,
      name: roomData.name || `Room ${existingRooms.length + 1}`,
      x: parseFloat(roomData.x),
      z: parseFloat(roomData.z),
      width: parseFloat(roomData.width),
      length: parseFloat(roomData.length),
      height: parseFloat(roomData.height),
      color: ROOM_COLORS[existingRooms.length % ROOM_COLORS.length],
    };
    onAdd(newRoom);
    setRoomData({ name: '', width: 12, length: 12, height: 9, x: 0, z: 0 });
    onClose();
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={e => e.stopPropagation()}>
        <h2>Add New Room</h2>
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label>Room Name</label>
            <input
              type="text"
              value={roomData.name}
              onChange={e => setRoomData({ ...roomData, name: e.target.value })}
              placeholder="e.g., Living Room"
            />
          </div>

          <div className="form-row">
            <div className="form-group">
              <label>Width (ft)</label>
              <input
                type="number"
                value={roomData.width}
                onChange={e => setRoomData({ ...roomData, width: e.target.value })}
                min="1"
                step="0.5"
              />
            </div>
            <div className="form-group">
              <label>Length (ft)</label>
              <input
                type="number"
                value={roomData.length}
                onChange={e => setRoomData({ ...roomData, length: e.target.value })}
                min="1"
                step="0.5"
              />
            </div>
            <div className="form-group">
              <label>Height (ft)</label>
              <input
                type="number"
                value={roomData.height}
                onChange={e => setRoomData({ ...roomData, height: e.target.value })}
                min="1"
                step="0.5"
              />
            </div>
          </div>

          <div className="form-row">
            <div className="form-group">
              <label>X Position (ft)</label>
              <input
                type="number"
                value={roomData.x}
                onChange={e => setRoomData({ ...roomData, x: e.target.value })}
                step="0.5"
              />
            </div>
            <div className="form-group">
              <label>Y Position (ft)</label>
              <input
                type="number"
                value={roomData.z}
                onChange={e => setRoomData({ ...roomData, z: e.target.value })}
                step="0.5"
              />
            </div>
          </div>

          <div className="form-info">
            Area: {(roomData.width * roomData.length).toFixed(1)} sq ft
          </div>

          <div className="modal-buttons">
            <button type="button" className="btn-cancel" onClick={onClose}>Cancel</button>
            <button type="submit" className="btn-add">Add Room</button>
          </div>
        </form>
      </div>
    </div>
  );
}

export function EditRoomModal({ isOpen, room, onClose, onSave, onDelete }) {
  const [roomData, setRoomData] = useState(room || {});

  // Update local state when room prop changes
  if (room && room.id !== roomData.id) {
    setRoomData(room);
  }

  if (!isOpen || !room) return null;

  const handleSubmit = (e) => {
    e.preventDefault();
    onSave({
      ...room,
      name: roomData.name,
      width: parseFloat(roomData.width),
      length: parseFloat(roomData.length),
      height: parseFloat(roomData.height),
      x: parseFloat(roomData.x),
      z: parseFloat(roomData.z),
    });
    onClose();
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={e => e.stopPropagation()}>
        <h2>Edit Room</h2>
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label>Room Name</label>
            <input
              type="text"
              value={roomData.name || ''}
              onChange={e => setRoomData({ ...roomData, name: e.target.value })}
            />
          </div>

          <div className="form-row">
            <div className="form-group">
              <label>Width (ft)</label>
              <input
                type="number"
                value={roomData.width || 0}
                onChange={e => setRoomData({ ...roomData, width: e.target.value })}
                min="1"
                step="0.5"
              />
            </div>
            <div className="form-group">
              <label>Length (ft)</label>
              <input
                type="number"
                value={roomData.length || 0}
                onChange={e => setRoomData({ ...roomData, length: e.target.value })}
                min="1"
                step="0.5"
              />
            </div>
            <div className="form-group">
              <label>Height (ft)</label>
              <input
                type="number"
                value={roomData.height || 0}
                onChange={e => setRoomData({ ...roomData, height: e.target.value })}
                min="1"
                step="0.5"
              />
            </div>
          </div>

          <div className="form-row">
            <div className="form-group">
              <label>X Position (ft)</label>
              <input
                type="number"
                value={roomData.x || 0}
                onChange={e => setRoomData({ ...roomData, x: e.target.value })}
                step="0.5"
              />
            </div>
            <div className="form-group">
              <label>Y Position (ft)</label>
              <input
                type="number"
                value={roomData.z || 0}
                onChange={e => setRoomData({ ...roomData, z: e.target.value })}
                step="0.5"
              />
            </div>
          </div>

          <div className="form-info">
            Area: {((roomData.width || 0) * (roomData.length || 0)).toFixed(1)} sq ft
          </div>

          <div className="modal-buttons">
            <button type="button" className="btn-delete" onClick={() => { onDelete(room.id); onClose(); }}>
              Delete Room
            </button>
            <button type="button" className="btn-cancel" onClick={onClose}>Cancel</button>
            <button type="submit" className="btn-add">Save Changes</button>
          </div>
        </form>
      </div>
    </div>
  );
}

export function AddDoorModal({ isOpen, onClose, onAdd, rooms }) {
  const [doorData, setDoorData] = useState({
    fromRoom: '',
    toRoom: '',
    width: 3,
    x: 0,
    z: 0,
    isExterior: false,
    label: '',
  });

  if (!isOpen) return null;

  const handleSubmit = (e) => {
    e.preventDefault();
    if (doorData.isExterior) {
      onAdd({
        type: 'exterior',
        room: doorData.fromRoom,
        wall: 'custom',
        x: parseFloat(doorData.x),
        z: parseFloat(doorData.z),
        width: parseFloat(doorData.width),
        label: doorData.label || 'Door',
      });
    } else {
      onAdd({
        type: 'interior',
        from: doorData.fromRoom,
        to: doorData.toRoom,
        x: parseFloat(doorData.x),
        z: parseFloat(doorData.z),
        width: parseFloat(doorData.width),
      });
    }
    setDoorData({ fromRoom: '', toRoom: '', width: 3, x: 0, z: 0, isExterior: false, label: '' });
    onClose();
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={e => e.stopPropagation()}>
        <h2>Add Door</h2>
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label className="checkbox-label">
              <input
                type="checkbox"
                checked={doorData.isExterior}
                onChange={e => setDoorData({ ...doorData, isExterior: e.target.checked })}
              />
              Exterior Door
            </label>
          </div>

          <div className="form-group">
            <label>{doorData.isExterior ? 'Room' : 'From Room'}</label>
            <select
              value={doorData.fromRoom}
              onChange={e => setDoorData({ ...doorData, fromRoom: e.target.value })}
              required
            >
              <option value="">Select room...</option>
              {rooms.map(room => (
                <option key={room.id} value={room.id}>{room.name}</option>
              ))}
            </select>
          </div>

          {!doorData.isExterior && (
            <div className="form-group">
              <label>To Room</label>
              <select
                value={doorData.toRoom}
                onChange={e => setDoorData({ ...doorData, toRoom: e.target.value })}
                required
              >
                <option value="">Select room...</option>
                {rooms.filter(r => r.id !== doorData.fromRoom).map(room => (
                  <option key={room.id} value={room.id}>{room.name}</option>
                ))}
              </select>
            </div>
          )}

          {doorData.isExterior && (
            <div className="form-group">
              <label>Label</label>
              <input
                type="text"
                value={doorData.label}
                onChange={e => setDoorData({ ...doorData, label: e.target.value })}
                placeholder="e.g., Front Entry"
              />
            </div>
          )}

          <div className="form-row">
            <div className="form-group">
              <label>Width (ft)</label>
              <input
                type="number"
                value={doorData.width}
                onChange={e => setDoorData({ ...doorData, width: e.target.value })}
                min="2"
                max="12"
                step="0.5"
              />
            </div>
            <div className="form-group">
              <label>X Position (ft)</label>
              <input
                type="number"
                value={doorData.x}
                onChange={e => setDoorData({ ...doorData, x: e.target.value })}
                step="0.5"
              />
            </div>
            <div className="form-group">
              <label>Y Position (ft)</label>
              <input
                type="number"
                value={doorData.z}
                onChange={e => setDoorData({ ...doorData, z: e.target.value })}
                step="0.5"
              />
            </div>
          </div>

          <div className="modal-buttons">
            <button type="button" className="btn-cancel" onClick={onClose}>Cancel</button>
            <button type="submit" className="btn-add">Add Door</button>
          </div>
        </form>
      </div>
    </div>
  );
}

export function AddWindowModal({ isOpen, onClose, onAdd, rooms }) {
  const [windowData, setWindowData] = useState({
    room: '',
    wall: 'north',
    width: 4,
    x: 0,
    z: 0,
  });

  if (!isOpen) return null;

  const handleSubmit = (e) => {
    e.preventDefault();
    onAdd({
      room: windowData.room,
      wall: windowData.wall,
      x: parseFloat(windowData.x),
      z: parseFloat(windowData.z),
      width: parseFloat(windowData.width),
    });
    setWindowData({ room: '', wall: 'north', width: 4, x: 0, z: 0 });
    onClose();
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={e => e.stopPropagation()}>
        <h2>Add Window</h2>
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label>Room</label>
            <select
              value={windowData.room}
              onChange={e => setWindowData({ ...windowData, room: e.target.value })}
              required
            >
              <option value="">Select room...</option>
              {rooms.map(room => (
                <option key={room.id} value={room.id}>{room.name}</option>
              ))}
            </select>
          </div>

          <div className="form-row">
            <div className="form-group">
              <label>Width (ft)</label>
              <input
                type="number"
                value={windowData.width}
                onChange={e => setWindowData({ ...windowData, width: e.target.value })}
                min="1"
                max="20"
                step="0.5"
              />
            </div>
            <div className="form-group">
              <label>X Position (ft)</label>
              <input
                type="number"
                value={windowData.x}
                onChange={e => setWindowData({ ...windowData, x: e.target.value })}
                step="0.5"
              />
            </div>
            <div className="form-group">
              <label>Y Position (ft)</label>
              <input
                type="number"
                value={windowData.z}
                onChange={e => setWindowData({ ...windowData, z: e.target.value })}
                step="0.5"
              />
            </div>
          </div>

          <div className="modal-buttons">
            <button type="button" className="btn-cancel" onClick={onClose}>Cancel</button>
            <button type="submit" className="btn-add">Add Window</button>
          </div>
        </form>
      </div>
    </div>
  );
}
