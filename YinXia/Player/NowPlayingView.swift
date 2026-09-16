import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject var playerService: PlayerService
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                if let track = playerService.currentTrack {
                    VStack(spacing: 24) {
                        Spacer()
                        
                        AsyncImage(url: URL(string: appState.subsonicAPI.getCoverArtURL(id: track.coverArt ?? track.id, size: 800) ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(width: UIScreen.main.bounds.width - 40, height: UIScreen.main.bounds.width - 40)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.2), radius: 20)
                        
                        VStack(spacing: 8) {
                            Text(track.title)
                                .font(.system(size: 22, weight: .semibold))
                                .lineLimit(1)
                            
                            Text(track.artist ?? "未知艺术家")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(spacing: 8) {
                            Slider(value: Binding(
                                get: { playerService.currentTime },
                                set: { playerService.seek(to: $0) }
                            ), in: 0...max(playerService.duration, 1))
                            .accentColor(.primary)
                            
                            HStack {
                                Text(formatTime(playerService.currentTime))
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(formatTime(playerService.duration))
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        HStack(spacing: 40) {
                            Button(action: {
                                playerService.previous()
                            }) {
                                Image(systemName: "backward.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.primary)
                            }
                            .frame(width: 64, height: 64)
                            
                            Button(action: {
                                playerService.togglePlayPause()
                            }) {
                                Image(systemName: playerService.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundColor(.primary)
                            }
                            .frame(width: 64, height: 64)
                            
                            Button(action: {
                                playerService.next()
                            }) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.primary)
                            }
                            .frame(width: 64, height: 64)
                            .disabled(playerService.currentIndex >= playerService.queue.count - 1)
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.down")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        guard !time.isNaN && time.isFinite else { return "0:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
