# 成绩系统 iOS App 工程 — 打包说明

这是一个 iOS App 壳：打开就是线上成绩系统 https://chengji.zhuoerx.cn ，和网页版连同一个服务器、同一个数据库，数据完全共通。App 名字「成绩系统」，图标是卓尔初阳 logo。导出 Excel 时会弹出系统分享面板，可以存到「文件」或发微信；支持下拉刷新和左右滑动返回。

> 说明：编译 iOS 应用必须用 Mac + Xcode。我这边是 Linux 环境，没法直接编译，所以把完整工程做好了，你用下面任意一种方式就能得到 IPA，再用你的自签方式签名安装。

## 方案 A：GitHub 云打包（推荐，不需要 Mac，免费）

1. 注册 GitHub 账号（github.com，免费），新建一个仓库（Repository），名字随意，例如 `zhuoer-score-app`，选 Public（公开仓库的 macOS 打包免费不限量；这个工程里只有公开网址，没有任何密钥）。
2. 把本工程的全部文件上传到仓库（网页上点 "uploading an existing file"，把文件夹里的文件拖进去；注意 `.github` 文件夹也要传，它是隐藏文件夹，拖整个文件夹上传时会自动带上）。
3. 打开仓库的 **Actions** 页 → 左侧选 "Build iOS IPA (unsigned)" → 点 **Run workflow**。
4. 等几分钟跑完，点进这次运行记录，页面下方 **Artifacts** 里下载 `ZhuoerScore-unsigned-ipa`，解压得到 `ZhuoerScore-unsigned.ipa`（未签名版）。

## 方案 B：本地 Mac + Xcode

1. 在 Mac 的 App Store 安装 Xcode（免费，体积较大，约 15GB）。
2. 双击打开 `ZhuoerScoreApp.xcodeproj`。
3. 左侧点项目 → TARGETS 里选 ZhuoerScoreApp → **Signing & Capabilities** → Team 选你的 Apple ID（免费账号选 Personal Team；付费开发者账号选你的团队）。
4. 顶部设备选你的 iPhone，点 ▶ 运行即可装到手机；要给别人装：Product → Archive → Distribute App → 按你的签名方式选（Ad Hoc / Development）导出 IPA。

## 签名安装（用你的自签条件）

- 拿到未签名 IPA 后，用你的自签工具（AltStore / Sideloadly / 签名平台等）签名安装即可。
- 免费 Apple ID 签名：7 天过期，需重签。
- 付费开发者账号 Ad Hoc：先把每台手机的 UDID 登记到账号里，签出的包能用 1 年。
- 签名平台（企业证书类）：直接上传未签名 IPA 即可，但证书有被封风险。

## 常用修改位置

- 打开的网址：`ZhuoerScoreApp/ContentView.swift` 第一行 `homeURL`。
- App 名字：工程 Build Settings 里的 `INFOPLIST_KEY_CFBundleDisplayName`（当前是「成绩系统」）。
- 图标：`ZhuoerScoreApp/Assets.xcassets/AppIcon.appiconset/` 里的 PNG，替换同名文件即可。
- Bundle ID：`cn.zhuoerx.chengji`（签名时如需改，在 Signing & Capabilities 里改）。

## 工程结构

- `ZhuoerScoreApp/` — App 源码（SwiftUI + WKWebView）
- `ZhuoerScoreApp.xcodeproj/` — Xcode 工程
- `.github/workflows/build-ios.yml` — GitHub 云打包配置
