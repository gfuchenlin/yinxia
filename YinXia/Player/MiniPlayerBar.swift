import SwiftUI

struct MiniPlayerBar: View {
    @EnvironmentObject var playerService: PlayerService
    @EnvironmentObject var appState: AppState
    @State private var showNowPlaying = false
    
    var body: some View {
        Button(action: {
            showNowPlaying = true
        }) {
            HStack(spacing: 12) {
                if let track = playerService.currentTrack {
                    AsyncImage(url: URL(string: appState.subsonicAPI.getCoverArtURL(id: track.coverArt ?? track.id, size: 200) ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 40, height: 40)
                    .cornerRadius(6)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(track.title)
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        
                        Text(track.artist ?? "未知艺术家")
                            .font(.system(size: 12))
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        playerService.togglePlayPause()
                    }) {
                        Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                    }
                    .frame(width: 44, height: 44)
                    
                    Button(action: {
                        playerService.next()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.primary)
                    }
                    .frame(width: 44, height: 44)
                    .disabled(playerService.currentIndex >= playerService.queue.count - 1)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 56)
            .background(.ultraThinMaterial)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showNowPlaying) {
            NowPlayingView()
                .environmentObject(playerService)
                .environmentObject(appState)
        }
    }
}
