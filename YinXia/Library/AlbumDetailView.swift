import SwiftUI

struct AlbumDetailView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var playerService: PlayerService
    @StateObject private var viewModel = AlbumDetailViewModel()
    @Environment(\.dismiss) var dismiss
    @Environment(\.showMiniPlayer) var showMiniPlayer
    
    let albumId: String
    
    @State private var showSongSheet: Song?
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error)
            } else if let album = viewModel.album {
                albumDetail(album)
            }
        }
        .toolbar(.hidden, for: .tabBar)  // 隐藏 tab bar
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadAlbum(id: albumId, api: appState.subsonicAPI)
        }
        .sheet(item: $showSongSheet) { song in
            SongActionSheet(
                song: song,
                coverArt: viewModel.album?.coverArt ?? viewModel.album?.id,
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
    
    private func albumDetail(_ album: AlbumDetail) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // 头图区（封面 112pt + 标题 + 全部播放）
                DetailHeaderView(
                    coverArt: album.coverArt ?? album.id,
                    title: album.name,
                    subtitle: buildSubtitle(album),
                    trackCount: album.songCount,
                    api: appState.subsonicAPI,
                    onPlayAll: {
                        // 追加整表到队列并播放第一首
                        playerService.appendAndPlayList(album.song, api: appState.subsonicAPI)
                    }
                )
                
                Divider()
                    .padding(.vertical, 8)
                
                // 曲目列表
                LazyVStack(spacing: 0) {
                    ForEach(Array(album.song.enumerated()), id: \.element.id) { index, song in
                        TrackRowView(
                            index: index + 1,
                            song: song,
                            showAlbum: false,  // 专辑页省略专辑名
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
    
    private func buildSubtitle(_ album: AlbumDetail) -> String {
        var parts: [String] = []
        
        // 年份
        if let year = album.year {
            parts.append(String(year))
        }
        
        // 歌手
        if let artist = album.artist {
            parts.append(artist)
        }
        
        return parts.joined(separator: " · ")
    }
}

struct SongRow: View {
    let song: Song
    let index: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .center)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.system(size: 15))
                    .lineLimit(1)
                
                if let artist = song.artist {
                    Text(artist)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if let duration = song.duration {
                Text(formatDuration(duration))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

@MainActor
class AlbumDetailViewModel: ObservableObject {
    @Published var album: AlbumDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadAlbum(id: String, api: SubsonicAPI) async {
        isLoading = true
        errorMessage = nil
        
        do {
            album = try await api.getAlbum(id: id)
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
