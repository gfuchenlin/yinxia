import SwiftUI

struct AlbumsGridView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AlbumsViewModel()
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .padding(.top, 100)
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error)
            } else if viewModel.albums.isEmpty {
                EmptyView(message: "暂无专辑")
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 16) {
                    ForEach(viewModel.albums) { album in
                        NavigationLink(destination: AlbumDetailView(albumId: album.id)) {
                            AlbumGridItem(album: album, api: appState.subsonicAPI)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("专辑")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadAlbums(api: appState.subsonicAPI)
        }
        .refreshable {
            await viewModel.loadAlbums(api: appState.subsonicAPI)
        }
    }
}

struct AlbumGridItem: View {
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
            .frame(height: 160)
            .cornerRadius(8)
            
            Text(album.name)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(2)
                .foregroundColor(.primary)
            
            if let artist = album.artist {
                Text(artist)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

@MainActor
class AlbumsViewModel: ObservableObject {
    @Published var albums: [Album] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadAlbums(api: SubsonicAPI) async {
        isLoading = true
        errorMessage = nil
        
        do {
            albums = try await api.getAlbums(type: "alphabeticalByName", size: 500)
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
