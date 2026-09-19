import SwiftUI

struct LibraryView: View {
    var body: some View {
        LibraryHomeView()
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
            .frame(height: 180)
            .cornerRadius(6)
            
            Text(album.name)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(1)
                .foregroundColor(.primary)
            
            Text(album.artist ?? "未知艺术家")
                .font(.system(size: 12))
                .lineLimit(1)
                .foregroundColor(.secondary)
        }
    }
}

@MainActor
class LibraryViewModel: ObservableObject {
    @Published var albums: [Album] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadAlbums(api: SubsonicAPI) async {
        isLoading = true
        errorMessage = nil
        
        do {
            albums = try await api.getAlbums(type: "newest", size: 100)
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
