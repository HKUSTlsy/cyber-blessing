# 0.7.0 素材说明

使用内置 imagegen 制作两个透明素材，保留 0.6.0 素材和源码备份。素材均复制进项目 Resources，不依赖 Codex 外部缓存。手部照片在界面中以遮罩分成手掌与可运动的拇指，珠子由原生 SwiftUI 分层绘制。

- `Sources/CyberBlessing/Resources/incense_unlit.png`：未点燃的木粉线香。界面取中央区域保持香体厚度，按进度裁短，动态火星单独绘制。
- `Sources/CyberBlessing/Resources/bead_hand.png`：盘串手部，等比缩小至最长边 900 px。

## 线香提示词

Use case: product-mockup. Transparent game/UI sprite of one UNLIT cylindrical sandalwood incense stick, vertically upright. Macro product photography, tangible thick round woody core, granular brown compressed wood powder coating, a clear soft side highlight and shaded right edge, flat dark brown unburnt tip at top, short pale bamboo foot at bottom. NO ember, NO ash, NO smoke, NO flame. One straight upright stick; slender real incense not a line or wire, width-to-height of the visible stick about 1:15. The stick fills 90% of image height centered on transparent background, entire stick visible. Strong legible cylindrical texture at small app UI scale, warm soft light from upper left. No text, no other objects, no floor, no background shadow.

## 手部提示词

Use case: product-mockup. Asset type: isolated hand sprite for an interactive prayer-beads desktop app. Photoreal adult left hand in a relaxed bead-rolling gesture, back/thumb side visible, wrist enters from LOWER LEFT and palm reaches center. Four fingers curl into a loose fist on the RIGHT, with index finger bent high at upper right; finger knuckles and fingernails clear, natural warm beige skin. IMPORTANT layered animation asset: thumb is tucked completely behind palm and not visible; no visible thumb in this base layer because a separate moving thumb will be composited later. Reserve the front upper-left side of palm for that thumb. No beads in this image; they will be rendered separately passing through web between thumb and index. Entire hand and short wrist in frame with 8% transparent padding, soft upper-left studio illumination, no jewelry, no sleeves, no text, no shadow on background. Actual transparent background.

手部输出仍包含可辨认拇指，因此使用同一照片的拇指区域作为独立运动层，避免额外生成造成肤色或轮廓不一致。

## 音效

`scripts/generate-sounds.py` 使用固定随机种子离线合成 WAV，不使用第三方录音或在线服务。木块声有两次错开的硬质接触和两次衰减回弹，采用短促宽频冲击与快速衰减的非谐和木质共振；另外生成擦火柴、点燃与轻微珠子碰撞。原木鱼音效保留。

## 木槌

保留原木槌透明 PNG，通过横向镜像、柄尾旋转支点和角度调整，使槌头朝向木鱼，尾部远离木鱼。

## 0.7.3 运动更新

复用原手部 PNG，不修改源图。Core Image 局部形变覆盖拇指垫和邻近软组织；完整手部与拇指前景使用同一形变结果和同步遮罩，代替原先裁片旋转。珠子、穿孔、串线、阴影仍由原生界面绘制。
