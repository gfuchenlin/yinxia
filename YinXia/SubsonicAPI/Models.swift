import Foundation

struct SubsonicResponse<T: Codable>: Codable {
    let subsonicResponse: T
    
    enum CodingKeys: String, CodingKey {
        case subsonicResponse = "subsonic-response"
    }
}

struct AlbumListResponse: Codable {
    let albumList2: AlbumList?
}

struct AlbumList: Codable {
    let album: [Album]
}

struct Album: Codable, Identifiable {
    let id: String
    let name: String
    let artist: String?
    let artistId: String?
    let coverArt: String?
    let songCount: Int?
    let duration: Int?
    let created: String?
    let year: Int?
    let genre: String?
}

struct AlbumDetailResponse: Codable {
    let album: AlbumDetail?
}

struct AlbumDetail: Codable, Identifiable {
    let id: String
    let name: String
    let artist: String?
    let artistId: String?
    let coverArt: String?
    let songCount: Int
    let duration: Int
    let created: String?
    let year: Int?
    let genre: String?
    let song: [Song]
}

struct Song: Codable, Identifiable {
    let id: String
    let title: String
    let album: String?
    let artist: String?
    let track: Int?
    let year: Int?
    let genre: String?
    let coverArt: String?
    let size: Int?
    let contentType: String?
    let suffix: String?
    let duration: Int?
    let bitRate: Int?
    let path: String?
    let albumId: String?
    let artistId: String?
}

struct SearchResponse: Codable {
    let searchResult3: SearchResult?
}

struct SearchResult: Codable {
    let artists: [Artist]
    let albums: [Album]
    let songs: [Song]
    
    enum CodingKeys: String, CodingKey {
        case artists = "artist"
        case albums = "album"
        case songs = "song"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.artists = (try? container.decode([Artist].self, forKey: .artists)) ?? []
        self.albums = (try? container.decode([Album].self, forKey: .albums)) ?? []
        self.songs = (try? container.decode([Song].self, forKey: .songs)) ?? []
    }
    
    init(artists: [Artist], albums: [Album], songs: [Song]) {
        self.artists = artists
        self.albums = albums
        self.songs = songs
    }
}

struct Artist: Codable, Identifiable {
    let id: String
    let name: String
    let albumCount: Int?
    let coverArt: String?
    let artistImageUrl: String?
}

struct ArtistsResponse: Codable {
    let artists: ArtistsIndex?
}

struct ArtistsIndex: Codable {
    let index: [ArtistIndex]
}

struct ArtistIndex: Codable {
    let name: String
    let artist: [Artist]
}

struct GenresResponse: Codable {
    let genres: GenresList?
}

struct GenresList: Codable {
    let genre: [Genre]
}

struct Genre: Codable, Identifiable {
    let value: String
    let songCount: Int?
    let albumCount: Int?
    
    var id: String { value }
}

struct Starred2Response: Codable {
    let starred2: Starred2?
}

struct Starred2: Codable {
    let artist: [Artist]?
    let album: [Album]?
    let song: [Song]?
}

struct SongsByGenreResponse: Codable {
    let songsByGenre: SongsByGenre?
}

struct SongsByGenre: Codable {
    let song: [Song]
}

struct PlaylistsResponse: Codable {
    let playlists: Playlists?
}

struct Playlists: Codable {
    let playlist: [Playlist]
}

struct Playlist: Codable, Identifiable {
    let id: String
    let name: String
    let songCount: Int
    let duration: Int
    let created: String?
    let changed: String?
    let coverArt: String?
    let owner: String?
    let `public`: Bool?
}

struct PlaylistDetailResponse: Codable {
    let playlist: PlaylistDetail?
}

struct PlaylistDetail: Codable, Identifiable {
    let id: String
    let name: String
    let songCount: Int
    let duration: Int
    let created: String?
    let changed: String?
    let coverArt: String?
    let owner: String?
    let `public`: Bool?
    let entry: [Song]
}
