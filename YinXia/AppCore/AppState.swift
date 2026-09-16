import Foundation
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentServer: String?
    @Published var username: String?
    
    let authService: AuthService
    let subsonicAPI: SubsonicAPI
    let playerService: PlayerService
    
    init() {
        self.authService = AuthService()
        self.subsonicAPI = SubsonicAPI()
        self.playerService = PlayerService()
        
        checkLoginStatus()
    }
    
    func checkLoginStatus() {
        if let credentials = authService.loadCredentials() {
            self.currentServer = credentials.serverURL
            self.username = credentials.username
            self.isLoggedIn = true
            subsonicAPI.configure(credentials: credentials)
        }
    }
    
    func login(serverURL: String, username: String, password: String) async throws {
        let credentials = ServerCredentials(
            serverURL: serverURL,
            username: username,
            password: password
        )
        
        try await subsonicAPI.ping(credentials: credentials)
        
        try authService.saveCredentials(credentials)
        
        self.currentServer = serverURL
        self.username = username
        self.isLoggedIn = true
        subsonicAPI.configure(credentials: credentials)
    }
    
    func logout() {
        authService.clearCredentials()
        self.isLoggedIn = false
        self.currentServer = nil
        self.username = nil
        subsonicAPI.configure(credentials: nil)
        playerService.stop()
    }
}
