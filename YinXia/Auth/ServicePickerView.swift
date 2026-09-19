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
        case .subsonic: return "自托管 · Subsonic API"
        case .navidrome: return "推荐 · 兼容 Subsonic"
        case .jellyfin: return "媒体服务器"
        case .emby: return "媒体服务器"
        }
    }
}

struct ServicePickerView: View {
    @State private var selectedService: MusicService?
    @State private var showConnectForm = false
    
    var body: some View {
        ZStack {
            // 深色背景 ~#0B1220
            Color(red: 0x0B / 255.0, green: 0x12 / 255.0, blue: 0x20 / 255.0)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 80)
                
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
                        .foregroundColor(.white)
                    
                    Text("连接音乐服务")
                        .font(.system(size: 17))
                        .foregroundColor(Color.white.opacity(0.6))
                }
                .padding(.top, 24)
                
                Spacer()
                
                // 服务卡片列表
                VStack(spacing: 12) {
                    ForEach(MusicService.allCases, id: \.self) { service in
                        ServiceCard(
                            service: service,
                            isSelected: selectedService == service
                        ) {
                            selectedService = service
                            showConnectForm = true
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer()
                
                // 页脚提示
                Text("仅连接你自己的服务器")
                    .font(.system(size: 14))
                    .foregroundColor(Color.white.opacity(0.5))
                    .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showConnectForm) {
            if let service = selectedService {
                ConnectFormView(service: service)
            }
        }
    }
}

struct ServiceCard: View {
    let service: MusicService
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 图标背景
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: service.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(service.rawValue)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(service.description)
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
        }
        .buttonStyle(PlainButtonStyle())
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
        ZStack {
            // 深色背景
            Color(red: 0x0B / 255.0, green: 0x12 / 255.0, blue: 0x20 / 255.0)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 导航栏
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("连接 \(service.rawValue)")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // 占位，保持标题居中
                    Color.clear
                        .frame(width: 44)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // 服务 Pill
                        HStack(spacing: 12) {
                            Image(systemName: service.icon)
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                            
                            Text(service.rawValue)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                        )
                        .padding(.top, 20)
                        
                        // 区块标题
                        Text("填写服务器信息")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.6))
                            .padding(.top, 8)
                        
                        // 服务器地址字段
                        VStack(alignment: .leading, spacing: 8) {
                            Text("服务器地址")
                                .font(.system(size: 14))
                                .foregroundColor(Color.white.opacity(0.6))
                            
                            TextField("https://music.example.com", text: $serverURL)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.URL)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.05))
                                )
                        }
                        
                        // 用户名字段
                        VStack(alignment: .leading, spacing: 8) {
                            Text("用户名")
                                .font(.system(size: 14))
                                .foregroundColor(Color.white.opacity(0.6))
                            
                            TextField("yourname", text: $username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.05))
                                )
                        }
                        
                        // 密码字段
                        VStack(alignment: .leading, spacing: 8) {
                            Text("密码")
                                .font(.system(size: 14))
                                .foregroundColor(Color.white.opacity(0.6))
                            
                            SecureField("••••••", text: $password)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.05))
                                )
                        }
                        
                        // 错误消息（内联红色）
                        if let error = errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 14))
                                
                                Text(error)
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(Color(red: 0xFF / 255.0, green: 0x45 / 255.0, blue: 0x45 / 255.0))
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0xFF / 255.0, green: 0x45 / 255.0, blue: 0x45 / 255.0).opacity(0.1))
                            )
                        }
                        
                        // 提示文字
                        Text("地址需包含协议，如 https://")
                            .font(.system(size: 13))
                            .foregroundColor(Color.white.opacity(0.5))
                        
                        // 连接按钮（紫色主色）
                        Button(action: connect) {
                            Group {
                                if isConnecting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("连接")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0x7C / 255.0, green: 0x3A / 255.0, blue: 0xED / 255.0),
                                                Color(red: 0x9F / 255.0, green: 0x5A / 255.0, blue: 0xFF / 255.0)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                        }
                        .disabled(serverURL.isEmpty || username.isEmpty || password.isEmpty || isConnecting)
                        .opacity((serverURL.isEmpty || username.isEmpty || password.isEmpty || isConnecting) ? 0.5 : 1.0)
                        .padding(.top, 8)
                        
                        // 改用其他服务
                        Button(action: { dismiss() }) {
                            Text("改用其他服务")
                                .font(.system(size: 15))
                                .foregroundColor(Color.white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
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
                errorMessage = "账号或密码错误，请检查后重试"
            } catch SubsonicError.connectionFailed {
                errorMessage = "无法连接服务器，请检查地址和网络"
            } catch SubsonicError.networkUnavailable {
                errorMessage = "网络不可用，请检查网络设置"
            } catch {
                let errorDesc = error.localizedDescription
                if errorDesc.contains("NSURLErrorAppTransportSecurityRequiresSecureConnection") ||
                   errorDesc.contains("cleartext") ||
                   errorDesc.contains("ATS") {
                    errorMessage = "需要使用 HTTPS 安全连接，或在设置中允许 HTTP 访问"
                } else {
                    errorMessage = "连接失败：\(errorDesc)"
                }
            }
            isConnecting = false
        }
    }
}
