import Foundation
import Security

struct ServerCredentials: Codable {
    let serverURL: String
    let username: String
    let password: String
}

class AuthService {
    private let service = "com.yinxia.app"
    private let account = "subsonic-credentials"
    
    func saveCredentials(_ credentials: ServerCredentials) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(credentials)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed
        }
    }
    
    func loadCredentials() -> ServerCredentials? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        
        let decoder = JSONDecoder()
        return try? decoder.decode(ServerCredentials.self, from: data)
    }
    
    func clearCredentials() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

enum KeychainError: Error {
    case saveFailed
    case loadFailed
}
