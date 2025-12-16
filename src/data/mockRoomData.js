// Mock room data simulating LiDAR scan output
// All measurements in feet for contractor familiarity

export const mockRoom = {
  name: "Living Room Scan",
  scanDate: "2024-12-15",

  // Room boundaries (feet)
  dimensions: {
    width: 18,    // X axis
    length: 24,   // Z axis
    height: 9,    // Y axis
  },

  // Walls defined by start/end points and features
  walls: [
    {
      id: 'wall-north',
      name: 'North Wall',
      start: { x: 0, z: 0 },
      end: { x: 18, z: 0 },
      length: 18,
      height: 9,
      features: [
        { type: 'window', x: 3, width: 4, height: 5, fromFloor: 3 },
        { type: 'window', x: 11, width: 4, height: 5, fromFloor: 3 },
      ]
    },
    {
      id: 'wall-east',
      name: 'East Wall',
      start: { x: 18, z: 0 },
      end: { x: 18, z: 24 },
      length: 24,
      height: 9,
      features: [
        { type: 'door', x: 8, width: 3, height: 7, fromFloor: 0 },
      ]
    },
    {
      id: 'wall-south',
      name: 'South Wall',
      start: { x: 18, z: 24 },
      end: { x: 0, z: 24 },
      length: 18,
      height: 9,
      features: [
        { type: 'window', x: 7, width: 4, height: 5, fromFloor: 3 },
      ]
    },
    {
      id: 'wall-west',
      name: 'West Wall',
      start: { x: 0, z: 24 },
      end: { x: 0, z: 0 },
      length: 24,
      height: 9,
      features: [
        { type: 'door', x: 4, width: 6, height: 7, fromFloor: 0, notes: 'Double door to patio' },
      ]
    },
  ],

  // Additional room elements
  elements: [
    { type: 'outlet', wall: 'wall-north', x: 1, fromFloor: 1.5 },
    { type: 'outlet', wall: 'wall-north', x: 17, fromFloor: 1.5 },
    { type: 'outlet', wall: 'wall-east', x: 2, fromFloor: 1.5 },
    { type: 'outlet', wall: 'wall-south', x: 3, fromFloor: 1.5 },
    { type: 'outlet', wall: 'wall-west', x: 20, fromFloor: 1.5 },
    { type: 'light-switch', wall: 'wall-east', x: 11.5, fromFloor: 4 },
  ],

  // Calculated properties
  get area() {
    return this.dimensions.width * this.dimensions.length;
  },

  get perimeter() {
    return (this.dimensions.width + this.dimensions.length) * 2;
  },

  get volume() {
    return this.dimensions.width * this.dimensions.length * this.dimensions.height;
  }
};

// Multiple room example for floor plan
export const mockFloorPlan = {
  name: "First Floor Scan",
  scanDate: "2024-12-15",
  rooms: [
    {
      id: 'living-room',
      name: 'Living Room',
      x: 0,
      z: 0,
      width: 18,
      length: 24,
      height: 9,
      color: '#e8f4f8',
    },
    {
      id: 'kitchen',
      name: 'Kitchen',
      x: 18,
      z: 0,
      width: 14,
      length: 12,
      height: 9,
      color: '#f8f4e8',
    },
    {
      id: 'dining',
      name: 'Dining Room',
      x: 18,
      z: 12,
      width: 14,
      length: 12,
      height: 9,
      color: '#f4f8e8',
    },
    {
      id: 'bathroom',
      name: 'Bathroom',
      x: 32,
      z: 0,
      width: 8,
      length: 10,
      height: 9,
      color: '#e8e8f8',
    },
    {
      id: 'bedroom',
      name: 'Master Bedroom',
      x: 32,
      z: 10,
      width: 14,
      length: 14,
      height: 9,
      color: '#f8e8f4',
    },
  ],

  // Doors connecting rooms
  doors: [
    { from: 'living-room', to: 'kitchen', x: 18, z: 6, width: 3 },
    { from: 'kitchen', to: 'dining', x: 22, z: 12, width: 4 },
    { from: 'dining', to: 'bedroom', x: 32, z: 18, width: 3 },
    { from: 'bathroom', to: 'bedroom', x: 32, z: 10, width: 2.5 },
  ],

  // External doors
  exteriorDoors: [
    { room: 'living-room', wall: 'west', x: 0, z: 10, width: 6, label: 'Front Entry' },
  ],

  // Windows
  windows: [
    { room: 'living-room', wall: 'north', x: 3, z: 0, width: 4 },
    { room: 'living-room', wall: 'north', x: 11, z: 0, width: 4 },
    { room: 'kitchen', wall: 'north', x: 22, z: 0, width: 5 },
    { room: 'bedroom', wall: 'east', x: 46, z: 15, width: 6 },
  ],

  get totalArea() {
    return this.rooms.reduce((sum, room) => sum + (room.width * room.length), 0);
  }
};
