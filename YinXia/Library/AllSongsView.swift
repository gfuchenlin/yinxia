import SwiftUI

struct AllSongsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var playerService: PlayerService
    @StateObject private var viewModel = AllSongsViewModel()
    @Environment(\.showMiniPlayer) var showMiniPlayer
    
    @State private var showSongSheet: Song?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, 100)
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error)
                } else if viewModel.songs.isEmpty {
                    EmptyView(message: "暂无歌曲")
                } else {
                    // 头图区
                    DetailHeaderView(
                        coverArt: nil,
                        title: "歌曲",
                        subtitle: "曲库",
                        trackCount: viewModel.songs.count,
                        api: appState.subsonicAPI,
                        onPlayAll: {
                            playerService.appendAndPlayList(viewModel.songs, api: appState.subsonicAPI)
                        }
                    )
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // 曲目列表
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.songs.enumerated()), id: \.element.id) { index, song in
                            TrackRowView(
                                index: index + 1,
                                song: song,
                                showAlbum: true,
                                onTap: {
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
        .toolbar(.hidden, for: .tabBar)
        .navigationTitle("歌曲")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadSongs(api: appState.subsonicAPI)
        }
        .sheet(item: $showSongSheet) { song in
            SongActionSheet(
                song: song,
                coverArt: song.coverArt,
                api: appState.subsonicAPI
            )
        }
        .onAppear {
            showMiniPlayer.wrappedValue = false
        }
        .onDisappear {
            showMiniPlayer.wrappedValue = true
        }
    }
}

struct FavoritesView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var playerService: PlayerService
    @StateObject private var viewModel = FavoritesViewModel()
    @Environment(\.showMiniPlayer) var showMiniPlayer
    
    @State private var showSongSheet: Song?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, 100)
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error)
                } else if viewModel.songs.isEmpty {
                    EmptyView(message: "暂无收藏")
                } else {
                    // 头图区
                    DetailHeaderView(
                        coverArt: nil,
                        title: "我喜欢的",
                        subtitle: "智能歌单",
                        trackCount: viewModel.songs.count,
                        api: appState.subsonicAPI,
                        onPlayAll: {
                            playerService.appendAndPlayList(viewModel.songs, api: appState.subsonicAPI)
                        }
                    )
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // 曲目列表
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.songs.enumerated()), id: \.element.id) { index, song in
                            TrackRowView(
                                index: index + 1,
                                song: song,
                                showAlbum: true,
                                onTap: {
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
        .toolbar(.hidden, for: .tabBar)
        .navigationTitle("我喜欢的")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadStarred(api: appState.subsonicAPI)
        }
        .sheet(item: $showSongSheet) { song in
            SongActionSheet(
                song: song,
                coverArt: song.coverArt,
                api: appState.subsonicAPI
            )
        }
        .onAppear {
            showMiniPlayer.wrappedValue = false
        }
        .onDisappear {
            showMiniPlayer.wrappedValue = true
        }
    }
}

@MainActor
class AllSongsViewModel: ObservableObject {
    @Published var songs: [Song] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadSongs(api: SubsonicAPI) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 获取最近添加的专辑，然后提取所有歌曲
            let albums = try await api.getAlbums(type: "newest", size: 100)
            var allSongs: [Song] = []
            
            for album in albums {
                do {
                    let albumDetail = try await api.getAlbum(id: album.id)
                    allSongs.append(contentsOf: albumDetail.song)
                } catch {
                    // 忽略单个专辑的错误，继续加载其他专辑
                    continue
                }
            }
            
            songs = allSongs
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
class FavoritesViewModel: ObservableObject {
    @Published var songs: [Song] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadStarred(api: SubsonicAPI) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let starred = try await api.getStarred2()
            songs = starred.song ?? []
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
