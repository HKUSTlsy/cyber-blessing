import Combine
import CyberBlessingCore
import SwiftUI

@MainActor
final class RitualController: ObservableObject {
    struct MeritPopupItem: Identifiable {
        let id = UUID()
        let xFraction = CGFloat.random(in: 0.18...0.82)
        let yFraction = CGFloat.random(in: 0.30...0.72)
        let rotation = Double.random(in: -8...8)
    }

    let store: BlessingStore
    let sound: SoundEngine
    @Published var mode: BlessingMode { didSet { store.mode = mode; cancelTransient() } }
    @Published var soundEnabled: Bool { didSet { store.soundEnabled = soundEnabled; if !soundEnabled { sound.stopAll() } } }
    @Published var volume: Double { didSet { store.volume = volume; if volume == 0 { sound.stopAll() } } }
    @Published var reduceMotion: Bool { didSet { store.reduceMotion = reduceMotion } }
    @Published private(set) var session: RitualSession
    @Published private(set) var strikePhase = false
    @Published private(set) var meritPopups: [MeritPopupItem] = []
    @Published private(set) var beads = BeadScrollState()
    private var lastBeadSoundAt = 0.0
    private var beadIdleTask: Task<Void, Never>?
    private var ignitionTask: Task<Void, Never>?
    private var tossTask: Task<Void, Never>?
    private var strikeTask: Task<Void, Never>?
    private var popupTasks: [UUID: Task<Void, Never>] = [:]

    init(store: BlessingStore = BlessingStore(), sound: SoundEngine? = nil) {
        self.store = store
        self.sound = sound ?? SoundEngine()
        mode = store.mode
        soundEnabled = store.soundEnabled
        volume = store.volume
        reduceMotion = store.reduceMotion
        session = RitualSession(reading: store.lastReading)
    }

    func lightIncense(reduced: Bool) {
        let now = Date.now.timeIntervalSince1970
        guard !IncenseBurnState(startedAt: store.incenseStartedAt, now: now).isBurning,
              let id = session.beginIgnition() else { return }
        if reduced {
            // Preserve the lighting event without large motion when accessibility requests it.
            sound.play("match-light", volume: volume, enabled: soundEnabled)
            objectWillChange.send()
            _ = store.lightIncense(now: now)
            session.cancelIgnition()
            return
        }
        sound.play("match-strike", volume: volume, enabled: soundEnabled)
        ignitionTask = Task { [weak self] in
            let sequence: [(UInt64, IgnitionStage, Double)] = [
                (330_000_000, .flaring, 0.12),
                (260_000_000, .approaching, 0.65),
                (650_000_000, .lighting, 0.12),
                (430_000_000, .withdrawing, 0.45)
            ]
            for (wait, stage, animationDuration) in sequence {
                do { try await Task.sleep(nanoseconds: wait) } catch { return }
                guard let self, self.session.ignitionID == id else { return }
                withAnimation(.easeInOut(duration: animationDuration)) { self.session.advanceIgnition(id, stage: stage) }
                if stage == .flaring { self.sound.play("match-light", volume: self.volume, enabled: self.soundEnabled) }
                if stage == .withdrawing {
                    self.objectWillChange.send()
                    _ = self.store.lightIncense(now: Date.now.timeIntervalSince1970)
                }
            }
            do { try await Task.sleep(nanoseconds: 500_000_000) } catch { return }
            guard let self, self.session.ignitionID == id else { return }
            self.session.cancelIgnition()
        }
    }

    func finishIncense() {
        cancelTransient()
        objectWillChange.send()
        if store.incenseStartedAt > 0 { store.incenseStartedAt = Date.now.timeIntervalSince1970 - 1_800 }
    }

    func rollBeads(delta: Double, precise: Bool, now: TimeInterval = Date.now.timeIntervalSince1970) {
        guard mode == .beads else { return }
        guard delta.isFinite, delta != 0, now.isFinite else { return }
        beadIdleTask?.cancel()
        let count = beads.scroll(delta: delta, precise: precise, now: now)
        if count > 0 { store.recordBeads(count) }
        beadIdleTask = Task { [weak self] in
            do { try await Task.sleep(nanoseconds: 250_000_000) } catch { return }
            self?.beads.stop()
        }
        if now - lastBeadSoundAt > 0.045 {
            sound.play("bead-click", volume: volume, enabled: soundEnabled)
            lastBeadSoundAt = now
        }
    }

    func strikeWoodfish(reduced: Bool) {
        objectWillChange.send()
        store.strikeWoodfish()
        strikeTask?.cancel()
        strikePhase = false
        let id = session.beginStrike()
        let popup = MeritPopupItem()
        // A finite display budget protects the view during sustained rapid taps.
        if meritPopups.count >= 24 {
            let oldest = meritPopups.removeFirst()
            popupTasks.removeValue(forKey: oldest.id)?.cancel()
        }
        meritPopups.append(popup)
        popupTasks[popup.id] = Task { [weak self] in
            do { try await Task.sleep(nanoseconds: 1_050_000_000) } catch { return }
            guard let self else { return }
            self.meritPopups.removeAll { $0.id == popup.id }
            self.popupTasks[popup.id] = nil
        }
        sound.play("woodfish-tap", volume: volume, enabled: soundEnabled)
        strikeTask = Task { [weak self] in
            do { try await Task.sleep(nanoseconds: 15_000_000) } catch { return }
            guard let self, self.session.strikeID == id else { return }
            withAnimation(reduced ? nil : .easeOut(duration: 0.05)) { self.strikePhase = !reduced }
            do { try await Task.sleep(nanoseconds: 100_000_000) } catch { return }
            guard self.session.strikeID == id else { return }
            withAnimation(reduced ? nil : .spring(response: 0.2, dampingFraction: 0.6)) {
                self.strikePhase = false
                self.session.endStrike(id)
            }
        }
    }

    func castCups(reduced: Bool) {
        guard let id = session.beginToss() else { return }
        var generator = SystemRandomNumberGenerator()
        let next = DivinationReading.cast(using: &generator)
        tossTask = Task { [weak self] in
            do { try await Task.sleep(nanoseconds: reduced ? 120_000_000 : 200_000_000) } catch { return }
            guard let self, self.session.tossID == id else { return }
            withAnimation(reduced ? nil : .interpolatingSpring(stiffness: 125, damping: 13)) {
                self.session.landToss(id)
            }
            // Commit the real faces at the landing, rather than flipping a second time later.
            withAnimation(reduced ? nil : .easeOut(duration: 0.12)) {
                if self.session.completeToss(id, reading: next) { self.store.recordDivination(next) }
            }
            self.sound.play("wood-clack", volume: self.volume, enabled: self.soundEnabled)
        }
    }

    func cancelTransient() {
        beadIdleTask?.cancel(); beadIdleTask = nil
        ignitionTask?.cancel(); ignitionTask = nil
        session.cancelIgnition()
        beads.stop()
        tossTask?.cancel(); tossTask = nil
        strikeTask?.cancel(); strikeTask = nil
        popupTasks.values.forEach { $0.cancel() }; popupTasks.removeAll()
        session.cancelToss()
        if let id = session.strikeID { session.endStrike(id) }
        strikePhase = false
        meritPopups.removeAll()
        sound.stopAll()
    }

    func resetStatistics() {
        cancelTransient()
        store.resetStatistics()
        session.clearReading()
        beads = BeadScrollState()
        objectWillChange.send()
    }
}
