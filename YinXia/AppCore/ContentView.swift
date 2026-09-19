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
    @State private var showMiniPlayer = true
    
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
            .padding(.bottom, (playerService.currentTrack != nil && showMiniPlayer) ? 56 : 0)
            
            // Mini player - 仅在 showMiniPlayer 为 true 时显示
            if playerService.currentTrack != nil && showMiniPlayer {
                MiniPlayerBar()
                    .environmentObject(playerService)
            }
        }
        .environmentObject(playerService)
        .environment(\.showMiniPlayer, $showMiniPlayer)
    }
}

// 环境键用于控制 mini player 显示
struct ShowMiniPlayerKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(true)
}

extension EnvironmentValues {
    var showMiniPlayer: Binding<Bool> {
        get { self[ShowMiniPlayerKey.self] }
        set { self[ShowMiniPlayerKey.self] = newValue }
    }
}
