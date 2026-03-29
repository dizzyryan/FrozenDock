import Foundation
import Combine

final class ProfileManager: ObservableObject {
    static let shared = ProfileManager()
    
    @Published var profiles: [Profile] = []
    @Published var activeProfile: Profile?
    
    private let settings = AppSettings.shared
    private let displayManager = DisplayManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadProfiles()
        setupDisplayChangeObserver()
    }
    
    // MARK: - CRUD
    
    func createProfile(name: String, anchorDisplayID: UInt32, anchorDisplayName: String) -> Profile {
        let signature = Profile.generateSignature(from: displayManager.displayIDs)
        let profile = Profile(
            name: name,
            anchorDisplayID: anchorDisplayID,
            anchorDisplayName: anchorDisplayName,
            connectedDisplaySignature: signature,
            isDefault: profiles.isEmpty
        )
        profiles.append(profile)
        saveProfiles()
        return profile
    }
    
    func updateProfile(_ profile: Profile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
            saveProfiles()
            if activeProfile?.id == profile.id {
                activeProfile = profile
            }
        }
    }
    
    func deleteProfile(_ profile: Profile) {
        profiles.removeAll { $0.id == profile.id }
        if activeProfile?.id == profile.id {
            activeProfile = profiles.first(where: { $0.isDefault }) ?? profiles.first
        }
        saveProfiles()
    }
    
    func setActiveProfile(_ profile: Profile) {
        activeProfile = profile
        settings.activeProfileID = profile.id.uuidString
        
        // Apply the profile's anchor display
        settings.anchorDisplayCGID = profile.anchorDisplayID
        DockProtectionService.shared.updateAnchorDisplay(profile.anchorDisplayID)
    }
    
    func setDefaultProfile(_ profile: Profile) {
        for i in profiles.indices {
            profiles[i].isDefault = (profiles[i].id == profile.id)
        }
        saveProfiles()
    }
    
    // MARK: - Auto-switching
    
    func autoSwitchProfile() {
        guard settings.autoSwitchProfiles else { return }
        
        let currentSignature = displayManager.displaySignature
        if let matching = profiles.first(where: { $0.connectedDisplaySignature == currentSignature }) {
            if activeProfile?.id != matching.id {
                setActiveProfile(matching)
            }
        }
    }
    
    /// Update the current profile's display signature to match current displays
    func updateCurrentProfileSignature() {
        guard var profile = activeProfile else { return }
        profile.connectedDisplaySignature = displayManager.displaySignature
        updateProfile(profile)
    }
    
    // MARK: - Persistence
    
    private func loadProfiles() {
        guard let data = UserDefaults.standard.data(forKey: Constants.Keys.profiles) else { return }
        do {
            profiles = try JSONDecoder().decode([Profile].self, from: data)
            
            // Restore active profile
            if let activeID = UUID(uuidString: settings.activeProfileID) {
                activeProfile = profiles.first(where: { $0.id == activeID })
            }
            if activeProfile == nil {
                activeProfile = profiles.first(where: { $0.isDefault }) ?? profiles.first
            }
        } catch {
            print("Failed to load profiles: \(error)")
        }
    }
    
    private func saveProfiles() {
        do {
            let data = try JSONEncoder().encode(profiles)
            UserDefaults.standard.set(data, forKey: Constants.Keys.profiles)
        } catch {
            print("Failed to save profiles: \(error)")
        }
    }
    
    // MARK: - Display Change Observer
    
    private func setupDisplayChangeObserver() {
        NotificationCenter.default.publisher(for: .displaysChanged)
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.autoSwitchProfile()
            }
            .store(in: &cancellables)
    }
}
