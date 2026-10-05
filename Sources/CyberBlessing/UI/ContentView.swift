import CyberBlessingCore
import SwiftUI

enum BlessingPalette {
    static let paper = Color(red: 0.98, green: 0.96, blue: 0.92)
    static let ink = Color(red: 0.22, green: 0.19, blue: 0.16)
    static let muted = Color(red: 0.45, green: 0.39, blue: 0.32)
    static let vermilion = Color(red: 0.68, green: 0.22, blue: 0.15)
    static let gold = Color(red: 0.75, green: 0.55, blue: 0.27)
    static let bronze = Color(red: 0.39, green: 0.31, blue: 0.20)
    static let card = Color.white.opacity(0.72)
}

@MainActor
struct ContentView: View {
    private struct MeritPopupLabel: View {
        let rotation: Double
        let reduced: Bool
        @State private var isRising = false

        var body: some View {
            Text("功德 +1")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(BlessingPalette.vermilion)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.white.opacity(0.94), in: Capsule())
                .overlay(Capsule().stroke(BlessingPalette.gold.opacity(0.24), lineWidth: 1))
                .shadow(color: BlessingPalette.bronze.opacity(0.12), radius: 5, x: 0, y: 2)
                .rotationEffect(.degrees(reduced ? 0 : rotation))
                .offset(y: reduced ? 0 : (isRising ? -31 : 8))
                .opacity(reduced ? 1 : (isRising ? 0 : 1))
                .scaleEffect(reduced ? 1 : (isRising ? 0.92 : 1))
                .onAppear {
                    if !reduced { withAnimation(.easeOut(duration: 0.95)) { isRising = true } }
                }
        }
    }

    private let handlesLifecycle: Bool
    private let incenseDuration: TimeInterval = 30 * 60

    @StateObject private var controller: RitualController
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var showingSettings = false
    @State private var confirmingReset = false
    @State private var resetCompleted = false

    init(controller: RitualController? = nil, showingSettings: Bool = false, handlesLifecycle: Bool = true) {
        self.handlesLifecycle = handlesLifecycle
        _controller = StateObject(wrappedValue: controller ?? RitualController())
        _showingSettings = State(initialValue: showingSettings)
    }

    private var reduced: Bool { systemReduceMotion || controller.reduceMotion }
    private var mode: BlessingMode { controller.mode }
    private var reading: DivinationReading? { controller.session.reading }
    private var isIgniting: Bool { controller.session.isIgniting }
    private var isTossing: Bool { controller.session.isTossing }
    private var cupsInAir: Bool { controller.session.cupsInAir && !reduced }
    private var incenseCount: Int { controller.store.incenseCount }
    private var incenseStartedAt: TimeInterval { controller.store.incenseStartedAt }
    private var meritCount: Int { controller.store.meritCount }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            header
            Group {
                if showingSettings {
                    settingsPanel
                } else {
                switch mode {
                case .incense:
                    incensePanel.transition(.opacity.combined(with: .move(edge: .leading)))
                case .divination:
                    divinationPanel.transition(.opacity.combined(with: .move(edge: .trailing)))
                case .woodfish:
                    woodFishPanel.transition(.opacity.combined(with: .move(edge: .bottom)))
                case .beads:
                    beadsPanel.transition(.opacity)
                }
                }
            }
            footer
        }
        .padding(17)
        .frame(width: AppMetadata.width)
        .background(BlessingPalette.paper)
        .foregroundStyle(BlessingPalette.ink)
        .animation(reduced ? nil : .spring(response: 0.4, dampingFraction: 0.84), value: mode)
        .transaction { if reduced { $0.animation = nil } }
        .onDisappear { if handlesLifecycle { controller.cancelTransient() } }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(BlessingPalette.vermilion.opacity(0.11)).frame(width: 38, height: 38)
                Image(systemName: "sparkle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(BlessingPalette.vermilion)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("赛博祈福").font(.system(size: 16, weight: .semibold, design: .rounded))
                Text("给心愿一个安静的仪式").font(.system(size: 11)).foregroundStyle(BlessingPalette.muted)
            }
            Spacer(minLength: 4)
            Menu {
                ForEach(Array(BlessingMode.allCases.enumerated()), id: \.element.rawValue) { index, item in
                    Button {
                        controller.mode = item
                        showingSettings = false
                        confirmingReset = false
                        resetCompleted = false
                    } label: {
                        Label(item.title + (mode == item ? " ✓" : ""), systemImage: item.symbol)
                    }
                    .keyboardShortcut(KeyEquivalent(Character(String(index + 1))), modifiers: .command)
                }
            } label: {
                Label(mode.title, systemImage: mode.symbol)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(BlessingPalette.vermilion)
                    .padding(.horizontal, 9).padding(.vertical, 8)
                    .background(BlessingPalette.vermilion.opacity(0.08), in: Capsule())
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .accessibilityLabel("选择仪式，当前为\(mode.title)")
        }
    }

    private var incensePanel: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let burnState = IncenseBurnState(startedAt: incenseStartedAt, now: timeline.date.timeIntervalSince1970, duration: incenseDuration)
            let progress = burnState.progress
            let isBurning = burnState.isBurning
            let remaining = burnState.remainingSeconds

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("虚拟上香").font(.system(size: 15, weight: .semibold, design: .rounded))
                    Text("一炷心香，留一点安静给自己")
                        .font(.system(size: 11)).foregroundStyle(BlessingPalette.muted)
                }

                IncenseScene(progress: isIgniting && !isBurning ? 0 : progress, isBurning: isBurning, phase: timeline.date, reducedMotion: reduced, ignitionStage: controller.session.ignitionStage)
                    .frame(height: 236)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(colors: [.white.opacity(0.7), BlessingPalette.paper.opacity(0.8)], startPoint: .top, endPoint: .bottom),
                        in: RoundedRectangle(cornerRadius: 17)
                    )

                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isIgniting ? ignitionStatus : incenseStatus(progress: progress, isBurning: isBurning))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                        Text(isIgniting ? "擦燃火柴，将火焰送到香头" : (isBurning ? "香火会继续缓缓燃烧" : "已点燃 \(incenseCount) 炷"))
                            .font(.system(size: 11)).foregroundStyle(BlessingPalette.muted)
                    }
                    Spacer()
                    Text(isBurning || progress == 0 ? clockText(remaining) : "已燃尽")
                        .font(.system(size: 18, weight: .medium, design: .rounded).monospacedDigit())
                        .foregroundStyle(isBurning ? BlessingPalette.vermilion : BlessingPalette.ink)
                }
                if isBurning && !isIgniting {
                    Button("结束此炷，重新体验点香") { controller.finishIncense() }
                        .font(.system(size: 10)).foregroundStyle(BlessingPalette.muted)
                        .buttonStyle(.plain)
                        .help("提前结束当前虚拟香，保留累计次数")
                }
                ProgressView(value: progress)
                    .tint(BlessingPalette.vermilion)
                    .scaleEffect(x: 1, y: 0.8, anchor: .center)
                Button { controller.lightIncense(reduced: reduced) } label: {
                    HStack(spacing: 7) {
                        Image(systemName: isBurning ? "hourglass" : "flame.fill")
                        Text(isIgniting ? "正在点香…" : (isBurning ? "香正缓缓燃烧" : (progress >= 1 ? "再点一炷香" : "擦火柴，点一炷香")))
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .frame(maxWidth: .infinity).frame(height: 37)
                    .foregroundStyle(isBurning ? BlessingPalette.muted : .white)
                    .background(isBurning ? BlessingPalette.gold.opacity(0.16) : BlessingPalette.vermilion, in: RoundedRectangle(cornerRadius: 11))
                }
                .buttonStyle(.plain)
                .disabled(isBurning || isIgniting)
                .accessibilityLabel(isBurning ? "香正在燃烧，剩余 \(clockText(remaining))" : "点燃一炷约三十分钟的虚拟香")
                Text("体验计时约 30 分钟；现实香支因尺寸与环境而异。")
                    .font(.system(size: 10)).foregroundStyle(BlessingPalette.muted)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(15)
            .background(BlessingPalette.card, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(.black.opacity(0.035), lineWidth: 1))
        }
    }

    private var divinationPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("虚拟掷圣杯").font(.system(size: 15, weight: .semibold, design: .rounded))
                Text("默念心愿，再将一对木筊杯掷向地面。")
                    .font(.system(size: 11)).foregroundStyle(BlessingPalette.muted)
            }

            ZStack(alignment: .bottom) {
                Ellipse()
                    .fill(BlessingPalette.bronze.opacity(cupsInAir ? 0.06 : 0.14))
                    .frame(width: cupsInAir ? 108 : 205, height: cupsInAir ? 7 : 12)
                    .blur(radius: cupsInAir ? 6 : 3)
                    .padding(.bottom, 22)
                    .animation(.easeOut(duration: 0.18), value: cupsInAir)
                HStack(spacing: 32) {
                    JiaobeiBlockView(face: reading?.first, isAirborne: cupsInAir, rotation: -27, reducedMotion: reduced)
                    JiaobeiBlockView(face: reading?.second, isAirborne: cupsInAir, rotation: 31, reducedMotion: reduced)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 24)
                Rectangle()
                    .fill(BlessingPalette.bronze.opacity(0.20))
                    .frame(height: 1)
                    .padding(.horizontal, 22)
                    .padding(.bottom, 17)
            }
            .frame(height: 192)
            .background(
                LinearGradient(colors: [.white.opacity(0.72), BlessingPalette.paper.opacity(0.65)], startPoint: .top, endPoint: .bottom),
                in: RoundedRectangle(cornerRadius: 17)
            )
            .clipped()

            if let reading, !isTossing {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 7) {
                        Image(systemName: reading.outcome.symbol)
                            .foregroundStyle(BlessingPalette.vermilion)
                        Text(reading.outcome.title)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                        Spacer()
                        Text("\(faceName(reading.first)) · \(faceName(reading.second))")
                            .font(.system(size: 11)).foregroundStyle(BlessingPalette.muted)
                    }
                    Text(reading.outcome.explanation)
                        .font(.system(size: 11)).foregroundStyle(BlessingPalette.muted)
                }
                .padding(.horizontal, 2)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                Text(isTossing ? "筊杯正在落下……" : "尚未掷杯")
                    .font(.system(size: 11)).foregroundStyle(BlessingPalette.muted)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            Button { controller.castCups(reduced: reduced) } label: {
                HStack(spacing: 7) {
                    Image(systemName: "arrow.up.and.down")
                    Text(isTossing ? "掷出中…" : (reading == nil ? "掷出圣杯" : "再掷一次"))
                }
                .font(.system(size: 12, weight: .semibold))
                .frame(maxWidth: .infinity).frame(height: 37)
                .foregroundStyle(.white)
                .background(BlessingPalette.vermilion, in: RoundedRectangle(cornerRadius: 11))
            }
            .buttonStyle(.plain)
            .disabled(isTossing)
            .accessibilityLabel("将两枚木筊杯掷向地面")
            Text(controller.soundEnabled && controller.volume > 0 ? "木质筊杯落地音效 · 结果为随机模拟" : "音效已静音 · 结果为随机模拟")
                .font(.system(size: 10)).foregroundStyle(BlessingPalette.muted)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(15)
        .background(BlessingPalette.card, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.black.opacity(0.035), lineWidth: 1))
    }

    private var woodFishPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("虚拟敲木鱼").font(.system(size: 15, weight: .semibold, design: .rounded))
                Text("轻敲一下，心静一分").font(.system(size: 11)).foregroundStyle(BlessingPalette.muted)
            }

            Button { controller.strikeWoodfish(reduced: reduced) } label: {
                WoodFishScene(isStriking: controller.strikePhase)
                    .frame(maxWidth: .infinity)
                    .frame(height: 178)
                    .background(
                        LinearGradient(colors: [.white.opacity(0.72), BlessingPalette.paper.opacity(0.65)], startPoint: .top, endPoint: .bottom),
                        in: RoundedRectangle(cornerRadius: 17)
                    )
                    .overlay {
                        GeometryReader { geometry in
                            ZStack {
                                ForEach(controller.meritPopups) { popup in
                                    MeritPopupLabel(rotation: popup.rotation, reduced: reduced)
                                        .position(
                                            x: geometry.size.width * popup.xFraction,
                                            y: geometry.size.height * popup.yFraction
                                        )
                                        .transition(.scale(scale: 0.7).combined(with: .opacity))
                                }
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .allowsHitTesting(false)
                        }
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("敲木鱼，功德加一")

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("累计功德").font(.system(size: 11)).foregroundStyle(BlessingPalette.muted)
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("\(meritCount)").font(.system(size: 25, weight: .semibold, design: .rounded).monospacedDigit())
                            .lineLimit(1).minimumScaleFactor(0.35)
                        Text("功德").font(.system(size: 11, weight: .medium)).foregroundStyle(BlessingPalette.muted)
                    }
                }
                Spacer()
                Button { controller.strikeWoodfish(reduced: reduced) } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "hand.tap.fill")
                        Text("敲一下")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 16).frame(height: 38)
                    .foregroundStyle(.white)
                    .background(BlessingPalette.vermilion, in: RoundedRectangle(cornerRadius: 11))
                }
                .buttonStyle(.plain)
            }
            Text("每次敲击计数 +1 · 功德数字保存在本机")
                .font(.system(size: 10)).foregroundStyle(BlessingPalette.muted)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(15)
        .background(BlessingPalette.card, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.black.opacity(0.035), lineWidth: 1))
    }

    private var beadsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("虚拟盘串").font(.system(size: 15, weight: .semibold, design: .rounded))
            Text("让拇指一颗颗拨过，慢下来，也动起来。")
                .font(.system(size: 11)).foregroundStyle(BlessingPalette.muted)
            BeadScene(position: controller.beads.position, reducedMotion: reduced)
                .frame(height: 248)
                .frame(maxWidth: .infinity)
                .animation(reduced ? nil : .interactiveSpring(response: 0.24, dampingFraction: 0.9), value: controller.beads.position)
                .background(
                    LinearGradient(colors: [.white.opacity(0.72), BlessingPalette.paper.opacity(0.65)], startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: 17)
                )
                .overlay {
                    BeadScrollCapture { delta, precise in controller.rollBeads(delta: delta, precise: precise) }
                }
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("累计拨珠").font(.system(size: 11)).foregroundStyle(BlessingPalette.muted)
                    Text(controller.store.beadCount.formatted()).font(.system(size: 25, weight: .semibold, design: .rounded)).monospacedDigit()
                        .lineLimit(1).minimumScaleFactor(0.35)
                }
                Spacer()
                Button("拨一颗") { controller.rollBeads(delta: 1, precise: false) }
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 15).padding(.vertical, 11)
                    .foregroundStyle(.white)
                    .background(BlessingPalette.vermilion, in: RoundedRectangle(cornerRadius: 11))
                    .buttonStyle(.plain)
                    .keyboardShortcut(.space, modifiers: [])
                    .accessibilityLabel("拨动一颗珠子")
            }
            Text("鼠标放在手串上滚动 · 越快拨得越快 · 支持触控板")
                .font(.system(size: 10)).foregroundStyle(BlessingPalette.muted)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(15)
        .background(BlessingPalette.card, in: RoundedRectangle(cornerRadius: 18))
    }

    private var ignitionStatus: String {
        switch controller.session.ignitionStage {
        case .striking: return "擦燃火柴"
        case .flaring: return "火柴已燃起"
        case .approaching: return "将火焰送到香头"
        case .lighting: return "点燃香头"
        case .withdrawing: return "一炷心香已点燃"
        case .idle: return "静候一炷心香"
        }
    }

    private var footer: some View {
        HStack(spacing: 5) {
            Image(systemName: "lock.fill").font(.system(size: 8))
            Text("本地保存 · 仅供仪式体验")
                .lineLimit(1)
            Spacer(minLength: 3)
            Button {
                if !showingSettings { controller.cancelTransient() }
                showingSettings.toggle()
                confirmingReset = false
                resetCompleted = false
            } label: {
                Image(systemName: "slider.horizontal.3")
            }
            .buttonStyle(.plain)
            .help("声音、动效与累计统计")
            .accessibilityLabel(showingSettings ? "返回仪式" : "打开设置与统计")
            Text(AppMetadata.version)
            Button(action: AppTermination.quit) {
                Label("退出", systemImage: "power")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(BlessingPalette.vermilion)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(BlessingPalette.vermilion.opacity(0.08), in: Capsule())
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q", modifiers: .command)
            .help("退出赛博祈福")
            .accessibilityLabel("退出赛博祈福")
        }
        .font(.system(size: 10)).foregroundStyle(BlessingPalette.muted.opacity(0.9))
        .padding(.horizontal, 2)
    }

    private var settingsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("设置与统计").font(.system(size: 13, weight: .semibold))
            Toggle("播放音效", isOn: $controller.soundEnabled)
            HStack {
                Text("音量")
                Slider(value: $controller.volume, in: 0...1)
                    .disabled(!controller.soundEnabled)
                    .accessibilityLabel("音效音量")
                Text("\(Int(controller.volume * 100))%")
                    .monospacedDigit().frame(width: 34, alignment: .trailing)
            }
            Toggle("减少动态效果", isOn: $controller.reduceMotion)
            if systemReduceMotion {
                Text("已遵循系统的减少动态效果设置。")
                    .foregroundStyle(BlessingPalette.muted)
            }
            Divider()
            HStack {
                statistic("上香", count: incenseCount)
                Spacer()
                statistic("掷杯", count: controller.store.divinationCount)
                Spacer()
                statistic("功德", count: meritCount)
                Spacer()
                statistic("拨珠", count: controller.store.beadCount)
            }
            // Keep confirmation inside the menu bar window. A system alert can
            // take focus away and dismiss MenuBarExtra before it can be used.
            if confirmingReset {
                VStack(alignment: .leading, spacing: 9) {
                    Text("清空累计统计？").fontWeight(.semibold)
                    Text("将清空四项累计次数和最近掷杯结果。正在燃烧的香和偏好设置会保留。")
                        .foregroundStyle(BlessingPalette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 12) {
                        SettingsActionButton(title: "取消", identifier: "cancel-statistics-reset") { confirmingReset = false }
                            .frame(width: 54, height: 24)
                        SettingsActionButton(title: "确认清空", identifier: "confirm-statistics-reset", destructive: true) {
                            controller.resetStatistics()
                            confirmingReset = false
                            resetCompleted = true
                        }
                        .frame(width: 78, height: 24)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(BlessingPalette.vermilion.opacity(0.06), in: RoundedRectangle(cornerRadius: 9))
            } else {
                SettingsActionButton(title: "清空累计统计…", identifier: "request-statistics-reset", destructive: true, enabled: !isTossing) {
                    resetCompleted = false
                    confirmingReset = true
                }
                .frame(width: 122, height: 24)
                if resetCompleted {
                    Label("累计统计已清空", systemImage: "checkmark.circle")
                        .foregroundStyle(BlessingPalette.muted)
                }
            }
            Text("⌘1 上香 · ⌘2 掷杯 · ⌘3 木鱼 · ⌘4 盘串")
            Text("⌘Q 退出").foregroundStyle(BlessingPalette.muted)
                .font(.system(size: 11)).foregroundStyle(BlessingPalette.muted)
        }
        .font(.system(size: 11))
        .padding(14)
        .background(BlessingPalette.card, in: RoundedRectangle(cornerRadius: 14))
    }

    private func statistic(_ title: String, count: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).foregroundStyle(BlessingPalette.muted)
            Text(count.formatted()).font(.system(size: 15, weight: .semibold)).monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    private func faceName(_ face: CupFace) -> String {
        face == .yang ? "阳面" : "阴面"
    }

    private func clockText(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private func incenseStatus(progress: Double, isBurning: Bool) -> String {
        if isBurning { return "香火正燃" }
        if progress >= 1 { return "此炷已燃尽" }
        return "静候一炷心香"
    }
}
