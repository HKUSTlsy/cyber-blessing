# 素材与图标

现有器物和音效保留原文件。新增 `Sources/CyberBlessing/Resources/jiaobei_flat.png` 使用内置 imagegen 生成，以原 `jiaobei_block.png` 为编辑参考，作为平面朝上的阳面。生成后等比缩小至最长边 760 px，保留透明背景；凸面仍使用原素材。原始生成文件保留在 Codex generated_images 下，项目不依赖该外部路径。

生成提示词：

> Use case: precise-object-edit. Asset type: transparent macOS app ritual sprite. Create the OTHER face of exactly this red rosewood crescent jiaobei divination block: turn the block over so the broad FLAT CUT PLANE faces upward and toward the viewer, with a thin curved convex underside barely visible beneath the edge. This upper face must be clearly flat, satin polished, with uninterrupted red-brown longitudinal fine wood grain and uniform soft reflection, NOT a bulging dome. Preserve crescent contour, wood species, red-brown hue, lighting direction and approximate left-to-right orientation from reference. Low oblique product photography viewpoint, single object fully in frame, 8% transparent margins, truly transparent background, no floor, no shadows on background, no text, no other objects. Match reference sprite for consistent pair of physical faces.

应用图标由 `scripts/generate-icon.swift` 使用 AppKit 原生路径绘制，输出标准 iconset，再用 macOS `iconutil` 转为 `AppIcon.icns`。需要重绘时运行：

```bash
swift scripts/generate-icon.swift .work/AppIcon.iconset
iconutil -c icns .work/AppIcon.iconset -o Sources/CyberBlessing/Resources/AppIcon.icns
```

## 0.7.0 更新

新增线香与手部素材、音效来源和提示词见 [ASSETS_0.7.0.md](ASSETS_0.7.0.md)。

## 原有素材的分发确认

2026-10-05，项目提供者确认原有香炉、线香、木鱼、木槌、圣杯图片和 `woodfish-tap.wav` 为其自行制作或生成，可随项目发布。此说明记录提供者的来源与分发确认，不将未提供的具体生成工具或第三方授权证明写成已核验事实。新增素材的制作方式及提示词如上文与 `ASSETS_0.7.0.md` 所述。


## README 网站展示图片

`docs/images/mylsyai-home.png` 与 `docs/images/mylsyai-products.png` 为 2026-10-05 对作者个人网站 https://mylsyai.com 的公开页面截图，分别展示首页横幅和套餐列表。使用中文界面，无登录操作。仅用于 README 网站介绍，不属于应用运行素材；价格及套餐以网站实时页面为准。
