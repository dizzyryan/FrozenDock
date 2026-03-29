import SwiftUI

struct StatusBadgeView: View {
    let isActive: Bool
    var size: CGFloat = 10
    
    var body: some View {
        Circle()
            .fill(isActive ? Color.green : Color.red)
            .frame(width: size, height: size)
            .shadow(color: isActive ? .green.opacity(0.5) : .red.opacity(0.5), radius: 3)
    }
}

struct ProtectionStatusView: View {
    @ObservedObject var protectionService: DockProtectionService
    
    var body: some View {
        HStack(spacing: 12) {
            StatusBadgeView(isActive: protectionService.isProtecting, size: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(protectionService.isProtecting ? "Protection Active" : "Protection Inactive")
                    .font(.headline)
                    .foregroundColor(protectionService.isProtecting ? .green : .secondary)
                
                Text(protectionService.statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if protectionService.blockedEventsCount > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(protectionService.blockedEventsCount)")
                        .font(.title3.monospacedDigit())
                        .fontWeight(.semibold)
                    Text("blocked")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(protectionService.isProtecting
                      ? Color.green.opacity(0.08)
                      : Color.secondary.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(protectionService.isProtecting
                              ? Color.green.opacity(0.2)
                              : Color.secondary.opacity(0.15), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        StatusBadgeView(isActive: true)
        StatusBadgeView(isActive: false)
    }
    .padding()
}
