import SwiftUI

struct GenresGridView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = GenresViewModel()
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .padding(.top, 100)
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error)
            } else if viewModel.genres.isEmpty {
                EmptyView(message: "暂无流派")
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(viewModel.genres) { genre in
                        NavigationLink(destination: GenreDetailView(genre: genre)) {
                            GenreGridItem(genre: genre)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("流派")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadGenres(api: appState.subsonicAPI)
        }
        .refreshable {
            await viewModel.loadGenres(api: appState.subsonicAPI)
        }
    }
}

struct GenreGridItem: View {
    let genre: Genre
    
    // 流派颜色映射
    private var genreColor: Color {
        let colors: [Color] = [
            .purple, .blue, .green, .orange, .pink, .red, .indigo, .teal
        ]
        let hash = abs(genre.value.hashValue)
        return colors[hash % colors.count]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                genreColor.opacity(0.7)
                
                VStack(spacing: 4) {
                    Image(systemName: "music.note")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                    
                    Text(genre.value)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
            }
            .frame(height: 120)
            .cornerRadius(12)
            
            if let songCount = genre.songCount {
                Text("\(songCount) 首歌曲")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
    }
}

struct GenreDetailView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var playerService: PlayerService
    @StateObject private var viewModel = GenreDetailViewModel()
    @Environment(\.showMiniPlayer) var showMiniPlayer
    
    let genre: Genre
    
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
                        title: genre.value,
                        subtitle: "流派 · \(genre.value)",
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
        .navigationTitle(genre.value)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadSongs(genre: genre.value, api: appState.subsonicAPI)
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
class GenresViewModel: ObservableObject {
    @Published var genres: [Genre] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadGenres(api: SubsonicAPI) async {
        isLoading = true
        errorMessage = nil
        
        do {
            genres = try await api.getGenres()
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
class GenreDetailViewModel: ObservableObject {
    @Published var songs: [Song] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadSongs(genre: String, api: SubsonicAPI) async {
        isLoading = true
        errorMessage = nil
        
        do {
            songs = try await api.getSongsByGenre(genre: genre)
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
