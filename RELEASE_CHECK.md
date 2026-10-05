# GitHub 发布前检查（0.7.4）

检查日期：2026-10-05。本地技术与交付检查已完成；随后开始准备 GitHub 源码及未公证测试版发布。

## 已完成的准备

- 检查源码、状态持久化、任务取消、资源加载、声音池和当前交互回归。
- 修正文档旧版本示例及已移除火星的描述；原有素材由提供者确认自行制作或生成、可随项目发布。
- 应用包补 MIT 许可证，移除本机构建路径；包验证包含版本、图标、全部资源、双架构最低 macOS 13 和签名。
- 最终包与源码归档检查结果、核心和应用运行结果保存于 `dist/CyberBlessing-0.7.4-QA`；具体数目与限制见该目录的 VALIDATION.md 和 JSON。

## 发布尚需处理

- 已初始化本地 `main` 分支，计划发布至 `HKUSTlsy/cyber-blessing`。仓库创建、推送和 Release 上传依赖 GitHub CLI 的本人设备授权。
- 应用是 ad-hoc 签名、未公证的测试包，Gatekeeper 评估拒绝。GitHub 可以托管源码和明确标注的测试包；正常的公开安装体验还需要 Developer ID 签名和 Apple 公证，当前没有对应账号凭证。
- 当前仅在 Apple Silicon/macOS 26 实际运行；Intel/macOS 13、菜单栏物理交互与快捷键、VoiceOver 和长时间使用仍需人工验收。
- 拇指形变使用 CIWarpKernel(source:)，当前 SDK 发出弃用警告；已验证本机可用。后续完整 Xcode 环境可迁移到 Metal 内核。

## 建议作为 Release 附件的文件

- `CyberBlessing-0.7.4-macOS.zip` 和对应 `.sha256`
- `CyberBlessing-0.7.4-source.zip` 和对应 `.sha256`

发布正文采用 RELEASE_NOTES_0.7.4.md。源码不要包含 `.work`、`.build` 或整个 `dist` 历史归档。`--self-check` 使用隔离的 UserDefaults，不修改真实用户统计。
