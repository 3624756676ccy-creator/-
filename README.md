# 番茄专注 · PomodoroFocus

一个好看、功能完整的 iOS 番茄钟，重点是**专注期间真的能挡住其它 App**（基于 Apple Screen Time 框架）。
纯 SwiftUI + ActivityKit，无第三方依赖，数据全部本地存储。

> 交付物是**完整的 Xcode 工程源码**。`.ipa` 必须在 macOS 上编译签名（iOS 应用无法在 Windows 上打包），
> 所以本仓库内置了 **GitHub Actions 流水线**，push 到 GitHub 后自动产出 IPA。

---

## 一、功能

### 计时
- 25 / 5 / 15 分钟默认时长，专注、短休息、长休息、长休息间隔、每日目标全部可调（1–120 分钟）
- 自动开始休息 / 自动开始下一个番茄
- 环形进度表盘：剩余时间从外环递减，运行时呼吸光晕
- **严格模式**：专注进行中不能暂停、重置、跳过；只有「长按 1.2 秒」才能放弃（防手滑、防作弊）
- 后台续跑：用绝对结束时间 `endDate` 计时，App 被杀掉再打开也能补算；结束后本地通知提醒
- 屏幕常亮开关、触感反馈、程序化合成的三音结束铃（无音频素材）

### 专注屏蔽（核心）
- `FamilyControls` 授权 → `FamilyActivityPicker` 选择要屏蔽的 **App / App 类别 / 网站**
- 专注开始 → `ManagedSettingsStore` 给选中的应用套上系统 Shield；专注结束/放弃 → 自动解除
- 屏蔽在 App 被切走后依然生效（由系统 Screen Time 守护，不是靠 App 在前台）
- 选择结果持久化，下次开机仍在

### 任务
- 任务清单：新建 / 勾选完成 / 右键（长按）删除 / 预计番茄数
- 点击卡片设为「当前专注任务」，专注完成自动给它 +1 番茄
- 每个任务显示完成度进度条

### 统计
- 今日番茄数、今日专注时长、连续打卡天数
- 最近 7 天柱状图（Swift Charts）
- 任务番茄排行条形图 + 本周总结文案

### 锁屏 / 灵动岛（Live Activity）
- 专注/休息开始时自动创建 Live Activity
- 锁屏卡片显示任务名、状态、原生倒计时（`Text(timerInterval:)`，无需后台刷新）
- 灵动岛：紧凑态显示图标+倒计时，展开态显示进度条
- 暂停时显示暂停态，结束时短暂显示「完成」后自动收起

### 视觉
- 深紫 → 酒红渐变背景 + 珊瑚色高亮，玻璃拟态卡片
- 圆角字体、等宽数字倒计时、自定义浮动 Tab Bar、Toast 提示
- App 图标为程序化绘制（`tools/make_icon.py` 可重新生成）

---

## 二、目录结构

```
PomodoroFocus/
├─ project.yml                     # XcodeGen 工程定义（唯一工程配置源）
├─ Shared/
│  └─ SessionAttributes.swift      # ActivityKit 属性（App + Widget 共用）
├─ PomodoroFocus/                  # 主 App target
│  ├─ App/PomodoroFocusApp.swift
│  ├─ Core/                        # AppModel（引擎）、统计、音效、噪音、通知、触感
│  ├─ Models/                      # Phase / FocusTask / SessionRecord / AppSettings
│  ├─ ScreenTime/                  # 屏蔽管理与选择器
│  ├─ LiveActivity/                # Live Activity 控制器
│  ├─ Views/                       # Root / Focus / Tasks / Stats / Settings
│  ├─ Design/                      # 主题、组件
│  └─ Assets.xcassets/             # AppIcon、AccentColor
├─ PomodoroWidget/                 # Widget 扩展 target（锁屏 + 灵动岛）
├─ .github/workflows/build-ipa.yml # 自动出 IPA
├─ docs/preview.html               # 设计预览（浏览器直接打开）
└─ tools/make_icon.py              # 图标生成脚本
```

---

## 三、拿 IPA 的两种方式

### 方式 A：GitHub Actions（无需 Mac，推荐）

1. 在 GitHub 新建一个空仓库（Private 也可以）
2. 把本目录所有文件推上去（`.github/` 必须包含）：

   ```bash
   cd PomodoroFocus
   git init
   git add .
   git commit -m "feat: pomodoro app"
   git branch -M main
   git remote add origin https://github.com/<你的账号>/<仓库名>.git
   git push -u origin main
   ```

3. 打开仓库 **Actions** → 选择 `Build IPA` → `Run workflow`（push 也会自动触发）
4. 跑完后在该次运行页面底部 **Artifacts** 下载 `PomodoroFocus-unsigned-ipa.zip`，解压得到
   `PomodoroFocus-unsigned.ipa`

> 流水线用 `CODE_SIGNING_ALLOWED=NO` 编译，产物是**未签名 IPA**，必须用下面的工具重签安装。

### 方式 B：Mac 本地编译

```bash
brew install xcodegen
cd PomodoroFocus
xcodegen generate
open PomodoroFocus.xcodeproj
```

- 真机运行：Xcode → Target `PomodoroFocus` → Signing & Capabilities → 选择你的 Team（免费 Apple ID 也能装，见限制说明）
- 出 IPA：`Product → Archive` → `Distribute App` → `Ad Hoc` / `Development`

命令行出未签名 IPA：

```bash
xcodebuild -project PomodoroFocus.xcodeproj -scheme PomodoroFocus \
  -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=""
mkdir -p out/Payload && cp -R build/Build/Products/Release-iphoneos/PomodoroFocus.app out/Payload/
cd out && zip -qry PomodoroFocus-unsigned.ipa Payload
```

---

## 四、安装到 iPhone

| 方式 | 说明 | 有效期 |
| --- | --- | --- |
| **Sideloadly**（Windows/Mac 都能用） | 拖入 IPA，填 Apple ID，自动重签并安装 | 免费账号 7 天，付费开发者 1 年 |
| **AltStore / SideStore** | 电脑做一次配对，手机端自签续期，可自动刷新 | 免费账号 7 天（可续） |
| **Xcode 直接 Run** | 连数据线，Xcode 跑到真机 | 同上 |
| **TestFlight / App Store** | 需要付费开发者账号 + 审核 | 长期 |

免费账号注意事项：
- 安装后需要在 iPhone `设置 → 通用 → VPN与设备管理` 里**信任**你的开发者证书
- Bundle ID 必须唯一（改 `project.yml` 里的 `PRODUCT_BUNDLE_IDENTIFIER` 为你自己的，例如 `com.你的名字.pomodorofocus`）
- 免费账号最多同时 3 个自签 App

---

## 五、关于「屏蔽 App」的真实限制（务必先读）

屏蔽依赖 Apple 的 **Screen Time API**，有两个硬性前提：

1. **必须是真机**，模拟器完全不支持。
2. **必须拥有 `com.apple.developer.family-controls` 能力**。这个 entitlement 需要向 Apple 提交申请并获批
   （个人开发者也可以申请，通过后同一 Team 的 App 才有资格调用 `AuthorizationCenter`）。

因此：

- 用付费开发者账号 + 获批 entitlement → 屏蔽完整可用。
- 用免费账号自签 / 未获批 → App 其余功能（计时、任务、统计、白噪音、Live Activity）**全部正常**，
  首次点「授权屏幕使用时间」会失败，界面会明确提示「未授权，屏蔽不可用」，不会崩溃。

工程内已把 `com.apple.developer.family-controls` 写进 entitlements（`project.yml` 的
`entitlements.properties`）。如果你的账号还没获批，把这个键删掉再编译，避免签名失败。

---

## 六、想改成自己的

| 想改的东西 | 位置 |
| --- | --- |
| App 名称 | `project.yml` → `CFBundleDisplayName` 与 `PRODUCT_NAME` |
| Bundle ID（自签必改） | `project.yml` → `PRODUCT_BUNDLE_IDENTIFIER`（两处：App 与 Widget，Widget 用 `.widget` 后缀） |
| 主题配色 | `PomodoroFocus/Design/Theme.swift` |
| 默认时长 / 目标 | `PomodoroFocus/Models/Phase.swift` → `AppSettings` |
| 图标 | `python tools/make_icon.py` 重新生成，或直接替换 `Assets.xcassets/AppIcon.appiconset/AppIcon.png`（1024×1024，**不要带透明通道**） |

---

## 七、常见问题

**Q：Actions 里 xcodebuild 报 team / signing 错误？**
流水线已关闭签名，一般不会。若报 `Unable to find a destination`，把 `runs-on` 换成 `macos-latest` 再跑。

**Q：装完打开就闪退？**
99% 是签名不完整。用 Sideloadly 重签，并在手机上信任证书；确认 Bundle ID 与自签时填写的一致。

**Q：Live Activity 不显示？**
需要 iOS 16.2+ 真机，且 `设置 → 番茄专注 → 实时活动` 打开；模拟器上灵动岛表现不稳定。

**Q：白噪音后台会停吗？**
已配置 `UIBackgroundModes: audio` + `.playback` 音频会话，锁屏后继续播放。计时本身基于结束时间，不受影响。

**Q：数据存在哪？**
全部在 `UserDefaults`（本机），不上传、不联网。
