import SwiftUI

enum MusicService: String, CaseIterable {
    case subsonic = "Subsonic"
    case navidrome = "Navidrome"
    case jellyfin = "Jellyfin"
    case emby = "Emby"
    
    var icon: String {
        switch self {
        case .subsonic: return "music.note.house"
        case .navidrome: return "waveform"
        case .jellyfin: return "play.square.stack"
        case .emby: return "sparkles.tv"
        }
    }
    
    var description: String {
        switch self {
        case .subsonic: return "Subsonic 兼容服务器"
        case .navidrome: return "推荐 Navidrome 服务器"
        case .jellyfin: return "Jellyfin 媒体服务器"
        case .emby: return "Emby 媒体服务器"
        }
    }
}

struct ServicePickerView: View {
    @State private var selectedService: MusicService?
    @State private var showConnectForm = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                // Logo
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0x4F / 255.0, green: 0x46 / 255.0, blue: 0xE5 / 255.0),
                            Color(red: 0xC0 / 255.0, green: 0x26 / 255.0, blue: 0xD3 / 255.0)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 100, height: 100)
                    .cornerRadius(22)
                    
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 60, height: 48)
                    
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white)
                            .frame(width: 5, height: 20)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white)
                            .frame(width: 5, height: 28)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white)
                            .frame(width: 5, height: 20)
                    }
                }
                
                VStack(spacing: 8) {
                    Text("音匣")
                        .font(.system(size: 32, weight: .semibold))
                    
                    Text("选择您的音乐服务")
                        .font(.system(size: 17))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 服务列表
                VStack(spacing: 12) {
                    ForEach(MusicService.allCases, id: \.self) { service in
                        ServiceButton(
                            service: service,
                            isSelected: selectedService == service
                        ) {
                            selectedService = service
                            showConnectForm = true
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showConnectForm) {
            if let service = selectedService {
                ConnectFormView(service: service)
            }
        }
    }
}

struct ServiceButton: View {
    let service: MusicService
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: service.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.primary)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(service.rawValue)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(service.description)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct ConnectFormView: View {
    let service: MusicService
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    @State private var serverURL = ""
    @State private var username = ""
    @State private var password = ""
    @State private var isConnecting = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Image(systemName: service.icon)
                        Text(service.rawValue)
                            .font(.headline)
                    }
                }
                
                Section(header: Text("服务器信息")) {
                    TextField("服务器地址", text: $serverURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    
                    TextField("用户名", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    SecureField("密码", text: $password)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button(action: connect) {
                        if isConnecting {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            HStack {
                                Spacer()
                                Text("连接")
                                Spacer()
                            }
                        }
                    }
                    .disabled(serverURL.isEmpty || username.isEmpty || password.isEmpty || isConnecting)
                }
            }
            .navigationTitle("连接到 \(service.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func connect() {
        isConnecting = true
        errorMessage = nil
        
        Task {
            do {
                try await appState.login(
                    serverURL: serverURL,
                    username: username,
                    password: password
                )
                dismiss()
            } catch SubsonicError.authenticationFailed {
                errorMessage = "账号或密码错误"
            } catch SubsonicError.connectionFailed {
                errorMessage = "无法连接"
            } catch SubsonicError.networkUnavailable {
                errorMessage = "网络不可用"
            } catch {
                errorMessage = "连接失败：\(error.localizedDescription)"
            }
            isConnecting = false
        }
    }
}
