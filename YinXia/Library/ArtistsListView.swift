import SwiftUI

struct ArtistsListView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ArtistsViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error)
            } else if viewModel.artists.isEmpty {
                EmptyView(message: "暂无歌手")
            } else {
                List(viewModel.artists) { artist in
                    NavigationLink(destination: ArtistDetailView(artistId: artist.id, artistName: artist.name)) {
                        ArtistRow(artist: artist, api: appState.subsonicAPI)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("歌手")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadArtists(api: appState.subsonicAPI)
        }
        .refreshable {
            await viewModel.loadArtists(api: appState.subsonicAPI)
        }
    }
}

struct ArtistRow: View {
    let artist: Artist
    let api: SubsonicAPI
    
    var body: some View {
        HStack(spacing: 12) {
            // 歌手头像/封面
            AsyncImage(url: URL(string: api.getCoverArtURL(id: artist.coverArt ?? artist.id, size: 200) ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                ZStack {
                    Color.gray.opacity(0.3)
                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(artist.name)
                    .font(.system(size: 16, weight: .medium))
                    .lineLimit(1)
                
                if let albumCount = artist.albumCount {
                    Text("\(albumCount) 专辑")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

@MainActor
class ArtistsViewModel: ObservableObject {
    @Published var artists: [Artist] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadArtists(api: SubsonicAPI) async {
        isLoading = true
        errorMessage = nil
        
        do {
            artists = try await api.getArtists()
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
