import AppKit
import AVFoundation
import CyberBlessingCore
import Darwin
import SwiftUI

/// Explicit CLI-only diagnostics. Uses isolated preferences, never user counters.
@MainActor
enum AppValidation {
    struct Failure: Error { let message: String }
    static func run(outputDirectory: String) async {
        let directory = URL(fileURLWithPath: outputDirectory, isDirectory: true)
        var passed: [String] = []
        var failures: [String] = []
        func require(_ condition: @autoclosure () -> Bool, _ title: String) throws {
            guard condition() else { throw Failure(message: title) }
            passed.append(title)
        }
        let suite = "dev.cyberblessing.appcheck.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let store = BlessingStore(defaults: defaults)
            let controller = RitualController(store: store)
            controller.soundEnabled = false
            try require(controller.sound.preparedPlayerCount == 14, "all fourteen pooled audio players preload")
            for name in CyberBlessingImages.names {
                guard let url = CyberBlessingImages.resourceURL(name) else { throw Failure(message: "missing \(name)") }
                try require(NSImage(contentsOf: url) != nil, "image loads: \(name)")
            }
            try require(CyberBlessingImages.loadedCount == 8, "all eight image views decode and cache")
            try require(AppMetadata.version.split(separator: ".").count == 3, "version resource")
            if let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                try require(bundleVersion == AppMetadata.version, "bundle version matches rendered version")
            }
            controller.mode = .woodfish
            controller.strikeWoodfish(reduced: false)
            try await Task.sleep(nanoseconds: 80_000_000)
            controller.strikeWoodfish(reduced: false)
            try await Task.sleep(nanoseconds: 70_000_000)
            try require(controller.session.isStriking && controller.strikePhase, "second strike survives old completion")
            try await Task.sleep(nanoseconds: 100_000_000)
            try require(!controller.session.isStriking && store.meritCount == 2, "latest strike finishes and counts both taps")
            for _ in 0..<100 { controller.strikeWoodfish(reduced: true) }
            try require(store.meritCount == 102 && controller.meritPopups.count == 24, "rapid taps retain exact counts and bounded popups")
            try require(controller.sound.activePlayerCount == 0, "muted taps play no audio")
            try await Task.sleep(nanoseconds: 1_200_000_000)
            try require(controller.meritPopups.isEmpty && !controller.strikePhase, "popups clean up and reduced motion stays still")
            controller.mode = .divination
            controller.castCups(reduced: false)
            controller.castCups(reduced: false)
            controller.mode = .woodfish
            try await Task.sleep(nanoseconds: 300_000_000)
            try require(store.divinationCount == 0 && !controller.session.isTossing, "mode switch cancels unfinished toss without a hidden count")
            controller.mode = .divination
            controller.castCups(reduced: true)
            try await Task.sleep(nanoseconds: 250_000_000)
            try require(store.divinationCount == 1 && controller.session.reading == store.lastReading, "reduced-motion toss commits exactly one reading")
            controller.castCups(reduced: false)
            controller.cancelTransient()
            try await Task.sleep(nanoseconds: 300_000_000)
            try require(store.divinationCount == 1 && !controller.session.isTossing, "close lifecycle cancels toss")
            controller.sound.play("woodfish-tap", volume: 0, enabled: true)
            try require(controller.sound.activePlayerCount == 0, "zero volume plays no audio")
            controller.sound.play("woodfish-tap", volume: 0.01, enabled: true)
            try await Task.sleep(nanoseconds: 35_000_000)
            controller.sound.play("woodfish-tap", volume: 0.01, enabled: true)
            try require(controller.sound.activePlayerCount >= 2, "consecutive taps have overlapping audio players")
            controller.sound.stopAll()
            try require(controller.sound.activePlayerCount == 0, "mute stops active audio")
            controller.mode = .incense
            controller.lightIncense(reduced: false)
            controller.lightIncense(reduced: false)
            try require(controller.session.ignitionStage == .striking && store.incenseCount == 0, "ignition starts striking before committing a burn")
            try await Task.sleep(nanoseconds: 180_000_000)
            try render(ContentView(controller: controller, handlesLifecycle: false), to: directory.appendingPathComponent("match-striking.png"))
            try await waitForIgnition(controller, stage: .approaching)
            try require(controller.session.ignitionStage == .approaching && store.incenseCount == 0, "burn not committed before match reaches tip")
            try render(ContentView(controller: controller, handlesLifecycle: false), to: directory.appendingPathComponent("match-approaching.png"))
            try await waitForIgnition(controller, stage: .lighting)
            try require(controller.session.ignitionStage == .lighting, "match holds flame against incense")
            try render(ContentView(controller: controller, handlesLifecycle: false), to: directory.appendingPathComponent("match-lighting.png"))
            try await waitForIgnition(controller, stage: .idle)
            try require(store.incenseCount == 1 && !controller.session.isIgniting, "lighting commits exactly once after contact")
            controller.finishIncense()
            try require(!IncenseBurnState(startedAt: store.incenseStartedAt, now: Date.now.timeIntervalSince1970).isBurning, "manual finish enables another lighting experience")
            controller.lightIncense(reduced: false)
            controller.mode = .beads
            try await Task.sleep(nanoseconds: 400_000_000)
            try require(!controller.session.isIgniting && store.incenseCount == 1, "switching pages cancels unfinished match sequence")
            let capture = try embeddedBeadCapture(controller)
            guard let cg = CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 1, wheel1: 1, wheel2: 0, wheel3: 0),
                  let event = NSEvent(cgEvent: cg) else { throw Failure(message: "cannot construct native wheel event") }
            capture.scrollWheel(with: event)
            try require(store.beadCount > 0 && controller.beads.position > 0, "native NSEvent wheel handler advances beads")
            let oldPosition = controller.beads.position
            for _ in 0..<12 { controller.rollBeads(delta: 1, precise: false) }
            try require(controller.beads.position == oldPosition + 12, "fast wheel events preserve movement")
            controller.rollBeads(delta: 0.25, precise: false)
            try render(ContentView(controller: controller, handlesLifecycle: false), to: directory.appendingPathComponent("beads-thumb-moving.png"))
            try await Task.sleep(nanoseconds: 400_000_000)
            try require(controller.beads.velocity == 0, "thumb and rolling settle after wheel stops")
            controller.mode = .incense
            controller.finishIncense()
            controller.lightIncense(reduced: true)
            try require(store.incenseCount == 2 && !controller.session.isIgniting, "reduced-motion lighting completes without match movement")
            controller.mode = .woodfish
            let oldCount = store.beadCount
            capture.scrollWheel(with: event)
            try require(store.beadCount == oldCount, "wheel input ignored outside beads mode")
            try render(WoodFishScene(isStriking: false).frame(width: AppMetadata.width, height: 220).background(BlessingPalette.paper), to: directory.appendingPathComponent("mallet-rest.png"))
            try render(WoodFishScene(isStriking: true).frame(width: AppMetadata.width, height: 220).background(BlessingPalette.paper), to: directory.appendingPathComponent("mallet-contact.png"))
            store.incenseStartedAt = Date.now.timeIntervalSince1970 - 900
            controller.volume = 0.35
            controller.resetStatistics()
            try require(store.incenseStartedAt > 0 && store.volume == 0.35 && store.meritCount == 0 && store.divinationCount == 0, "statistics reset preserves burning incense and preferences")

            controller.reduceMotion = true
            // Capture native SwiftUI/AppKit rendering, including menus and controls.
            for mode in BlessingMode.allCases {
                controller.mode = mode
                if mode == .divination {
                    store.recordDivination(DivinationReading(first: .yang, second: .yin))
                    let refreshed = RitualController(store: store)
                    try render(ContentView(controller: refreshed), to: directory.appendingPathComponent("\(mode.rawValue).png"))
                } else {
                    try render(ContentView(controller: controller, handlesLifecycle: false), to: directory.appendingPathComponent("\(mode.rawValue).png"))
                }
                passed.append("native render: \(mode.rawValue), width 354 pt")
            }
            try render(ContentView(controller: controller, showingSettings: true), to: directory.appendingPathComponent("settings.png"))
            passed.append("native render: settings")
            for time in [0.0, 2.0, 4.0] {
                try render(IncenseScene(progress: 0.1, isBurning: true, phase: Date(timeIntervalSinceReferenceDate: time), smokeTime: time)
                    .frame(width: AppMetadata.width, height: 236).background(BlessingPalette.paper),
                    to: directory.appendingPathComponent("incense-smoke-\(Int(time)).png"))
            }
            passed.append("native render: anchored incense and smoke at three animation phases")
            try require(HandPoseRenderer.isAvailable, "thumb deformation renderer loads")
            guard let rest = HandPoseRenderer.image(cycle: 0)?.tiffRepresentation,
                  let flex = HandPoseRenderer.image(cycle: 0.5)?.tiffRepresentation else {
                throw Failure(message: "thumb deformation produces no image")
            }
            try require(rest != flex, "thumb pad flex changes the intact hand photograph")
            for (name, position) in [("rest", 0.0), ("contact", 0.25), ("press", 0.5), ("release", 0.75), ("reverse", -0.25)] {
                try render(BeadScene(position: position).frame(width: AppMetadata.width, height: 248).background(BlessingPalette.paper),
                    to: directory.appendingPathComponent("beads-pose-\(name).png"))
            }
            passed.append("native render: threaded beads and thumb at five poses")
            try await checkResetButtons(controller, directory: directory)
            passed.append("native settings buttons: request, cancel, confirm and repeat reset stay in the same window")
            // Cover the less common readings and burnout states too.
            for (name, reading) in [("laughing", DivinationReading(first: .yang, second: .yang)), ("yin", DivinationReading(first: .yin, second: .yin))] {
                store.mode = .divination; store.recordDivination(reading)
                try render(ContentView(controller: RitualController(store: store)), to: directory.appendingPathComponent("\(name).png"))
                passed.append("native render: \(name)")
            }
            store.mode = .incense; store.incenseStartedAt = 0
            try render(ContentView(controller: RitualController(store: store)), to: directory.appendingPathComponent("unlit.png"))
            passed.append("native render: unlit")
            store.incenseStartedAt = Date.now.timeIntervalSince1970 - 1_700
            try render(ContentView(controller: RitualController(store: store)), to: directory.appendingPathComponent("almost-burnt.png"))
            passed.append("native render: almost burnt")
            store.incenseStartedAt = Date.now.timeIntervalSince1970 - 2_000
            try render(ContentView(controller: RitualController(store: store)), to: directory.appendingPathComponent("burnout.png"))
            passed.append("native render: burnout")
        } catch let error as Failure { failures.append(error.message) }
        catch { failures.append(String(describing: error)) }
        let report: [String: Any] = ["passed": passed, "failures": failures, "version": AppMetadata.version,
            "notes": ["Isolated UserDefaults suite; user data untouched.", "Native offscreen rendering; manual menu bar click and keyboard routing are not asserted."]]
        if let data = try? JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: directory.appendingPathComponent("APP_QA.json"))
        }
        defaults.removePersistentDomain(forName: suite)
        for item in passed { print("PASS \(item)") }
        for item in failures { print("FAIL \(item)") }
        print("App checks: \(passed.count) passed, \(failures.count) failed")
        fflush(stdout)
        exit(failures.isEmpty ? 0 : 1)
    }

    static func checkResetButtons(_ controller: RitualController, directory: URL) async throws {
        let hosting = NSHostingView(rootView: ContentView(controller: controller, showingSettings: true, handlesLifecycle: false))
        let window = NSWindow(contentRect: NSRect(x: -20_000, y: -20_000, width: AppMetadata.width, height: 600),
            styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = hosting
        window.orderFront(nil)
        defer { window.contentView = nil; window.close() }
        func settle() async throws {
            try await Task.sleep(nanoseconds: 120_000_000)
            window.setContentSize(hosting.fittingSize)
            hosting.layoutSubtreeIfNeeded()
        }
        func button(_ identifier: String) -> NSButton? {
            func find(_ view: NSView) -> NSButton? {
                if let button = view as? NSButton, button.accessibilityIdentifier() == identifier { return button }
                return view.subviews.lazy.compactMap { find($0) }.first
            }
            return find(hosting)
        }
        func press(_ identifier: String) throws {
            guard let target = button(identifier), target.isEnabled else {
                throw Failure(message: "missing or disabled settings button: \(identifier)")
            }
            target.performClick(nil)
        }
        controller.store.recordBeads(3)
        let count = controller.store.beadCount
        let burn = controller.store.incenseStartedAt
        let volume = controller.volume
        try await settle()
        let initialHeight = hosting.bounds.height
        try press("request-statistics-reset")
        try await settle()
        let confirmationHeight = hosting.bounds.height
        guard confirmationHeight > initialHeight + 20, window.contentView === hosting,
              controller.store.beadCount == count else { throw Failure(message: "reset request must remain inline without clearing") }
        guard let bitmap = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds) else { throw Failure(message: "reset confirmation bitmap unavailable") }
        hosting.cacheDisplay(in: hosting.bounds, to: bitmap)
        try bitmap.representation(using: .png, properties: [:])?.write(to: directory.appendingPathComponent("settings-reset-confirmation.png"))
        try press("cancel-statistics-reset")
        try await settle()
        guard controller.store.beadCount == count, hosting.bounds.height < confirmationHeight else {
            throw Failure(message: "reset cancellation changed statistics or lost button")
        }
        try press("request-statistics-reset")
        try await settle()
        try press("confirm-statistics-reset")
        try await settle()
        guard controller.store.beadCount == 0, controller.store.incenseCount == 0,
              controller.store.divinationCount == 0, controller.store.meritCount == 0,
              controller.store.lastReading == nil, controller.store.incenseStartedAt == burn,
              controller.volume == volume, hosting.bounds.height < confirmationHeight,
              window.contentView === hosting else { throw Failure(message: "confirmed reset must clear only statistics and keep settings usable") }
        if let bitmap = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds) {
            hosting.cacheDisplay(in: hosting.bounds, to: bitmap)
            try bitmap.representation(using: .png, properties: [:])?.write(to: directory.appendingPathComponent("settings-reset-completed.png"))
        }
        try press("request-statistics-reset")
        try await settle()
        try press("cancel-statistics-reset")
        try await settle()
    }

    static func embeddedBeadCapture(_ controller: RitualController) throws -> BeadWheelView {
        let hosting = NSHostingView(rootView: ContentView(controller: controller, handlesLifecycle: false))
        hosting.setFrameSize(hosting.fittingSize)
        let window = NSWindow(contentRect: hosting.bounds, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = hosting
        hosting.layoutSubtreeIfNeeded()
        func find(_ view: NSView) -> BeadWheelView? {
            if let capture = view as? BeadWheelView { return capture }
            return view.subviews.lazy.compactMap { find($0) }.first
        }
        guard let result = find(hosting), result.frame.width > 100 else {
            throw Failure(message: "beads panel has no usable native scroll capture view")
        }
        window.contentView = nil; window.close()
        return result
    }

    static func waitForIgnition(_ controller: RitualController, stage: IgnitionStage) async throws {
        let deadline = Date.now.addingTimeInterval(4)
        while controller.session.ignitionStage != stage {
            guard Date.now < deadline else { throw Failure(message: "ignition never reached \(stage)") }
            try await Task.sleep(nanoseconds: 15_000_000)
        }
    }

    static func render<V: View>(_ content: V, to url: URL) throws {
        let hosting = NSHostingView(rootView: content)
        let size = hosting.fittingSize
        guard abs(size.width - AppMetadata.width) < 0.5, size.height > 100, size.height < 760 else {
            throw Failure(message: "invalid rendered size \(size)")
        }
        hosting.setFrameSize(size)
        let window = NSWindow(contentRect: NSRect(origin: NSPoint(x: -20_000, y: -20_000), size: size),
            styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = hosting
        hosting.layoutSubtreeIfNeeded()
        guard let bitmap = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds) else { throw Failure(message: "native bitmap unavailable") }
        hosting.cacheDisplay(in: hosting.bounds, to: bitmap)
        guard let data = bitmap.representation(using: .png, properties: [:]) else { throw Failure(message: "native PNG unavailable") }
        try data.write(to: url)
        window.contentView = nil
        window.close()
    }
}
