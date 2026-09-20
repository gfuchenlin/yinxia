# 音匣 · Cursor 交接说明

> 给后续 Cursor / 云端 Agent 的项目备注。更新：2026-09-20（小戴）  
> 仓库：https://github.com/gfuchenlin/yinxia  
> 当前工作分支 / PR：`cursor/yinxia-mvp-a794` · https://github.com/gfuchenlin/yinxia/pull/1  
> 本地路径（用户 Mac）：`/Users/fuchenlin/Documents/tempwork/yinxia`  
> 设计原型（用户 Mac）：`/Users/fuchenlin/Documents/tempwork/yinxia-prototype/`

---

## 1. 产品是什么

- App 名：**音匣**（YinXia）
- 对标「音流」类：连接**自建** Navidrome / Subsonic，管理并播放本地曲库
- 技术栈：Swift / SwiftUI，iOS 17+
- 当前阶段：MVP（单服务器，真 API 可播）

### 团队角色（Grok Bot / Agent）

| 角色 | 职责 |
|---|---|
| 小付 | 产品：范围、优先级、验收 |
| 小杨 | UI/UX：线框、盖章规格、视觉验收 |
| **小戴（本 iOS）** | 工程实现、PR、编译修复 |
| 小李 | 测试清单、真机/弱网 |

---

## 2. 打开与编译（Mac）

```bash
cd /Users/fuchenlin/Documents/tempwork/yinxia
git checkout cursor/yinxia-mvp-a794
git pull
open YinXia.xcodeproj
```

- 已提交 `YinXia.xcodeproj`，**不必**本地再跑 XcodeGen 才能打开（`project.yml` 仍保留，可选 `xcodegen generate`）
- Bundle ID：`com.yinxia.app`；展示名「音匣」
- 最低系统：iOS 17
- Info.plist 已开 ATS：`NSAllowsArbitraryLoads` + `NSAllowsLocalNetworking`（自建 Navidrome 常用 `http://`）

### 历史编译坑（已修，勿回退）

1. **新 Swift 文件未进 Compile Sources**  
   - 现象：`Cannot find 'SettingsHomeView' / 'ServicePickerView' in scope`  
   - 原因：`pbxproj` 有 FileRef/BuildFile，但未进 `PBXSourcesBuildPhase`  
   - 规则：**每加一个 `.swift`，必须同时进 Sources 列表**；改完用脚本核对「磁盘 Swift 数 == Sources 数」

2. **`AlbumGridItem` 重复定义**  
   - 曾同时存在于 `LibraryView.swift` 与 `AlbumsGridView.swift`  
   - 只保留网格页那份；`LibraryView` 仅作 `LibraryHomeView` 包装

3. **`PlayerService` 私有 init**  
   - 用 `PlayerService.shared`，不要 `PlayerService()`

---

## 3. 工程结构（以磁盘为准，2026-09-20）

```
YinXia/
├── AppCore/
│   ├── AppState.swift
│   ├── ContentView.swift
│   └── SharedViews.swift
├── Assets.xcassets/
├── Auth/
│   ├── AuthService.swift
│   ├── LoginView.swift
│   └── ServicePickerView.swift
├── Library/
│   ├── AlbumDetailView.swift
│   ├── AlbumsGridView.swift
│   ├── AllSongsView.swift
│   ├── ArtistDetailView.swift
│   ├── ArtistsListView.swift
│   ├── DetailComponents.swift
│   ├── GenresGridView.swift
│   ├── LibraryHomeView.swift
│   └── LibraryView.swift
├── Player/
│   ├── MiniPlayerBar.swift
│   ├── NowPlayingView.swift
│   └── PlayerService.swift
├── Playlist/
│   └── PlaylistView.swift
├── Search/
│   └── SearchView.swift
├── Settings/
│   ├── SettingsHomeView.swift
│   └── SettingsView.swift
├── SubsonicAPI/
│   ├── Models.swift
│   └── SubsonicAPI.swift
├── Info.plist
├── LaunchScreen.storyboard
└── YinXiaApp.swift
```

导航壳：未登录 → **选服务 → 连接表单**；已登录 → 三 Tab（搜索 / 曲库 / 设置）+ 迷你条。


---

## 4. 设计盖章（必须遵守）

### 4.1 原型唯一源

- HTML 分页原型：`yinxia-prototype/pages/`（可点）
- 连接规格一页纸：`yinxia-prototype/CONNECT-SPEC.md`（小杨 2026-09-19 盖章）
- Token：`yinxia-prototype/shared.css` 顶部变量
- PNG 对照：`assets/connect.png` / `connect-form.png` / `connect-fail.png` / `splash.png`
- 设计盖章清单（摘要）：启动→选服务→连接→成功→曲库，**禁直达曲库**

### 4.2 连接流（两页，禁止合成系统 Form）

1. **选服务**（`connect`）  
   - 头：「音匣 / 添加资料库」（以 CONNECT-SPEC 与最新实现为准）  
   - 服务卡片列表；Navidrome 副文侧重「推荐 · 兼容 Subsonic」

2. **连接表单**（`connect-form`）  
   - 大标题：**「连接 {服务}」**（**不要**「连接到 …」）  
   - 顶栏：仅返回，不要 Large Title / 居中系统标题  
   - 主按钮在页面流内，不靠 toolbar

### 4.3 连接页 Token（盖章）

| Token | 值 |
|---|---|
| 背景 | `#0C0E16` |
| 卡片 / 输入 | `#1B2030` |
| 主色 | `#6D4DFF`（单色，非渐变） |
| 正文 | `#F5F7FB` |
| 次要 | `#8D93A8` |

尺寸要点：标题 28 Semibold 左对齐；输入高 ~48、圆角 12、padding 14；主按钮高 50、圆角 14；Hint「地址需含协议，如 https://」；Ghost「改用其他服务」。

### 4.4 其它已盖章产品/设计点

- 底栏三 Tab：搜索 / 曲库 / 设置  
- 曲库六宫格：歌曲 / 我喜欢的 / 本地音乐 / 专辑 / 流派 / 歌手  
- 「全部播放」= **追加队列**（不替换）  
- 三级详情：见原型 `DETAIL-SPEC.md` / 仓库外设计文档；详情页隐藏 Tab + 迷你条  
- Slogan：「装下你的每一首歌」（关于页 / 启动页）  
- App Icon：Logo E；LaunchScreen 中文用 Label，勿把中文烤进缺字体的位图

---

## 5. 已完成（PR 分支上）

- [x] Xcode/SwiftUI 骨架 + 模块拆分  
- [x] Subsonic 登录（Keychain）+ 真机可连 Navidrome  
- [x] 曲库六宫格 → 列表/详情 → 可播  
- [x] 搜索点播改为**追加**队列  
- [x] 迷你条 / 锁屏播控骨架  
- [x] 设置关于页 Slogan、清除缓存等  
- [x] `pbxproj` Sources 补齐（25 个 Swift）  
- [x] Auth UI 按盖章重做深色两页 + ATS 明文 HTTP  
- [x] 去掉 `AlbumGridItem` 重复定义  

近期相关提交（节选）：

- `87c5c0c` fix: PBXSourcesBuildPhase 补文件  
- `40ed5d3` feat: 深色 Auth UI + ATS  
- `26be166` fix: 严格对齐小杨盖章 token/文案/尺寸  

---

## 6. 建议下一步（给 Cursor 的任务优先级）

### P0（先做）

1. **真机冒烟**：选服务 → 连 `http://…:4533` Navidrome → 六宫格进专辑连续播 → 后台/锁屏  
2. **对照 `CONNECT-SPEC.md` / `connect-form.html` 视觉 diff**：有偏差按规格改，改完贴截图给小杨验收  
3. **确认所有新 Swift 仍在 Sources**（防回归）

### P1

4. 三级详情与 `DETAIL-SPEC` 逐条对齐（封面尺寸、全部播放文案「共 N 首」、行副信息、⋯ 操作）  
5. 空态 / 弱网 / 连接失败页对齐原型  
6. 本地音乐入口：页壳 + 占用示意即可（完整导入非 MVP）  
7. Jellyfin / Emby：UI 可留，后端未接则「即将支持」，勿假装已通

### P2 / 非 MVP

- 多服务器、歌词、EQ、CarPlay、完整离线缓存策略、循环模式完整重放逻辑  

---

## 7. 给 Cursor Agent 的约束

1. **改仓库用 Cloud Agent / PR 分支**，保持 `cursor/yinxia-mvp-a794`（或用户指定分支），不要 silent force-push main  
2. **UI 以小杨盖章与 HTML 原型为准**，不要用系统 `Form { Section }` 冒充连接页  
3. **新增 `.swift` 必须写入 `project.pbxproj` 的 Sources**；改完核对数量  
4. 中文文案与产品一致；错误提示用中文  
5. 自建服场景保留 HTTP ATS 例外，直到产品明确收紧为仅 HTTPS  
6. 「全部播放」保持**追加**语义（CR/产品已定）  

### 建议开场 Prompt（可复制）

```
仓库 https://github.com/gfuchenlin/yinxia
分支 cursor/yinxia-mvp-a794
先读 CURSOR-HANDOFF.md 与用户机上的 yinxia-prototype/CONNECT-SPEC.md。

任务：…
验收：…
```

---

## 8. 相关链接与路径速查

| 项 | 位置 |
|---|---|
| GitHub | https://github.com/gfuchenlin/yinxia |
| PR | https://github.com/gfuchenlin/yinxia/pull/1 |
| 本地工程 | `/Users/fuchenlin/Documents/tempwork/yinxia` |
| 设计原型 | `/Users/fuchenlin/Documents/tempwork/yinxia-prototype` |
| 连接规格 | `…/yinxia-prototype/CONNECT-SPEC.md` |
| 本交接文档 | 仓库根目录 `CURSOR-HANDOFF.md` |

---

**音匣** — 装下你的每一首歌
