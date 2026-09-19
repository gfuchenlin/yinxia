import SwiftUI

struct ArtistDetailView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var playerService: PlayerService
    @StateObject private var viewModel = ArtistDetailViewModel()
    @Environment(\.showMiniPlayer) var showMiniPlayer
    
    let artistId: String
    let artistName: String
    
    @State private var selectedTab = 0
    @State private var isFavorite = false
    @State private var showSongSheet: Song?
    
    var body: some View {
        VStack(spacing: 0) {
            // 头部信息
            VStack(spacing: 8) {
                Text(artistName)
                    .font(.system(size: 28, weight: .bold))
                
                if !viewModel.albums.isEmpty || !viewModel.songs.isEmpty {
                    Text("\(viewModel.albums.count) 专辑 · \(viewModel.songs.count) 歌曲")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                
                Text("来自已连接曲库")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 20)
            
            // Tab 选择器
            Picker("", selection: $selectedTab) {
                Text("专辑").tag(0)
                Text("歌曲").tag(1)
                Text("相似").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            
            // Tab 内容
            TabView(selection: $selectedTab) {
                // 专辑 Tab
                albumsTab
                    .tag(0)
                
                // 歌曲 Tab
                songsTab
                    .tag(1)
                
                // 相似 Tab
                similarTab
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .toolbar(.hidden, for: .tabBar)  // 隐藏 tab bar
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { isFavorite.toggle() }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(isFavorite ? .red : .primary)
                }
            }
        }
        .task {
            await viewModel.loadArtist(id: artistId, api: appState.subsonicAPI)
        }
        .sheet(item: $showSongSheet) { song in
            SongActionSheet(
                song: song,
                coverArt: nil,
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
    
    // MARK: - 专辑 Tab
    
    private var albumsTab: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(viewModel.albums) { album in
                    NavigationLink(destination: AlbumDetailView(albumId: album.id)) {
                        VStack(alignment: .leading, spacing: 8) {
                            AsyncImage(url: URL(string: appState.subsonicAPI.getCoverArtURL(id: album.coverArt ?? album.id, size: 300) ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray.opacity(0.3)
                            }
                            .frame(height: 160)
                            .cornerRadius(8)
                            
                            Text(album.name)
                                .font(.system(size: 14, weight: .medium))
                                .lineLimit(1)
                                .foregroundColor(.primary)
                            
                            if let year = album.year {
                                Text(String(year))
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(12)
        }
    }
    
    // MARK: - 歌曲 Tab
    
    private var songsTab: some View {
        ScrollView {
            VStack(spacing: 0) {
                if !viewModel.songs.isEmpty {
                    // 全部播放按钮
                    Button(action: {
                        playerService.appendAndPlayList(viewModel.songs, api: appState.subsonicAPI)
                    }) {
                        HStack {
                            Spacer()
                            Text("全部播放（共 \(viewModel.songs.count) 首）")
                                .font(.system(size: 16, weight: .medium))
                            Spacer()
                        }
                        .padding(.vertical, 12)
                    }
                    .foregroundColor(.accentColor)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(8)
                    .padding(16)
                    
                    // 曲目列表
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.songs.enumerated()), id: \.element.id) { index, song in
                            TrackRowView(
                                index: index + 1,
                                song: song,
                                showAlbum: true,  // 歌手页歌曲 Tab 显示专辑名
                                onTap: {
                                    playerService.appendSong(song, api: appState.subsonicAPI)
                                },
                                onMore: {
                                    showSongSheet = song
                                }
                            )
                        }
                    }
                } else {
                    Text("暂无歌曲")
                        .foregroundColor(.secondary)
                        .padding(.top, 100)
                }
            }
        }
    }
    
    // MARK: - 相似 Tab
    
    private var similarTab: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "person.2")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("暂无相似歌手")
                .font(.system(size: 17))
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - ViewModel

@MainActor
class ArtistDetailViewModel: ObservableObject {
    @Published var albums: [Album] = []
    @Published var songs: [Song] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadArtist(id: String, api: SubsonicAPI) async {
        isLoading = true
        errorMessage = nil
        
        // TODO: 实现真实的歌手数据加载
        // 这里使用占位数据
        
        isLoading = false
    }
}
