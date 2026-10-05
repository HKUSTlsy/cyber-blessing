# 赛博祈福

轻量、离线的 macOS 菜单栏应用。虚拟上香、掷圣杯、敲木鱼与盘串一次呈现一种；仅供娱乐与仪式体验，不预测或保证现实结果。无需账号、网络或服务器。

## 下载测试版

[0.7.4 未公证测试版及源码下载](https://github.com/HKUSTlsy/cyber-blessing/releases/tag/v0.7.4)。选择 `CyberBlessing-0.7.4-macOS.zip` 获取应用，源码归档与对应 SHA-256 文件也在同一页面。

当前安装包未经 Developer ID 签名和 Apple 公证，Gatekeeper 评估拒绝，下载后可能无法直接打开。该发布标记为 Pre-release；需要常规安装体验时，应等待完成签名与公证的版本。


## 功能

- 顶部菜单直接选择四项仪式，弹窗宽度统一为 354 pt。
- 上香：有厚度与木粉纹理的线香；擦燃火柴、移近香头、接触点燃并移开，配套擦燃音效，约 2.2 秒后开始 30 分钟计时。燃烧期间可提前结束当前香以重新体验点香。线香渐短、半透明淡烟与香灰反馈。保存开始时间，关闭弹窗或退出后，下次打开仍按真实时间计算剩余时长。系统时间回拨时将进度限制为零，不显示负数或超长倒计时。
- 掷杯：平面与凸面采用独立透明素材；抛落、接触阴影与木音。落地时提交结果并保存最近一次结果；未落地时切换页面或关闭弹窗，会取消本次掷杯且不增加次数。
- 木鱼：点击器物或「敲一下」均计数 +1，独立功德浮层最多同时显示 24 条。音效预加载，最多六个木鱼声音并发；极快点击超出声音池时重用一个声道，计数仍完整保留。
- 盘串：鼠标放在手串画面内滚动滚轮或触控板，拇指随珠子运动拨动；滚动越密集，移动越快。18 颗黑檀色珠子沿闭合串线排列并分前后层穿过虎口，拇指柔性按压与回弹，累计拨珠次数本机保存。支持反向滚动，也可点击「拨一颗」或按空格。
- 设置：播放音效开关、音量、减少动态效果、累计上香/掷杯/功德/拨珠统计。本机持久化偏好；系统开启减少动态效果时也会遵循。
- 清空统计需确认，仅清空累计计数（含拨珠）和最近掷杯结果，保留正在燃烧的香与设置。
- 弹窗内快捷键：⌘1 上香、⌘2 掷杯、⌘3 木鱼、⌘4 盘串、⌘Q 退出。它们不是全局快捷键。

## 掷杯规则

采用一种常见的简化映射：一阴一阳为圣杯，两阳为笑杯，两阴为阴杯。平面朝上记为阳，凸面朝上记为阴。每枚杯独立公平随机，因此理论概率为圣杯 50%、笑杯 25%、阴杯 25%；不同传统可能采用不同解释。结果不作为现实决策依据。

## 燃香时长

「一炷香」不是固定的现代时间单位，燃烧时长受香的长短、风力和环境影响。本应用选用 30 分钟作为虚拟体验默认值，不表示所有真实香支都燃烧 30 分钟。

保留原项目参考：[中国日报网](https://language.chinadaily.com.cn/a/202107/05/WS60e24b84a310efa1bd65f9fa.html)、[澎湃新闻 / 方志大名](https://m.thepaper.cn/newsDetail_forward_14774034)。

## 环境与运行

- macOS 13 或更新版本。
- Swift 5.9+，macOS Command Line Tools 可构建并运行独立核心检查。
- 完整 XCTest 和 Xcode 调试需要包含相应测试框架的完整 Xcode。
- 双架构包包含 Apple Silicon arm64 与 Intel x86_64；当前机器的实际运行验证仅覆盖 arm64。

```bash
swift run CyberBlessing
./scripts/check.sh
```

也可在 Xcode 打开 `Package.swift`，选择 `CyberBlessing` scheme。完整测试环境运行 `swift test`；仅有 Command Line Tools 时使用 `swift run CyberBlessingChecks`，运行相同的 28 项回归检查，无需安装额外依赖。

不要搬运编译缓存到另一个目录。若旧项目包含失效的 `.build`，先将其移走再构建。源码 ZIP 不包含 `.build`、`.work` 或交付包。

## 版本与打包

唯一版本来源为 `Sources/CyberBlessing/Resources/VERSION`，界面与包信息均读取该版本。

```bash
./scripts/package-macos.sh
./scripts/verify-package.sh
```

可传入与 VERSION 一致的版本号和输出目录，例如 `./scripts/package-macos.sh 0.7.4 dist`；不一致时脚本立即报错。脚本采用独立构建目录，迁移项目后会自动退役旧打包缓存。

输出包括应用、双架构 macOS ZIP、源码 ZIP 及对应 SHA-256 文件。发布前检查版本、架构、全部素材、图标与签名，并验证 ZIP 解包后的应用。之前的默认应用移入 `dist/archive-*`，已有历史版本 ZIP 保留。

```bash
cd dist
shasum -a 256 -c CyberBlessing-0.7.4-macOS.zip.sha256
shasum -a 256 -c CyberBlessing-0.7.4-source.zip.sha256
```

包采用 ad-hoc 签名，未经 Developer ID 签名和 Apple 公证，系统 Gatekeeper 评估会拒绝它，下载后可能无法直接打开。当前仅作为明确标注的未公证测试包；要提供正常的公开安装体验，需要使用开发者账号完成 Developer ID 签名和 Apple 公证。源码发布不依赖这两项流程。

## 应用检查与证据

诊断模式使用独立的临时 UserDefaults，不改变用户数据。它验证真实控制器的连击、任务取消、点香阶段、实际嵌入的原生 NSEvent 滚轮输入、音效并发、资源加载，并保存四项功能、设置、点香各阶段和不同结果的原生渲染截图及 JSON 结果：

```bash
dist/CyberBlessing.app/Contents/MacOS/CyberBlessing --self-check .work/app-qa
```

该检查覆盖原生离屏渲染，不替代菜单栏真实点击、快捷键路由、VoiceOver、macOS 13 和 Intel 机器上的人工验收。

发布检查与已知验证边界见 [RELEASE_CHECK.md](RELEASE_CHECK.md)。

素材来源和图标再生成方法见 `ASSETS.md` 和 `ASSETS_0.7.0.md`；界面说明见 `DESIGN.md`。项目采用 MIT License，详见 `LICENSE`。
