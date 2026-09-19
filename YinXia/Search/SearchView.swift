import SwiftUI

struct SearchView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var playerService: PlayerService
    @StateObject private var viewModel = SearchViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error)
                } else if searchText.isEmpty {
                    Text("输入关键词搜索")
                        .foregroundColor(.secondary)
                } else if viewModel.isEmpty {
                    EmptyView(message: "无匹配")
                } else {
                    searchResults
                }
            }
            .navigationTitle("搜索")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "搜索歌曲、专辑或艺术家")
            .onChange(of: searchText) { _, newValue in
                Task {
                    await viewModel.search(query: newValue, api: appState.subsonicAPI)
                }
            }
        }
    }
    
    private var searchResults: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !viewModel.songs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("歌曲")
                            .font(.headline)
                            .padding(.horizontal, 12)
                        
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.songs) { song in
                                SearchSongRow(song: song, api: appState.subsonicAPI)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        // 追加到队列并播放（不替换）
                                        playerService.appendSong(song, api: appState.subsonicAPI)
                                    }
                            }
                        }
                    }
                }
                
                if !viewModel.albums.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("专辑")
                            .font(.headline)
                            .padding(.horizontal, 12)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.albums) { album in
                                    NavigationLink(destination: AlbumDetailView(albumId: album.id)) {
                                        SearchAlbumItem(album: album, api: appState.subsonicAPI)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 12)
                        }
                    }
                }
            }
            .padding(.vertical, 12)
        }
    }
}

struct SearchSongRow: View {
    let song: Song
    let api: SubsonicAPI
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: api.getCoverArtURL(id: song.coverArt ?? song.id, size: 120) ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 40, height: 40)
            .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.system(size: 15))
                    .lineLimit(1)
                
                Text(song.artist ?? "未知艺术家")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

struct SearchAlbumItem: View {
    let album: Album
    let api: SubsonicAPI
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: api.getCoverArtURL(id: album.coverArt ?? album.id, size: 300) ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 140, height: 140)
            .cornerRadius(6)
            
            Text(album.name)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(1)
                .foregroundColor(.primary)
                .frame(width: 140, alignment: .leading)
            
            Text(album.artist ?? "未知艺术家")
                .font(.system(size: 12))
                .lineLimit(1)
                .foregroundColor(.secondary)
                .frame(width: 140, alignment: .leading)
        }
    }
}

@MainActor
class SearchViewModel: ObservableObject {
    @Published var songs: [Song] = []
    @Published var albums: [Album] = []
    @Published var artists: [Artist] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var searchTask: Task<Void, Never>?
    
    var isEmpty: Bool {
        songs.isEmpty && albums.isEmpty && artists.isEmpty
    }
    
    func search(query: String, api: SubsonicAPI) async {
        searchTask?.cancel()
        
        guard !query.isEmpty else {
            songs = []
            albums = []
            artists = []
            return
        }
        
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            guard !Task.isCancelled else { return }
            
            isLoading = true
            errorMessage = nil
            
            do {
                let result = try await api.search(query: query)
                guard !Task.isCancelled else { return }
                
                songs = result.songs
                albums = result.albums
                artists = result.artists
            } catch SubsonicError.networkUnavailable {
                errorMessage = "网络不可用"
            } catch SubsonicError.connectionFailed {
                errorMessage = "无法连接"
            } catch {
                errorMessage = "搜索失败"
            }
            
            isLoading = false
        }
    }
}
