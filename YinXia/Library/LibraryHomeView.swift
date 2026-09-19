import SwiftUI

struct LibraryHomeView: View {
    @EnvironmentObject var appState: AppState
    
    private let gridItems = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 6宫格
                    LazyVGrid(columns: gridItems, spacing: 12) {
                        LibraryGridItem(
                            title: "歌曲",
                            icon: "music.note",
                            destination: AnyView(AllSongsView())
                        )
                        
                        LibraryGridItem(
                            title: "我喜欢的",
                            icon: "heart",
                            destination: AnyView(FavoritesView())
                        )
                        
                        LibraryGridItem(
                            title: "本地音乐",
                            icon: "arrow.down.circle",
                            destination: AnyView(LocalMusicView())
                        )
                        
                        LibraryGridItem(
                            title: "专辑",
                            icon: "square.stack",
                            destination: AnyView(AlbumsGridView())
                        )
                        
                        LibraryGridItem(
                            title: "流派",
                            icon: "guitars",
                            destination: AnyView(GenresGridView())
                        )
                        
                        LibraryGridItem(
                            title: "歌手",
                            icon: "person.2",
                            destination: AnyView(ArtistsListView())
                        )
                    }
                    .padding(.horizontal, 12)
                    
                    // 我的歌单区块
                    VStack(alignment: .leading, spacing: 12) {
                        Text("我的歌单")
                            .font(.system(size: 20, weight: .semibold))
                            .padding(.horizontal, 12)
                        
                        PlaylistsListView()
                    }
                    
                    // 最近播放横条
                    VStack(alignment: .leading, spacing: 12) {
                        Text("最近播放")
                            .font(.system(size: 20, weight: .semibold))
                            .padding(.horizontal, 12)
                        
                        RecentlyPlayedStrip()
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 80)
            }
            .navigationTitle("曲库")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct LibraryGridItem: View {
    let title: String
    let icon: String
    let destination: AnyView
    
    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(.primary)
                    .frame(height: 60)
                
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// 本地音乐占位
struct LocalMusicView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("本地音乐")
                .font(.title)
            
            Text("占用 0 MB")
                .foregroundColor(.secondary)
            
            Text("本地导入功能待实现")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .navigationTitle("本地音乐")
    }
}

// 我的歌单列表
struct PlaylistsListView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = PlaylistsViewModel()
    
    var body: some View {
        VStack(spacing: 8) {
            if viewModel.isLoading {
                ProgressView()
                    .frame(height: 100)
            } else if viewModel.playlists.isEmpty {
                Text("暂无歌单")
                    .foregroundColor(.secondary)
                    .frame(height: 100)
            } else {
                ForEach(viewModel.playlists.prefix(3)) { playlist in
                    NavigationLink(destination: PlaylistDetailView(playlistId: playlist.id)) {
                        HStack(spacing: 12) {
                            AsyncImage(url: URL(string: appState.subsonicAPI.getCoverArtURL(id: playlist.coverArt ?? playlist.id, size: 200) ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray.opacity(0.3)
                            }
                            .frame(width: 50, height: 50)
                            .cornerRadius(6)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(playlist.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                Text("\(playlist.songCount) 首歌曲")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .task {
            await viewModel.loadPlaylists(api: appState.subsonicAPI)
        }
    }
}

@MainActor
class PlaylistsViewModel: ObservableObject {
    @Published var playlists: [Playlist] = []
    @Published var isLoading = false
    
    func loadPlaylists(api: SubsonicAPI) async {
        isLoading = true
        
        do {
            playlists = try await api.getPlaylists()
        } catch {
            playlists = []
        }
        
        isLoading = false
    }
}

struct RecentlyPlayedStrip: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<5) { _ in
                    VStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 100, height: 100)
                        
                        Text("最近")
                            .font(.caption)
                    }
                }
            }
            .padding(.horizontal, 12)
        }
    }
}
