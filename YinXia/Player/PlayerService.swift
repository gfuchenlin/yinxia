import Foundation
import UIKit
import AVFoundation
import MediaPlayer
import Combine

@MainActor
class PlayerService: ObservableObject {
    static let shared = PlayerService()
    
    @Published var currentTrack: Song?
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var queue: [Song] = []
    @Published var currentIndex: Int = 0
    
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var api: SubsonicAPI?
    
    private init() {
        setupAudioSession()
        setupRemoteCommands()
        setupInterruptionHandling()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                self.play()
            }
            return .success
        }
        
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                self.pause()
            }
            return .success
        }
        
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                self.next()
            }
            return .success
        }
        
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                self.previous()
            }
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            Task { @MainActor in
                self.seek(to: positionEvent.positionTime)
            }
            return .success
        }
    }
    
    private func setupInterruptionHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        Task { @MainActor in
            if type == .began {
                self.pause()
            } else if type == .ended {
                if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) {
                        self.play()
                    }
                }
            }
        }
    }
    
    func playSong(_ song: Song, api: SubsonicAPI) {
        self.api = api
        self.queue = [song]
        self.currentIndex = 0
        self.currentTrack = song
        loadAndPlay(song: song)
    }
    
    func playAlbum(_ songs: [Song], api: SubsonicAPI, startIndex: Int = 0) {
        self.api = api
        self.queue = songs
        self.currentIndex = startIndex
        guard startIndex < songs.count else { return }
        self.currentTrack = songs[startIndex]
        loadAndPlay(song: songs[startIndex])
    }
    
    // MARK: - Append Queue (CR-003)
    
    /// 追加歌曲到队列并播放（如果当前无播放）
    func appendSong(_ song: Song, api: SubsonicAPI, playImmediately: Bool = true) {
        self.api = api
        
        if queue.isEmpty || currentTrack == nil {
            // 队列为空，直接播放
            self.queue = [song]
            self.currentIndex = 0
            self.currentTrack = song
            loadAndPlay(song: song)
        } else {
            // 追加到队列
            queue.append(song)
            
            if playImmediately {
                // 立即播放新追加的歌曲
                currentIndex = queue.count - 1
                currentTrack = song
                loadAndPlay(song: song)
            }
        }
    }
    
    /// 追加整个列表到队列并播放第一首
    func appendAndPlayList(_ songs: [Song], api: SubsonicAPI) {
        guard !songs.isEmpty else { return }
        self.api = api
        
        if queue.isEmpty || currentTrack == nil {
            // 队列为空，直接设置为新队列
            self.queue = songs
            self.currentIndex = 0
            self.currentTrack = songs[0]
            loadAndPlay(song: songs[0])
        } else {
            // 追加到现有队列
            let insertIndex = queue.count
            queue.append(contentsOf: songs)
            
            // 播放追加列表的第一首
            currentIndex = insertIndex
            currentTrack = songs[0]
            loadAndPlay(song: songs[0])
        }
    }
    
    private func loadAndPlay(song: Song) {
        guard let api = api,
              let urlString = api.getStreamURL(id: song.id),
              let url = URL(string: urlString) else {
            return
        }
        
        removeTimeObserver()
        
        let playerItem = AVPlayerItem(url: url)
        
        if player == nil {
            player = AVPlayer(playerItem: playerItem)
        } else {
            player?.replaceCurrentItem(with: playerItem)
        }
        
        player?.play()
        isPlaying = true
        
        addTimeObserver()
        updateNowPlaying()
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.next()
            }
        }
    }
    
    func play() {
        player?.play()
        isPlaying = true
        updateNowPlaying()
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlaying()
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func next() {
        guard currentIndex < queue.count - 1 else { return }
        currentIndex += 1
        currentTrack = queue[currentIndex]
        loadAndPlay(song: queue[currentIndex])
    }
    
    func previous() {
        if currentTime > 3 {
            seek(to: 0)
        } else if currentIndex > 0 {
            currentIndex -= 1
            currentTrack = queue[currentIndex]
            loadAndPlay(song: queue[currentIndex])
        } else {
            seek(to: 0)
        }
    }
    
    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 1000)
        player?.seek(to: cmTime)
        currentTime = time
        updateNowPlaying()
    }
    
    func stop() {
        player?.pause()
        player = nil
        currentTrack = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        queue = []
        currentIndex = 0
        removeTimeObserver()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    private func addTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            Task { @MainActor in
                self.currentTime = time.seconds
                if let duration = self.player?.currentItem?.duration.seconds, !duration.isNaN {
                    self.duration = duration
                }
            }
        }
    }
    
    private func removeTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
    
    private func updateNowPlaying() {
        guard let track = currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = track.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = track.artist ?? "未知艺术家"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = track.album ?? ""
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        if let coverArt = track.coverArt,
           let api = api,
           let urlString = api.getCoverArtURL(id: coverArt, size: 600),
           let url = URL(string: urlString) {
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let image = UIImage(data: data) {
                        let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                        await MainActor.run {
                            var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? nowPlayingInfo
                            info[MPMediaItemPropertyArtwork] = artwork
                            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
                        }
                    }
                } catch {
                    print("Failed to load cover art: \(error)")
                }
            }
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}
