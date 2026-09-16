import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
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
