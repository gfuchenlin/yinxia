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
                            destination: AnyView(GenresView())
                        )
                        
                        LibraryGridItem(
                            title: "歌手",
                            icon: "person.2",
                            destination: AnyView(ArtistsView())
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

// 占位视图
struct AllSongsView: View {
    var body: some View {
        Text("全部歌曲")
            .navigationTitle("歌曲")
    }
}

struct FavoritesView: View {
    var body: some View {
        Text("我喜欢的")
            .navigationTitle("我喜欢的")
    }
}

struct LocalMusicView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("本地音乐")
                .font(.title)
            
            Text("占用 0 MB")
                .foregroundColor(.secondary)
        }
        .navigationTitle("本地音乐")
    }
}

struct AlbumsGridView: View {
    var body: some View {
        Text("专辑网格")
            .navigationTitle("专辑")
    }
}

struct GenresView: View {
    var body: some View {
        Text("流派")
            .navigationTitle("流派")
    }
}

struct ArtistsView: View {
    var body: some View {
        Text("歌手")
            .navigationTitle("歌手")
    }
}

struct PlaylistsListView: View {
    var body: some View {
        VStack {
            Text("歌单列表")
                .foregroundColor(.secondary)
        }
        .frame(height: 100)
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
