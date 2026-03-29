import Foundation
import AppKit
import Combine

final class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()
    
    @Published var updateAvailable: Bool = false
    @Published var latestVersion: String?
    @Published var releaseURL: URL?
    @Published var isChecking: Bool = false
    @Published var lastCheckDate: Date?
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    struct GitHubRelease: Codable {
        let tagName: String
        let htmlUrl: String
        let name: String?
        let body: String?
        
        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case htmlUrl = "html_url"
            case name
            case body
        }
    }
    
    /// Check for updates from GitHub releases
    func checkForUpdates() {
        guard !isChecking else { return }
        guard let url = URL(string: Constants.githubReleasesURL) else { return }
        
        isChecking = true
        errorMessage = nil
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: GitHubRelease.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isChecking = false
                    self?.lastCheckDate = Date()
                    if case .failure(let error) = completion {
                        self?.errorMessage = "Update check failed: \(error.localizedDescription)"
                        self?.updateAvailable = false
                    }
                },
                receiveValue: { [weak self] release in
                    let remoteVersion = release.tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
                    self?.latestVersion = remoteVersion
                    self?.releaseURL = URL(string: release.htmlUrl)
                    self?.updateAvailable = self?.isNewerVersion(remoteVersion) ?? false
                }
            )
            .store(in: &cancellables)
    }
    
    /// Compare version strings (semantic versioning)
    private func isNewerVersion(_ remote: String) -> Bool {
        let current = Constants.appVersion
        return current.compare(remote, options: .numeric) == .orderedAscending
    }
    
    /// Open the release page in the default browser
    func openReleasePage() {
        if let url = releaseURL {
            NSWorkspace.shared.open(url)
        }
    }
}
