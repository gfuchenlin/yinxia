import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
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
                    .listRowBackground(Color.clear)
                }
                
                Section {
                    HStack {
                        Text("服务器")
                        Spacer()
                        Text(appState.currentServer ?? "")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("用户名")
                        Spacer()
                        Text(appState.username ?? "")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("退出登录")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
                
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
            .alert("确认退出", isPresented: $showLogoutAlert) {
                Button("取消", role: .cancel) {}
                Button("退出", role: .destructive) {
                    appState.logout()
                }
            } message: {
                Text("退出登录后需要重新输入账号密码")
            }
        }
    }
}
