import SwiftUI

struct SettingsHomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showDisconnectAlert = false
    @State private var loopMode: LoopMode = .list
    @State private var cacheSize: String = "0 MB"
    
    enum LoopMode: String, CaseIterable {
        case list = "列表循环"
        case single = "单曲循环"
    }
    
    var body: some View {
        NavigationView {
            List {
                // About 部分（移到顶部）
                Section {
                    aboutSection
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }
                
                // 服务器卡片
                Section(header: Text("服务器")) {
                    serverCard
                }
                
                // 循环模式
                Section(header: Text("播放")) {
                    Picker("循环模式", selection: $loopMode) {
                        ForEach(LoopMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                }
                
                // 缓存管理
                Section(header: Text("存储")) {
                    HStack {
                        Text("已用缓存")
                        Spacer()
                        Text(cacheSize)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("清除缓存") {
                        clearCache()
                    }
                    .foregroundColor(.blue)
                }
                
                // 外观
                Section(header: Text("外观")) {
                    HStack {
                        Text("主题")
                        Spacer()
                        Text("跟随系统")
                            .foregroundColor(.secondary)
                    }
                }
                
                // 版本
                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("0.1.1")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var aboutSection: some View {
        VStack(spacing: 16) {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0x4F / 255.0, green: 0x46 / 255.0, blue: 0xE5 / 255.0),
                        Color(red: 0xC0 / 255.0, green: 0x26 / 255.0, blue: 0xD3 / 255.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 80, height: 80)
                .cornerRadius(18)
                
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 50, height: 40)
                
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white)
                        .frame(width: 4, height: 16)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white)
                        .frame(width: 4, height: 24)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white)
                        .frame(width: 4, height: 16)
                }
            }
            
            VStack(spacing: 8) {
                Text("音匣")
                    .font(.system(size: 24, weight: .semibold))
                
                Text("装下你的每一首歌")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var serverCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(appState.currentServer ?? "未连接")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text(appState.username ?? "")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 20))
            }
            
            Button(action: {
                showDisconnectAlert = true
            }) {
                HStack {
                    Spacer()
                    Text("断开连接")
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .alert("确认断开", isPresented: $showDisconnectAlert) {
            Button("取消", role: .cancel) {}
            Button("断开", role: .destructive) {
                appState.logout()
            }
        } message: {
            Text("断开后需要重新选择服务并连接")
        }
    }
    
    private func clearCache() {
        // TODO: 实现清除缓存逻辑
        cacheSize = "0 MB"
    }
}
