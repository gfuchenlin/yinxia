import SwiftUI

struct AlbumDetailView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var playerService: PlayerService
    @StateObject private var viewModel = AlbumDetailViewModel()
    
    let albumId: String
    
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
        .task {
            await viewModel.loadAlbum(id: albumId, api: appState.subsonicAPI)
        }
    }
    
    private func albumDetail(_ album: AlbumDetail) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                AsyncImage(url: URL(string: appState.subsonicAPI.getCoverArtURL(id: album.coverArt ?? album.id, size: 600) ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: UIScreen.main.bounds.width - 40, height: UIScreen.main.bounds.width - 40)
                .cornerRadius(12)
                .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(album.name)
                        .font(.system(size: 22, weight: .semibold))
                        .multilineTextAlignment(.leading)
                    
                    Text(album.artist ?? "未知艺术家")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                    
                    if let year = album.year {
                        Text("\(year) • \(album.songCount) 首歌曲")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                Button(action: {
                    playerService.playAlbum(album.song, api: appState.subsonicAPI)
                }) {
                    Text("播放全部")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                
                LazyVStack(spacing: 0) {
                    ForEach(Array(album.song.enumerated()), id: \.element.id) { index, song in
                        SongRow(song: song, index: index + 1)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                playerService.playAlbum(album.song, api: appState.subsonicAPI, startIndex: index)
                            }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
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
