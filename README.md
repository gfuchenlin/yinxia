# 音匣 (YinXia)

iOS 音乐播放器，专为 Navidrome / Subsonic 服务器设计。

## 功能特性

### MVP v0.1.1

- ✅ 单服务器 Navidrome/Subsonic 客户端
- ✅ 登录认证（Keychain 安全存储）
- ✅ 曲库浏览（专辑列表、专辑详情）
- ✅ 搜索功能（歌曲、专辑、艺术家）
- ✅ 歌单管理（查看、播放）
- ✅ 后台音频播放（AVPlayer + Now Playing 集成）
- ✅ 锁屏控制（MediaPlayer framework）
- ✅ 迷你播放器栏（56pt，悬浮在底部标签栏上方）
- ✅ 全屏播放界面
- ✅ 用户设置

### 技术实现

- **认证方式**: Subsonic Token Authentication (MD5 哈希 + salt)
- **音频引擎**: AVPlayer 实时流媒体播放
- **安全存储**: Keychain Services
- **最低系统**: iOS 17.0+
- **UI 框架**: SwiftUI
- **构建工具**: XcodeGen

### 布局规范

- 迷你播放器栏：56pt 高度
- 内边距：12pt
- 专辑封面（列表）：40pt × 40pt，圆角 6pt
- 专辑封面（正在播放）：屏幕宽度 - 40pt，圆角 12pt
- 标题字体：22pt Semibold
- 副标题字体：15pt Regular
- 主要控制按钮：64pt 触控区域

## 快速开始

### 前置要求

- macOS 13.0+
- Xcode 15.0+

### 方式一：直接打开（推荐）

项目已包含生成的 `.xcodeproj` 文件，可以直接打开：

```bash
open YinXia.xcodeproj
```

在 Xcode 中选择目标设备，然后点击运行（⌘R）。

### 方式二：使用 XcodeGen 重新生成

如果需要从 `project.yml` 重新生成项目：

1. **安装 XcodeGen**

```bash
brew install xcodegen
```

2. **生成 Xcode 项目**

```bash
xcodegen generate
```

3. **打开项目**

```bash
open YinXia.xcodeproj
```

## 项目结构

```
YinXia/
├── YinXiaApp.swift          # 应用入口
├── AppCore/                 # 核心应用逻辑
│   ├── AppState.swift       # 全局应用状态
│   ├── ContentView.swift    # 主视图
│   └── SharedViews.swift    # 共享 UI 组件
├── Auth/                    # 认证模块
│   ├── AuthService.swift    # Keychain 服务
│   └── LoginView.swift      # 登录界面
├── SubsonicAPI/             # Subsonic API 客户端
│   ├── SubsonicAPI.swift    # API 实现
│   └── Models.swift         # 数据模型
├── Library/                 # 曲库模块
│   ├── LibraryView.swift    # 曲库列表
│   └── AlbumDetailView.swift # 专辑详情
├── Search/                  # 搜索模块
│   └── SearchView.swift     # 搜索界面
├── Playlist/                # 歌单模块
│   └── PlaylistView.swift   # 歌单列表和详情
├── Player/                  # 播放器模块
│   ├── PlayerService.swift  # 播放器服务（AVPlayer）
│   ├── MiniPlayerBar.swift  # 迷你播放器栏
│   └── NowPlayingView.swift # 全屏播放界面
├── Settings/                # 设置模块
│   └── SettingsView.swift   # 设置界面
└── Assets.xcassets/         # 资源文件
    └── AppIcon.appiconset/  # App 图标（Logo 方案 E 最终版）
```

### 设计资源

- **App Icon**: Logo 方案 E 最终版
  - 渐变色：#4F46E5 → #C026D3（蓝紫到品红）
  - 白色圆角边框
  - 三条均衡器音柱设计
  - 1024x1024 主图 + 多尺寸适配（180/120/87/80/60/58/40/29px）

## 使用说明

### 首次登录

1. 启动应用后输入 Subsonic/Navidrome 服务器地址
2. 输入用户名和密码
3. 点击"登录"按钮

### 浏览音乐

- **曲库**：浏览服务器上的所有专辑
- **搜索**：搜索歌曲、专辑或艺术家
- **歌单**：查看和播放已创建的歌单
- **设置**：查看账户信息和退出登录

### 播放控制

- 点击歌曲开始播放
- 使用底部迷你播放器栏快速控制播放/暂停、切换歌曲
- 点击迷你播放器栏展开全屏播放界面
- 锁屏状态下可使用控制中心和锁屏控件

## 错误提示

应用使用中文错误提示，常见提示包括：

- `无法连接` - 服务器地址无法访问
- `账号或密码错误` - 认证失败
- `曲库为空` - 服务器上没有音乐内容
- `无匹配` - 搜索无结果
- `网络不可用` - 网络连接问题

## 限制说明

当前版本 **不包含** 以下功能：

- ❌ 多服务器支持
- ❌ 歌词显示
- ❌ 均衡器 (EQ)
- ❌ CarPlay 集成
- ❌ 完全离线模式（仅支持实时流媒体）

## 开发注意事项

### 在 Mac 上验证

由于项目使用 XcodeGen 生成，建议在 Mac 上使用 Xcode 进行以下验证：

- [ ] 构建成功（所有目标）
- [ ] 代码签名配置
- [ ] 真机测试
- [ ] 后台音频播放
- [ ] 锁屏控制
- [ ] 音频会话中断处理（来电、闹钟等）
- [ ] 内存使用情况
- [ ] 网络错误处理

### 配置 Bundle ID

在 `project.yml` 中修改 `bundleIdPrefix` 和 `PRODUCT_BUNDLE_IDENTIFIER`，然后重新运行 `xcodegen generate`。

## 许可证

此项目为个人学习项目。

## Cursor / 后续开发交接

详细现状、设计盖章、编译坑与待办见根目录 **[CURSOR-HANDOFF.md](./CURSOR-HANDOFF.md)**。  
当前开发分支：`cursor/yinxia-mvp-a794`（PR #1）。

## 贡献

欢迎提交 Issue 和 Pull Request。

---

**音匣** - 简洁优雅的 Subsonic 音乐播放器
