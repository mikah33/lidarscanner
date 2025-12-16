import { jsPDF } from 'jspdf';

// Export floor plan as PNG
export function exportAsPNG(canvasElement, filename = 'floor-plan.png') {
  const link = document.createElement('a');
  link.download = filename;
  link.href = canvasElement.toDataURL('image/png');
  link.click();
}

// Export floor plan as PDF with dimensions
export function exportAsPDF(floorPlanData, filename = 'floor-plan.pdf') {
  const pdf = new jsPDF('landscape', 'in', 'letter');

  const pageWidth = 11;
  const pageHeight = 8.5;
  const margin = 0.5;

  // Calculate scale to fit on page
  const maxX = Math.max(...floorPlanData.rooms.map(r => r.x + r.width));
  const maxZ = Math.max(...floorPlanData.rooms.map(r => r.z + r.length));
  const scale = Math.min(
    (pageWidth - margin * 2) / maxX,
    (pageHeight - margin * 2 - 1) / maxZ
  ) * 0.9;

  // Title
  pdf.setFontSize(18);
  pdf.setFont('helvetica', 'bold');
  pdf.text(floorPlanData.name, pageWidth / 2, margin, { align: 'center' });

  // Date
  pdf.setFontSize(10);
  pdf.setFont('helvetica', 'normal');
  pdf.text(`Generated: ${new Date().toLocaleDateString()}`, pageWidth / 2, margin + 0.3, { align: 'center' });

  const offsetX = margin + 0.5;
  const offsetY = margin + 0.8;

  // Draw rooms
  floorPlanData.rooms.forEach(room => {
    const x = room.x * scale + offsetX;
    const y = room.z * scale + offsetY;
    const width = room.width * scale;
    const height = room.length * scale;

    // Room outline
    pdf.setDrawColor(0);
    pdf.setLineWidth(0.02);
    pdf.rect(x, y, width, height);

    // Room name
    pdf.setFontSize(10);
    pdf.setFont('helvetica', 'bold');
    pdf.text(room.name, x + width / 2, y + height / 2 - 0.15, { align: 'center' });

    // Dimensions
    pdf.setFontSize(8);
    pdf.setFont('helvetica', 'normal');
    pdf.text(`${room.width}' × ${room.length}'`, x + width / 2, y + height / 2 + 0.05, { align: 'center' });

    // Area
    pdf.setFontSize(7);
    pdf.text(`${room.width * room.length} sq ft`, x + width / 2, y + height / 2 + 0.2, { align: 'center' });
  });

  // Draw dimension lines for overall
  pdf.setDrawColor(255, 0, 0);
  pdf.setLineWidth(0.01);

  // Width dimension
  const totalWidth = maxX * scale;
  const dimY = maxZ * scale + offsetY + 0.3;
  pdf.line(offsetX, dimY, offsetX + totalWidth, dimY);
  pdf.line(offsetX, dimY - 0.1, offsetX, dimY + 0.1);
  pdf.line(offsetX + totalWidth, dimY - 0.1, offsetX + totalWidth, dimY + 0.1);
  pdf.setTextColor(255, 0, 0);
  pdf.text(`${maxX}' 0"`, offsetX + totalWidth / 2, dimY + 0.2, { align: 'center' });

  // Height dimension
  const dimX = maxX * scale + offsetX + 0.3;
  pdf.line(dimX, offsetY, dimX, offsetY + maxZ * scale);
  pdf.line(dimX - 0.1, offsetY, dimX + 0.1, offsetY);
  pdf.line(dimX - 0.1, offsetY + maxZ * scale, dimX + 0.1, offsetY + maxZ * scale);
  pdf.text(`${maxZ}' 0"`, dimX + 0.3, offsetY + (maxZ * scale) / 2, { angle: 90 });

  // Reset text color
  pdf.setTextColor(0);

  // Footer with total area
  pdf.setFontSize(12);
  pdf.text(`Total Area: ${floorPlanData.totalArea} sq ft`, margin, pageHeight - margin);

  // Scale note
  pdf.setFontSize(8);
  pdf.text(`Scale: 1" = ${(1 / scale).toFixed(1)}'`, pageWidth - margin, pageHeight - margin, { align: 'right' });

  pdf.save(filename);
}

// Export as DXF (AutoCAD format)
export function exportAsDXF(floorPlanData, filename = 'floor-plan.dxf') {
  // DXF file format - basic structure
  let dxf = '';

  // Header section
  dxf += '0\nSECTION\n2\nHEADER\n';
  dxf += '9\n$ACADVER\n1\nAC1015\n'; // AutoCAD 2000 format
  dxf += '9\n$INSUNITS\n70\n2\n'; // Units = feet
  dxf += '0\nENDSEC\n';

  // Tables section (layers)
  dxf += '0\nSECTION\n2\nTABLES\n';
  dxf += '0\nTABLE\n2\nLAYER\n';

  // Define layers
  const layers = ['WALLS', 'DOORS', 'WINDOWS', 'DIMENSIONS', 'TEXT'];
  layers.forEach((layer, i) => {
    dxf += '0\nLAYER\n';
    dxf += `2\n${layer}\n`;
    dxf += '70\n0\n';
    dxf += `62\n${i + 1}\n`; // Color
    dxf += '6\nCONTINUOUS\n';
  });

  dxf += '0\nENDTAB\n';
  dxf += '0\nENDSEC\n';

  // Entities section
  dxf += '0\nSECTION\n2\nENTITIES\n';

  // Draw room outlines
  floorPlanData.rooms.forEach(room => {
    const x1 = room.x;
    const y1 = room.z;
    const x2 = room.x + room.width;
    const y2 = room.z + room.length;

    // Four lines for room boundary
    // Bottom
    dxf += `0\nLINE\n8\nWALLS\n`;
    dxf += `10\n${x1}\n20\n${y1}\n30\n0\n`;
    dxf += `11\n${x2}\n21\n${y1}\n31\n0\n`;

    // Right
    dxf += `0\nLINE\n8\nWALLS\n`;
    dxf += `10\n${x2}\n20\n${y1}\n30\n0\n`;
    dxf += `11\n${x2}\n21\n${y2}\n31\n0\n`;

    // Top
    dxf += `0\nLINE\n8\nWALLS\n`;
    dxf += `10\n${x2}\n20\n${y2}\n30\n0\n`;
    dxf += `11\n${x1}\n21\n${y2}\n31\n0\n`;

    // Left
    dxf += `0\nLINE\n8\nWALLS\n`;
    dxf += `10\n${x1}\n20\n${y2}\n30\n0\n`;
    dxf += `11\n${x1}\n21\n${y1}\n31\n0\n`;

    // Room name text
    dxf += `0\nTEXT\n8\nTEXT\n`;
    dxf += `10\n${room.x + room.width / 2}\n`;
    dxf += `20\n${room.z + room.length / 2}\n`;
    dxf += `30\n0\n`;
    dxf += `40\n1\n`; // Text height
    dxf += `1\n${room.name}\n`;
    dxf += `72\n1\n`; // Horizontal center
    dxf += `73\n2\n`; // Vertical center
    dxf += `11\n${room.x + room.width / 2}\n`;
    dxf += `21\n${room.z + room.length / 2}\n`;
    dxf += `31\n0\n`;

    // Dimension text
    dxf += `0\nTEXT\n8\nDIMENSIONS\n`;
    dxf += `10\n${room.x + room.width / 2}\n`;
    dxf += `20\n${room.z + room.length / 2 - 2}\n`;
    dxf += `30\n0\n`;
    dxf += `40\n0.7\n`;
    dxf += `1\n${room.width}' x ${room.length}'\n`;
    dxf += `72\n1\n`;
    dxf += `73\n2\n`;
    dxf += `11\n${room.x + room.width / 2}\n`;
    dxf += `21\n${room.z + room.length / 2 - 2}\n`;
    dxf += `31\n0\n`;
  });

  // Draw doors
  floorPlanData.doors?.forEach(door => {
    dxf += `0\nLINE\n8\nDOORS\n`;
    dxf += `10\n${door.x - 0.5}\n20\n${door.z - door.width / 2}\n30\n0\n`;
    dxf += `11\n${door.x + 0.5}\n21\n${door.z + door.width / 2}\n31\n0\n`;
  });

  dxf += '0\nENDSEC\n';
  dxf += '0\nEOF\n';

  // Download the file
  const blob = new Blob([dxf], { type: 'application/dxf' });
  const link = document.createElement('a');
  link.href = URL.createObjectURL(blob);
  link.download = filename;
  link.click();
}

// Export room data as JSON (for backup/transfer)
export function exportAsJSON(data, filename = 'floor-plan-data.json') {
  const jsonStr = JSON.stringify(data, null, 2);
  const blob = new Blob([jsonStr], { type: 'application/json' });
  const link = document.createElement('a');
  link.href = URL.createObjectURL(blob);
  link.download = filename;
  link.click();
}
