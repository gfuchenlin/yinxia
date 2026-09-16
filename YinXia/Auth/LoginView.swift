import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var serverURL: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("音匣")
                    .font(.system(size: 48, weight: .bold))
                    .padding(.bottom, 32)
                
                VStack(spacing: 16) {
                    TextField("服务器地址", text: $serverURL)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    
                    TextField("用户名", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    SecureField("密码", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal, 32)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Button(action: login) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    } else {
                        Text("登录")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                }
                .background(Color.accentColor)
                .cornerRadius(12)
                .padding(.horizontal, 32)
                .disabled(isLoading || serverURL.isEmpty || username.isEmpty || password.isEmpty)
                
                Spacer()
            }
            .padding(.top, 100)
        }
    }
    
    private func login() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await appState.login(
                    serverURL: serverURL,
                    username: username,
                    password: password
                )
            } catch SubsonicError.authenticationFailed {
                errorMessage = "账号或密码错误"
            } catch SubsonicError.connectionFailed {
                errorMessage = "无法连接"
            } catch SubsonicError.networkUnavailable {
                errorMessage = "网络不可用"
            } catch {
                errorMessage = "登录失败：\(error.localizedDescription)"
            }
            isLoading = false
        }
    }
}
