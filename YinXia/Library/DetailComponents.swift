import SwiftUI

// MARK: - 详情页头图区（专辑/歌单共用）

struct DetailHeaderView: View {
    let coverArt: String?
    let title: String
    let subtitle: String
    let trackCount: Int
    let api: SubsonicAPI
    let onPlayAll: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                // 封面 112×112 pt，圆角 12
                AsyncImage(url: URL(string: api.getCoverArtURL(id: coverArt ?? "", size: 300) ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 112, height: 112)
                .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    // 主标题 20-22 pt，最多 2 行
                    Text(title)
                        .font(.system(size: 20, weight: .semibold))
                        .lineLimit(2)
                    
                    // 副标题 13 pt 次要色
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // 全部播放按钮
            Button(action: onPlayAll) {
                HStack {
                    Spacer()
                    Text("全部播放（共 \(trackCount) 首）")
                        .font(.system(size: 16, weight: .medium))
                    Spacer()
                }
                .padding(.vertical, 12)
            }
            .foregroundColor(.accentColor)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - 曲目行（统一）

struct TrackRowView: View {
    let index: Int
    let song: Song
    let showAlbum: Bool  // 专辑页为 false，歌单/歌手页为 true
    let onTap: () -> Void
    let onMore: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 序号（2 位）
                Text(String(format: "%02d", index))
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .frame(width: 30, alignment: .trailing)
                
                VStack(alignment: .leading, spacing: 4) {
                    // 歌名
                    Text(song.title)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // 副行：格式徽标 + 体积 · 歌手 · 专辑
                    HStack(spacing: 4) {
                        // 格式徽标
                        if let format = song.suffix?.lowercased() {
                            Text(format)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                                )
                        }
                        
                        // 体积 · 歌手 · 专辑
                        Text(buildSubtitle())
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // 更多按钮
                Button(action: onMore) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func buildSubtitle() -> String {
        var parts: [String] = []
        
        // 体积
        if let size = song.size {
            let mb = Double(size) / 1024 / 1024
            parts.append(String(format: "%.1f MB", mb))
        }
        
        // 歌手
        if let artist = song.artist {
            parts.append(artist)
        }
        
        // 专辑（专辑页省略）
        if showAlbum, let album = song.album {
            parts.append(album)
        }
        
        return parts.joined(separator: " · ")
    }
}

// MARK: - 歌曲操作面板

struct SongActionSheet: View {
    let song: Song
    let coverArt: String?
    let api: SubsonicAPI
    @Environment(\.dismiss) var dismiss
    
    @State private var isFavorite = false
    @State private var rating: Int = 0
    
    var body: some View {
        NavigationView {
            List {
                // 头部：封面 + 歌名 + 歌手
                Section {
                    HStack(spacing: 16) {
                        AsyncImage(url: URL(string: api.getCoverArtURL(id: coverArt ?? song.coverArt ?? song.id, size: 200) ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(song.title)
                                .font(.system(size: 16, weight: .medium))
                                .lineLimit(2)
                            
                            if let artist = song.artist {
                                Text(artist)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        // 心形喜欢
                        Button(action: { isFavorite.toggle() }) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 24))
                                .foregroundColor(isFavorite ? .red : .secondary)
                        }
                    }
                }
                
                // 星级评分（1-5 星，仅此面板）
                Section {
                    HStack {
                        Text("评分")
                        Spacer()
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { star in
                                Button(action: { rating = star }) {
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .foregroundColor(star <= rating ? .yellow : .gray)
                                }
                            }
                        }
                    }
                }
                
                // MVP 操作
                Section {
                    Button("下一首播放") {
                        // TODO: 实现
                        dismiss()
                    }
                    
                    Button("追加到队列") {
                        // TODO: 实现
                        dismiss()
                    }
                    
                    if song.artistId != nil {
                        Button("查看歌手") {
                            // TODO: 实现
                            dismiss()
                        }
                    }
                    
                    if song.albumId != nil {
                        Button("查看专辑") {
                            // TODO: 实现
                            dismiss()
                        }
                    }
                }
                
                // 后续功能（灰显）
                Section {
                    Button("下载") {}
                        .foregroundColor(.secondary)
                        .disabled(true)
                    
                    Button("定时停止播放") {}
                        .foregroundColor(.secondary)
                        .disabled(true)
                    
                    Button("播放速度") {}
                        .foregroundColor(.secondary)
                        .disabled(true)
                }
            }
            .navigationTitle("歌曲选项")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}
