import SwiftUI

struct ProfilesView: View {
    @ObservedObject var profileManager: ProfileManager
    @ObservedObject var displayManager: DisplayManager
    @ObservedObject var settings: AppSettings
    
    @State private var showingCreateSheet = false
    @State private var newProfileName = ""
    @State private var selectedAnchorID: CGDirectDisplayID = CGMainDisplayID()
    @State private var editingProfile: Profile?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label("Profiles", systemImage: "person.2.fill")
                    .font(.headline)
                
                Spacer()
                
                Toggle("Auto-switch", isOn: $settings.autoSwitchProfiles)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .help("Automatically switch profiles when display configuration changes")
                
                Button {
                    newProfileName = ""
                    selectedAnchorID = settings.anchorDisplayCGID
                    showingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .help("Create new profile")
            }
            
            if settings.autoSwitchProfiles {
                Text("Profiles will automatically switch when your display configuration changes.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Profile list
            if profileManager.profiles.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "rectangle.stack.badge.plus")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("No profiles yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Create a profile to save your display and anchor settings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(profileManager.profiles) { profile in
                        ProfileRowView(
                            profile: profile,
                            isActive: profileManager.activeProfile?.id == profile.id,
                            onActivate: {
                                profileManager.setActiveProfile(profile)
                            },
                            onEdit: {
                                editingProfile = profile
                            },
                            onDelete: {
                                profileManager.deleteProfile(profile)
                            },
                            onSetDefault: {
                                profileManager.setDefaultProfile(profile)
                            }
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            createProfileSheet
        }
        .sheet(item: $editingProfile) { profile in
            editProfileSheet(profile)
        }
    }
    
    // MARK: - Create Profile Sheet
    
    private var createProfileSheet: some View {
        VStack(spacing: 16) {
            Text("Create Profile")
                .font(.headline)
            
            TextField("Profile Name", text: $newProfileName)
                .textFieldStyle(.roundedBorder)
            
            Picker("Anchor Display", selection: $selectedAnchorID) {
                ForEach(displayManager.displays) { display in
                    Text(display.displayLabel).tag(display.displayID)
                }
            }
            
            Text("Current displays will be saved with this profile for auto-switching.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Button("Cancel") {
                    showingCreateSheet = false
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Create") {
                    let displayName = displayManager.display(for: selectedAnchorID)?.name ?? "Unknown"
                    let profile = profileManager.createProfile(
                        name: newProfileName,
                        anchorDisplayID: selectedAnchorID,
                        anchorDisplayName: displayName
                    )
                    profileManager.setActiveProfile(profile)
                    showingCreateSheet = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newProfileName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 350)
    }
    
    // MARK: - Edit Profile Sheet
    
    private func editProfileSheet(_ profile: Profile) -> some View {
        EditProfileView(
            profile: profile,
            displays: displayManager.displays,
            onSave: { updated in
                profileManager.updateProfile(updated)
                editingProfile = nil
            },
            onCancel: {
                editingProfile = nil
            }
        )
    }
}

// MARK: - Profile Row

private struct ProfileRowView: View {
    let profile: Profile
    let isActive: Bool
    let onActivate: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onSetDefault: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Active indicator
            Circle()
                .fill(isActive ? Color.accentColor : Color.clear)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(profile.name)
                        .font(.subheadline.weight(.medium))
                    
                    if profile.isDefault {
                        Text("Default")
                            .font(.caption2)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundColor(.accentColor)
                            .cornerRadius(4)
                    }
                }
                
                Text("Anchor: \(profile.anchorDisplayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !isActive {
                Button("Activate") {
                    onActivate()
                }
                .controlSize(.small)
            }
            
            Menu {
                Button("Edit…") { onEdit() }
                Button("Set as Default") { onSetDefault() }
                Divider()
                Button("Delete", role: .destructive) { onDelete() }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.secondary)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 24)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? Color.accentColor.opacity(0.08) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isActive ? Color.accentColor.opacity(0.2) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Edit Profile

private struct EditProfileView: View {
    @State var profile: Profile
    let displays: [DisplayInfo]
    let onSave: (Profile) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Edit Profile")
                .font(.headline)
            
            TextField("Profile Name", text: $profile.name)
                .textFieldStyle(.roundedBorder)
            
            Picker("Anchor Display", selection: $profile.anchorDisplayID) {
                ForEach(displays) { display in
                    Text(display.displayLabel).tag(display.displayID)
                }
            }
            
            HStack {
                Button("Cancel") { onCancel() }
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save") {
                    if let display = displays.first(where: { $0.displayID == profile.anchorDisplayID }) {
                        profile.anchorDisplayName = display.name
                    }
                    onSave(profile)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(profile.name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 350)
    }
}
