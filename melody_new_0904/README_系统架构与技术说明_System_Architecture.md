## Melody · 系统架构与技术说明 (System Architecture & Technical Overview)

### 目录 (Table of Contents)
- **目标与概览 (Goals & Overview)**
- **系统架构 (Architecture)**
- **模块说明 (Modules)**
- **数据与状态 (Data & State Management)**
- **日历权限与使用 (Calendar Permissions & Usage)**
- **AI 推理服务集成 (AI Inference Integration)**
- **多媒体处理 (Media Handling)**
- **导航与路由 (Navigation & Routing)**
- **性能与稳定性 (Performance & Stability)**
- **可访问性与设计 (Accessibility & Design)**
- **安全与隐私 (Security & Privacy)**
- **构建与运行 (Build & Run)**
- **环境变量与 Info.plist (Env Vars & Info.plist)**
- **测试与故障排查 (Testing & Troubleshooting)**
- **Roadmap 与待办 (Roadmap & TODOs)**

---

### 目标与概览 (Goals & Overview)
Melody 是一款面向专注与身心放松的 iOS 应用。核心能力：
- 读取用户当日日历，结合时间空档进行本地与 AI 驱动的放松建议。
- 提供 5 种放松会话：深呼吸、冥想（种子生长动画）、音乐疗愈、拉伸视频、戳泡泡小游戏。
- 记录与可视化使用统计（天/周/月），支持数据导出与清理。

主要技术栈：SwiftUI、EventKit（日历）、AVFoundation/AVKit（音视频）、Charts（iOS16+）、UserDefaults（本地持久化）。

---

### 系统架构 (Architecture)

逻辑流转（简化）：
```
App (melody_newApp)
  └── RootView
        ├── SplashView (加载动画, AVPlayer)
        └── OnboardingView (首次启动) ──▶ completeOnboarding()
               │
               ▼
            MelodyAppView
               │
               ▼
            MainView
               ├── 顶部问候 (AI / 本地)
               ├── 扇形 5 卡 (深呼吸/种子/音乐/运动/戳泡泡)
               │     └── 导航到对应会话页面 (NavigationDestination)
               ├── 旋钮联动选择 (触控/拖拽)
               └── 日程条 + 今日事件列表

会话页面:
  - BreathingSessionView (倒计时 + 呼吸动画)
  - MeditationSessionView (种子 → 幼苗 → 成熟动画)
  - MusicSessionView (音频播放 + 倒计时 + 完成庆祝)
  - StretchSessionView (视频循环播放)
  - BubbleSessionView (物理泡泡 + 打击反馈 + 结束页)

个人中心:
  - ProfileView (总览、7/30天图表、导出/清理、设置、历史)
    - SettingsView / DataHistoryView / AboutView

数据持久化:
  - RelaxStatsStore (UserDefaults, 线程安全队列、按天聚合)
```

核心目录：
```
melody_new/
  melody_newApp.swift        # @main, RootView/Splash/Onboarding 路由
  melodyMain.swift           # MainView 主页、AI/日历/导航/动画
  OnboardingView.swift       # 4 页引导与动效
  BackButton.swift           # 统一返回按钮组件
  RelaxStatsStore.swift      # 会话与按日统计的本地存储
  ProfileView.swift          # 个人中心/设置/数据历史/导出
  BreathingSessionView.swift # 深呼吸
  MeditationSessionView.swift# 冥想
  MusicSessionView.swift     # 音乐
  StretchSessionView.swift   # 拉伸视频
  BubbleSessionView.swift    # 戳泡泡
  OtherTabs.swift            # 占位页面（Discover/Insights等）
  Assets.xcassets            # 引导、卡片、音乐、视频等资源
```

---

### 模块说明 (Modules)
- `RootView`：应用入口状态机。控制 Splash → Onboarding → 主应用的切换；首次完成后持久化 `hasCompletedOnboarding`。
- `OnboardingView`：4 张全屏插画+文字掉落动画，点击逐步揭示或翻页。
- `MainView`：
  - 日历授权与事件抓取（EventKit）。
  - 顶部 AI 问候（短句）与“休息模式”放松建议。
  - 扇形 5 卡 + 旋钮联动选择与导航。
  - 今日事件列表与时间条 `ScheduleBar`。
- 会话页：
  - `BreathingSessionView`：倒计时、呼吸环形渐变动画、完成写入统计。
  - `MeditationSessionView`：点击推进 5 阶段成长图、完成写入统计。
  - `MusicSessionView`：AVAudioSession + AVAudioPlayer 播放 `music`，倒计时到零或手动完成 → 记录统计 → 庆祝视图/返回。
  - `StretchSessionView`：`NSDataAsset` 写入临时文件 + AVPlayerLayer `.resizeAspectFill` 循环播放 `stretch` 视频。
  - `BubbleSessionView`：物理移动/边界反弹/打爆动画/得分计时，结束跳转 `SessionEndView`（小狗视频）。
- `ProfileView`：总览/趋势/成就/快速操作；设置（通知、目标、偏好、数据管理）；数据历史（时间范围、类型分布、最近会话）。
- `RelaxStatsStore`：线程安全（串行队列）读写 UserDefaults，提供：
  - `addSession()`、`minutes(on:)`、`sessionsCount(on:)`
  - `last7DaysStats()` / `last30DaysStats()`、`getAllSessions()`
  - `getTotalStats()`、`calculateStreakDays()`、`getSessionTypeStats()`

---

### 数据与状态 (Data & State Management)
- SwiftUI `@State`/`@AppStorage`/`@Environment`：用于页面交互、导航状态、首启标记。
- `RelaxStatsStore`：
  - 存储键：`relax_daily_stats`、`relax_sessions`。
  - 结构：`SessionRecord`（类型/时长/时间/完成标记）、`DayStats`（分钟数/会话数/类型分布）。
  - 缓存：内存缓存 + 5 分钟有效期，减少 UserDefaults 解码频率。
  - 迁移：从旧 `relax_minutes_by_day` 聚合分钟数迁移生成估算会话。

---

### 日历权限与使用 (Calendar Permissions & Usage)
- 依赖 `EventKit`：
  - 首次请求 `.event` 权限，拒绝时在 UI 反馈并提示设置开启。
  - 读取“当天所有事件”→ 构造文本/区间进行：
    - 顶部问候/短荐内容生成
    - 根据可用空档本地计算推荐卡（时间窗口 → 放松类型）
- Info.plist 需包含：
  - `NSCalendarsUsageDescription`：说明用途的中文文案。

---

### AI 推理服务集成 (AI Inference Integration)
- 目标：生成短句问候/放松建议、选择最合适的放松卡片索引。
- 优先级与回退：
  1) ModelScope `https://api-inference.modelscope.cn`（多鉴权：`Authorization: Bearer` / `X-API-Key` / URL 参数），多个请求体（OpenAI Chat / legacy）；
  2) 无 Token 时回退 SiliconFlow `https://api.siliconflow.cn`。
- Token 读取顺序：环境变量 → Info.plist（均支持两个主备）。
  - `MODELSCOPE_API_TOKEN`, `MODELSCOPE_API_TOKEN_2`
  - `SILICONFLOW_API_TOKEN`
- 重试与健壮性：
  - 多 endpoint + 多鉴权头组合尝试；
  - 失败时收集原因并在 UI 以失败消息反馈；
  - 对问候卡有 30 分钟刷新节流；休息模式下不刷新。
- 安全文本：仅发送“当日日程的文本化摘要”（标题/时间），不上传本地统计或隐私标识符。

---

### 多媒体处理 (Media Handling)
- 视频：
  - `SplashView` / `StretchSessionView` 使用 `NSDataAsset` → 写入 `temporaryDirectory` 生成临时 URL → `AVPlayerLayer` 播放，强制 `videoGravity = .resizeAspectFill` 避免黑边。
  - `SessionEndView` / `CelebrationView` 读取 `dog.mov`（建议统一放入 `Assets.xcassets/dog.dataset` 并走同一临时文件方案）。
- 音频：
  - `MusicSessionView` 先尝试 `NSDataAsset(name: "music")`，回退 `Bundle` 中的 `music.mp3`；`AVAudioSession` `.playback` 类别。

---

### 导航与路由 (Navigation & Routing)
- `NavigationStack` + `navigationDestination(isPresented:)`：从 MainView 的卡片点击进入对应会话。
- `ProfileView` 从主页头像按钮进入。
- 结束流程：会话完成写入统计后返回或进入庆祝/结束页，再返回主页。

---

### 性能与稳定性 (Performance & Stability)
- 动画：统一 `Motion` 常量（弹簧/透明度），尽量使用轻量动画与合适的 damping，避免布局抖动。
- 计时器：主页定时检查日程（5 分钟）、问候刷新（30 分钟）进入/退出页面时清理；会话内 1s 定时器驱动倒计时。
- 视频：采用 `AVPlayerLayer` + `resizeAspectFill`，避免 `VideoPlayer` 的黑边与控制条成本。
- 数据：UserDefaults + 内存缓存（5 分钟）减少序列化开销；所有存储操作走串行队列确保线程安全。

---

### 可访问性与设计 (Accessibility & Design)
- 色彩：与主色系（橙/绿/米黄）一致，高对比度按钮与标签。
- 文本：问候卡打字机动画支持收起/展开，行高/最小高度防止回流。
- 触觉：关键交互（选择卡片、完成会话、设置切换）提供 `UIImpactFeedbackGenerator`/`UINotificationFeedbackGenerator`。
- 动效：Onboarding 文字掉落、扇形卡缩放与旋转、泡泡物理反弹与爆破等，保证 60fps。

---

### 安全与隐私 (Security & Privacy)
- Token/秘钥：不硬编码，优先从环境变量读取，其次 Info.plist（开发便捷）。
- 日历数据：仅在本地分析并构造“当日文本摘要”用于 AI 推理；不上传历史统计与标识符。
- 本地数据：UserDefaults 存放非敏感统计；提供“一键清理”。

---

### 构建与运行 (Build & Run)
前置环境：
- Xcode 15+，iOS 16+（Charts 用于 16+，旧版本有降级实现）。

运行步骤：
1) 在 Xcode Scheme 中设置环境变量（可选但推荐）：
   - `MODELSCOPE_API_TOKEN` / `MODELSCOPE_API_TOKEN_2`
   - `SILICONFLOW_API_TOKEN`
2) 或在 Info.plist 添加同名键（开发/演示场景）：
   - `MODELSCOPE_API_TOKEN` / `MODELSCOPE_API_TOKEN_2` / `SILICONFLOW_API_TOKEN`
3) 确认 Info.plist 含有：`NSCalendarsUsageDescription`。
4) 资源检查：`Assets.xcassets` 中的 `onboarding1-4`、`card_*`、`seed1-5`、`music`、`loading_animation`、`stretch`、`logo` 等需在 Target → Build Phases → Copy Bundle Resources 中。
5) 选择 `melody_new` 目标，Run。

---

### 环境变量与 Info.plist (Env Vars & Info.plist)
示例（Scheme → Run → Arguments → Environment Variables）：
```text
MODELSCOPE_API_TOKEN=ms-xxxxxxxxxxxxxxxx
MODELSCOPE_API_TOKEN_2=ms-xxxxxxxxxxxxxxxx
SILICONFLOW_API_TOKEN=sk-xxxxxxxxxxxxxxxx
```

Info.plist 关键项：
```xml
<key>NSCalendarsUsageDescription</key>
<string>读取您的当日日程以生成个性化放松建议</string>

<key>MODELSCOPE_API_TOKEN</key>
<string>（可选）开发期占位或从Scheme注入</string>
<key>MODELSCOPE_API_TOKEN_2</key>
<string>（可选）开发期占位或从Scheme注入</string>

<key>SILICONFLOW_API_TOKEN</key>
<string>（可选）开发期占位或从Scheme注入</string>
```

---

### 测试与故障排查 (Testing & Troubleshooting)
- 常见问题：
  - 启动页无动画：确认 `Assets.xcassets/loading_animation.dataset` 存在且可读；模拟器偶发 `NSDataAsset` 读取失败时，可清理 DerivedData 或真机测试。
  - 音乐无声：检查 `AVAudioSession` 权限与系统音量；确认 `music` 资产或 `Bundle` 中 `music.mp3` 存在。
  - 日历为空：确认已授权 EventKit，并在系统“日历”中确有当天事件。
  - AI 响应为空/401：确认 Token 与模型权限；可切换至 SiliconFlow 作为回退。
  - 资源缺失：确保所有图片/视频均被加入目标资源。

---

### Roadmap 与待办 (Roadmap & TODOs)
- 统一 `dog.mov` 资源为 data asset，并与 `SplashView`/`StretchSessionView` 复用同一临时文件播放路径。
- 问候卡添加“刷新/重试”按钮与网络失败重试提示。
- 旋钮触点中心通过几何计算（替代硬编码坐标），增强屏幕适配性。
- 增加更丰富的统计维度（每日目标达成率、最长专注/休息节律）。
- 引入单元/快照测试覆盖核心数据层与关键 UI 状态机。

---

### 致谢 (Credits)
- SwiftUI / EventKit / AVFoundation / AVKit / Charts
- 所有插画与多媒体素材由项目资源 `Assets.xcassets` 提供


