import SwiftUI

struct DisplayMapView: View {
    @ObservedObject var displayManager: DisplayManager
    let anchorDisplayID: CGDirectDisplayID
    var onSelectDisplay: ((DisplayInfo) -> Void)?
    
    private let mapPadding: CGFloat = 24
    private let minDisplayWidth: CGFloat = 100
    
    var body: some View {
        GeometryReader { geometry in
            let layout = calculateLayout(in: geometry.size)
            
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.windowBackgroundColor).opacity(0.5))
                
                if displayManager.displays.isEmpty {
                    Text("No displays detected")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(displayManager.displays) { display in
                        let rect = layout.rect(for: display)
                        
                        DisplayRectView(
                            display: display,
                            isAnchor: display.displayID == anchorDisplayID,
                            rect: rect
                        )
                        .onTapGesture {
                            onSelectDisplay?(display)
                        }
                    }
                }
            }
        }
        .frame(minHeight: 180)
    }
    
    // MARK: - Layout Calculation
    
    private func calculateLayout(in size: CGSize) -> DisplayLayout {
        let displays = displayManager.displays
        guard !displays.isEmpty else {
            return DisplayLayout(scale: 1, offsetX: 0, offsetY: 0)
        }
        
        // Find the bounding box of all displays in CG coordinates
        let minX = displays.map { CGFloat($0.originX) }.min() ?? 0
        let minY = displays.map { CGFloat($0.originY) }.min() ?? 0
        let maxX = displays.map { CGFloat($0.originX + $0.width) }.max() ?? 1
        let maxY = displays.map { CGFloat($0.originY + $0.height) }.max() ?? 1
        
        let totalWidth = maxX - minX
        let totalHeight = maxY - minY
        
        let availableWidth = size.width - mapPadding * 2
        let availableHeight = size.height - mapPadding * 2
        
        let scaleX = availableWidth / totalWidth
        let scaleY = availableHeight / totalHeight
        let scale = min(scaleX, scaleY)
        
        // Center the layout
        let scaledWidth = totalWidth * scale
        let scaledHeight = totalHeight * scale
        let offsetX = (size.width - scaledWidth) / 2 - minX * scale
        let offsetY = (size.height - scaledHeight) / 2 - minY * scale
        
        return DisplayLayout(scale: scale, offsetX: offsetX, offsetY: offsetY)
    }
}

private struct DisplayLayout {
    let scale: CGFloat
    let offsetX: CGFloat
    let offsetY: CGFloat
    
    func rect(for display: DisplayInfo) -> CGRect {
        CGRect(
            x: CGFloat(display.originX) * scale + offsetX,
            y: CGFloat(display.originY) * scale + offsetY,
            width: CGFloat(display.width) * scale,
            height: CGFloat(display.height) * scale
        )
    }
}

private struct DisplayRectView: View {
    let display: DisplayInfo
    let isAnchor: Bool
    let rect: CGRect
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(isAnchor ? Color.accentColor.opacity(0.15) : Color(.controlBackgroundColor))
            
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isAnchor ? Color.accentColor : Color.secondary.opacity(0.4), lineWidth: isAnchor ? 2.5 : 1.5)
            
            VStack(spacing: 4) {
                Text(display.name)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                
                Text(display.resolution)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if display.isPrimary {
                    Text("Primary")
                        .font(.caption2.weight(.medium))
                        .foregroundColor(.blue)
                }
                
                if isAnchor {
                    HStack(spacing: 2) {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                        Text("Anchor")
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundColor(.accentColor)
                }
            }
            .padding(6)
        }
        .frame(width: max(rect.width, 80), height: max(rect.height, 50))
        .position(x: rect.midX, y: rect.midY)
        .help(display.displayLabel)
    }
}

#Preview {
    DisplayMapView(
        displayManager: DisplayManager.shared,
        anchorDisplayID: CGMainDisplayID()
    )
    .frame(width: 500, height: 250)
    .padding()
}
