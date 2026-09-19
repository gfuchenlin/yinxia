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
    @Environment(\.showMiniPlayer) var showMiniPlayer
    
    let playlistId: String
    
    @State private var showSongSheet: Song?
    
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
        .toolbar(.hidden, for: .tabBar)  // 隐藏 tab bar
        .navigationTitle(viewModel.playlist?.name ?? "歌单")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadPlaylist(id: playlistId, api: appState.subsonicAPI)
        }
        .sheet(item: $showSongSheet) { song in
            SongActionSheet(
                song: song,
                coverArt: viewModel.playlist?.coverArt,
                api: appState.subsonicAPI
            )
        }
        .onAppear {
            // 隐藏 mini player
            showMiniPlayer.wrappedValue = false
        }
        .onDisappear {
            // 恢复 mini player
            showMiniPlayer.wrappedValue = true
        }
    }
    
    private func playlistDetail(_ playlist: PlaylistDetail) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // 头图区（使用 DetailHeaderView）
                DetailHeaderView(
                    coverArt: playlist.coverArt ?? playlist.id,
                    title: playlist.name,
                    subtitle: buildSubtitle(playlist),
                    trackCount: playlist.songCount,
                    api: appState.subsonicAPI,
                    onPlayAll: {
                        // 追加整表到队列并播放第一首
                        playerService.appendAndPlayList(playlist.entry, api: appState.subsonicAPI)
                    }
                )
                
                Divider()
                    .padding(.vertical, 8)
                
                // 曲目列表
                LazyVStack(spacing: 0) {
                    ForEach(Array(playlist.entry.enumerated()), id: \.element.id) { index, song in
                        TrackRowView(
                            index: index + 1,
                            song: song,
                            showAlbum: true,  // 歌单页显示专辑名
                            onTap: {
                                // 追加该曲并播放
                                playerService.appendSong(song, api: appState.subsonicAPI)
                            },
                            onMore: {
                                showSongSheet = song
                            }
                        )
                    }
                }
            }
        }
    }
    
    private func buildSubtitle(_ playlist: PlaylistDetail) -> String {
        // 根据 DETAIL-SPEC：普通歌单显示「服务器歌单」或「N 首」
        // 这里简化为「服务器歌单」
        return "服务器歌单"
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
