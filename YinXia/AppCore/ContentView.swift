import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if appState.isLoggedIn {
                MainTabView()
                    .environmentObject(appState)
            } else {
                ServicePickerView()
                    .environmentObject(appState)
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var playerService: PlayerService
    
    init() {
        _playerService = StateObject(wrappedValue: PlayerService.shared)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                SearchView()
                    .tabItem {
                        Label("搜索", systemImage: "magnifyingglass")
                    }
                
                LibraryView()
                    .tabItem {
                        Label("曲库", systemImage: "music.note.list")
                    }
                
                SettingsView()
                    .tabItem {
                        Label("设置", systemImage: "gearshape")
                    }
            }
            .padding(.bottom, playerService.currentTrack != nil ? 56 : 0)
            
            if playerService.currentTrack != nil {
                MiniPlayerBar()
                    .environmentObject(playerService)
            }
        }
        .environmentObject(playerService)
    }
}
