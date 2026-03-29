import Foundation

struct Profile: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var anchorDisplayID: UInt32
    var anchorDisplayName: String
    var connectedDisplaySignature: String  // Hash of connected display IDs for auto-switching
    var createdAt: Date
    var isDefault: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        anchorDisplayID: UInt32,
        anchorDisplayName: String,
        connectedDisplaySignature: String = "",
        createdAt: Date = Date(),
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.anchorDisplayID = anchorDisplayID
        self.anchorDisplayName = anchorDisplayName
        self.connectedDisplaySignature = connectedDisplaySignature
        self.createdAt = createdAt
        self.isDefault = isDefault
    }
    
    /// Generate a signature from a set of display IDs for matching profiles to display configurations
    static func generateSignature(from displayIDs: [UInt32]) -> String {
        let sorted = displayIDs.sorted()
        return sorted.map { String($0) }.joined(separator: "-")
    }
}
