import SwiftUI

struct PlaylistView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = PlaylistViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error)
                } else if viewModel.playlists.isEmpty {
                    EmptyView(message: "暂无歌单")
                } else {
                    playlistList
                }
            }
            .navigationTitle("歌单")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await viewModel.loadPlaylists(api: appState.subsonicAPI)
        }
        .refreshable {
            await viewModel.loadPlaylists(api: appState.subsonicAPI)
        }
    }
    
    private var playlistList: some View {
        List(viewModel.playlists) { playlist in
            NavigationLink(destination: PlaylistDetailView(playlistId: playlist.id)) {
                PlaylistRow(playlist: playlist, api: appState.subsonicAPI)
            }
        }
        .listStyle(.plain)
    }
}

struct PlaylistRow: View {
    let playlist: Playlist
    let api: SubsonicAPI
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: api.getCoverArtURL(id: playlist.coverArt ?? playlist.id, size: 200) ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 60, height: 60)
            .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.system(size: 16, weight: .medium))
                    .lineLimit(1)
                
                Text("\(playlist.songCount) 首歌曲")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct PlaylistDetailView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var playerService: PlayerService
    @StateObject private var viewModel = PlaylistDetailViewModel()
    
    let playlistId: String
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error)
            } else if let playlist = viewModel.playlist {
                playlistDetail(playlist)
            }
        }
        .task {
            await viewModel.loadPlaylist(id: playlistId, api: appState.subsonicAPI)
        }
        .navigationTitle(viewModel.playlist?.name ?? "歌单")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func playlistDetail(_ playlist: PlaylistDetail) -> some View {
        VStack(spacing: 0) {
            Button(action: {
                playerService.playAlbum(playlist.entry, api: appState.subsonicAPI)
            }) {
                Text("播放全部")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            
            List(Array(playlist.entry.enumerated()), id: \.element.id) { index, song in
                SongRow(song: song, index: index + 1)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        playerService.playAlbum(playlist.entry, api: appState.subsonicAPI, startIndex: index)
                    }
            }
            .listStyle(.plain)
        }
    }
}

@MainActor
class PlaylistViewModel: ObservableObject {
    @Published var playlists: [Playlist] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadPlaylists(api: SubsonicAPI) async {
        isLoading = true
        errorMessage = nil
        
        do {
            playlists = try await api.getPlaylists()
        } catch SubsonicError.networkUnavailable {
            errorMessage = "网络不可用"
        } catch SubsonicError.connectionFailed {
            errorMessage = "无法连接"
        } catch {
            errorMessage = "加载失败"
        }
        
        isLoading = false
    }
}

@MainActor
class PlaylistDetailViewModel: ObservableObject {
    @Published var playlist: PlaylistDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadPlaylist(id: String, api: SubsonicAPI) async {
        isLoading = true
        errorMessage = nil
        
        do {
            playlist = try await api.getPlaylist(id: id)
        } catch SubsonicError.networkUnavailable {
            errorMessage = "网络不可用"
        } catch SubsonicError.connectionFailed {
            errorMessage = "无法连接"
        } catch {
            errorMessage = "加载失败"
        }
        
        isLoading = false
    }
}
