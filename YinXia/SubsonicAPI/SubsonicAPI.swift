import Foundation
import CryptoKit

enum SubsonicError: Error {
    case invalidURL
    case authenticationFailed
    case connectionFailed
    case networkUnavailable
    case serverError(String)
    case parsingError
}

class SubsonicAPI {
    private var credentials: ServerCredentials?
    private let clientName = "YinXia"
    private let apiVersion = "1.16.1"
    
    func configure(credentials: ServerCredentials?) {
        self.credentials = credentials
    }
    
    func ping(credentials: ServerCredentials) async throws {
        let params = createAuthParams(credentials: credentials)
        let url = try createURL(endpoint: "ping", params: params, credentials: credentials)
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SubsonicError.connectionFailed
        }
        
        guard httpResponse.statusCode == 200 else {
            throw SubsonicError.connectionFailed
        }
        
        try validateResponse(data)
    }
    
    func getAlbums(type: String = "newest", size: Int = 50, offset: Int = 0) async throws -> [Album] {
        guard let credentials = credentials else {
            throw SubsonicError.authenticationFailed
        }
        
        var params = createAuthParams(credentials: credentials)
        params["type"] = type
        params["size"] = "\(size)"
        params["offset"] = "\(offset)"
        
        let url = try createURL(endpoint: "getAlbumList2", params: params, credentials: credentials)
        let (data, _) = try await URLSession.shared.data(from: url)
        
        try validateResponse(data)
        
        let response = try JSONDecoder().decode(SubsonicResponse<AlbumListResponse>.self, from: data)
        return response.subsonicResponse.albumList2?.album ?? []
    }
    
    func getAlbum(id: String) async throws -> AlbumDetail {
        guard let credentials = credentials else {
            throw SubsonicError.authenticationFailed
        }
        
        var params = createAuthParams(credentials: credentials)
        params["id"] = id
        
        let url = try createURL(endpoint: "getAlbum", params: params, credentials: credentials)
        let (data, _) = try await URLSession.shared.data(from: url)
        
        try validateResponse(data)
        
        let response = try JSONDecoder().decode(SubsonicResponse<AlbumDetailResponse>.self, from: data)
        guard let album = response.subsonicResponse.album else {
            throw SubsonicError.parsingError
        }
        return album
    }
    
    func search(query: String) async throws -> SearchResult {
        guard let credentials = credentials else {
            throw SubsonicError.authenticationFailed
        }
        
        var params = createAuthParams(credentials: credentials)
        params["query"] = query
        params["artistCount"] = "20"
        params["albumCount"] = "20"
        params["songCount"] = "50"
        
        let url = try createURL(endpoint: "search3", params: params, credentials: credentials)
        let (data, _) = try await URLSession.shared.data(from: url)
        
        try validateResponse(data)
        
        let response = try JSONDecoder().decode(SubsonicResponse<SearchResponse>.self, from: data)
        return response.subsonicResponse.searchResult3 ?? SearchResult(artists: [], albums: [], songs: [])
    }
    
    func getPlaylists() async throws -> [Playlist] {
        guard let credentials = credentials else {
            throw SubsonicError.authenticationFailed
        }
        
        let params = createAuthParams(credentials: credentials)
        let url = try createURL(endpoint: "getPlaylists", params: params, credentials: credentials)
        let (data, _) = try await URLSession.shared.data(from: url)
        
        try validateResponse(data)
        
        let response = try JSONDecoder().decode(SubsonicResponse<PlaylistsResponse>.self, from: data)
        return response.subsonicResponse.playlists?.playlist ?? []
    }
    
    func getPlaylist(id: String) async throws -> PlaylistDetail {
        guard let credentials = credentials else {
            throw SubsonicError.authenticationFailed
        }
        
        var params = createAuthParams(credentials: credentials)
        params["id"] = id
        
        let url = try createURL(endpoint: "getPlaylist", params: params, credentials: credentials)
        let (data, _) = try await URLSession.shared.data(from: url)
        
        try validateResponse(data)
        
        let response = try JSONDecoder().decode(SubsonicResponse<PlaylistDetailResponse>.self, from: data)
        guard let playlist = response.subsonicResponse.playlist else {
            throw SubsonicError.parsingError
        }
        return playlist
    }
    
    func getStreamURL(id: String) -> String? {
        guard let credentials = credentials else { return nil }
        
        var params = createAuthParams(credentials: credentials)
        params["id"] = id
        
        return try? createURL(endpoint: "stream", params: params, credentials: credentials).absoluteString
    }
    
    func getCoverArtURL(id: String, size: Int = 300) -> String? {
        guard let credentials = credentials else { return nil }
        
        var params = createAuthParams(credentials: credentials)
        params["id"] = id
        params["size"] = "\(size)"
        
        return try? createURL(endpoint: "getCoverArt", params: params, credentials: credentials).absoluteString
    }
    
    private func createAuthParams(credentials: ServerCredentials) -> [String: String] {
        let salt = generateSalt()
        let token = generateToken(password: credentials.password, salt: salt)
        
        return [
            "u": credentials.username,
            "t": token,
            "s": salt,
            "v": apiVersion,
            "c": clientName,
            "f": "json"
        ]
    }
    
    private func generateSalt() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<12).map { _ in letters.randomElement()! })
    }
    
    private func generateToken(password: String, salt: String) -> String {
        let input = password + salt
        let digest = Insecure.MD5.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    private func createURL(endpoint: String, params: [String: String], credentials: ServerCredentials) throws -> URL {
        var serverURL = credentials.serverURL
        if !serverURL.hasPrefix("http://") && !serverURL.hasPrefix("https://") {
            serverURL = "https://" + serverURL
        }
        
        if serverURL.hasSuffix("/") {
            serverURL.removeLast()
        }
        
        guard var components = URLComponents(string: "\(serverURL)/rest/\(endpoint)") else {
            throw SubsonicError.invalidURL
        }
        
        components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        guard let url = components.url else {
            throw SubsonicError.invalidURL
        }
        
        return url
    }
    
    private func validateResponse(_ data: Data) throws {
        struct ErrorResponse: Codable {
            let subsonicResponse: SubsonicErrorResponse
            
            enum CodingKeys: String, CodingKey {
                case subsonicResponse = "subsonic-response"
            }
        }
        
        struct SubsonicErrorResponse: Codable {
            let status: String
            let error: SubsonicErrorDetail?
        }
        
        struct SubsonicErrorDetail: Codable {
            let code: Int
            let message: String
        }
        
        let response = try JSONDecoder().decode(ErrorResponse.self, from: data)
        
        if response.subsonicResponse.status == "failed",
           let error = response.subsonicResponse.error {
            if error.code == 40 || error.code == 41 {
                throw SubsonicError.authenticationFailed
            }
            throw SubsonicError.serverError(error.message)
        }
    }
}
