import Foundation
import CyberBlessingCore

public struct CoreCheck {
    public let name: String
    public let run: () throws -> Void
}
public struct CheckFailure: Error, CustomStringConvertible {
    public let description: String
}
private func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() { throw CheckFailure(description: message) }
}
private func withStore(_ body: (BlessingStore, UserDefaults, String) throws -> Void) throws {
    let suite = "dev.cyberblessing.checks.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    try body(BlessingStore(defaults: defaults), defaults, suite)
}

public enum CoreChecks {
    public static let all: [CoreCheck] = [
        CoreCheck(name: "all four cup faces") {
            try require(DivinationOutcome.resolve(.yang, .yin) == .holy, "yang/yin")
            try require(DivinationOutcome.resolve(.yin, .yang) == .holy, "yin/yang")
            try require(DivinationOutcome.resolve(.yang, .yang) == .laughing, "yang/yang")
            try require(DivinationOutcome.resolve(.yin, .yin) == .yin, "yin/yin")
        },
        CoreCheck(name: "reading metadata") {
            let reading = DivinationReading(first: .yang, second: .yin)
            try require(reading.outcome.title == "圣杯" && !reading.outcome.explanation.isEmpty, "reading metadata")
        },
        CoreCheck(name: "unlit incense") {
            let x = IncenseBurnState(startedAt: 0, now: 100)
            try require(x.progress == 0 && x.remainingSeconds == 1_800 && !x.isBurning, "unlit state")
        },
        CoreCheck(name: "halfway incense") {
            let x = IncenseBurnState(startedAt: 1_000, now: 1_900)
            try require(x.progress == 0.5 && x.remainingSeconds == 900 && x.isBurning, "halfway state")
        },
        CoreCheck(name: "burnout boundary") {
            let x = IncenseBurnState(startedAt: 1_000, now: 2_800)
            try require(x.progress == 1 && x.remainingSeconds == 0 && !x.isBurning, "boundary")
        },
        CoreCheck(name: "long after burnout") {
            let x = IncenseBurnState(startedAt: 1_000, now: 99_999)
            try require(x.progress == 1 && x.remainingSeconds == 0 && !x.isBurning, "after burnout")
        },
        CoreCheck(name: "clock rollback") {
            let x = IncenseBurnState(startedAt: 1_000, now: 900)
            try require(x.progress == 0 && x.remainingSeconds == 1_800 && x.isBurning, "clock rollback clamp")
        },
        CoreCheck(name: "fractional countdown") {
            try require(IncenseBurnState(startedAt: 1_000, now: 2_799.2).remainingSeconds == 1, "ceil final second")
        },
        CoreCheck(name: "invalid timestamp") {
            for value in [Double.nan, .infinity, -.infinity, -1] {
                try require(!IncenseBurnState(startedAt: value, now: 1_000).isBurning, "invalid start")
            }
            try require(!IncenseBurnState(startedAt: 1, now: .nan).isBurning, "invalid now")
        },
        CoreCheck(name: "invalid duration") {
            try require(IncenseBurnState(startedAt: 1, now: 1, duration: 0).remainingSeconds == 1, "zero duration")
            try require(IncenseBurnState(startedAt: 1, now: 1, duration: .infinity).remainingSeconds == 1_800, "infinite duration")
            try require(IncenseBurnState(startedAt: 1, now: 1, duration: Double.greatestFiniteMagnitude).remainingSeconds == 86_400, "duration bound")
        },
        CoreCheck(name: "legacy mode migration") {
            try withStore { store, defaults, _ in
                try require(store.mode == .incense, "default mode")
                defaults.set(false, forKey: "blessing.showingIncense")
                try require(store.mode == .divination, "legacy mode")
                store.mode = .woodfish
                try require(store.mode == .woodfish, "new mode wins")
                defaults.set("invalid", forKey: "blessing.mode")
                try require(store.mode == .incense, "invalid mode fallback")
            }
        },
        CoreCheck(name: "prevent double lighting") {
            try withStore { store, _, _ in
                try require(store.lightIncense(now: 1_000), "first lighting")
                try require(!store.lightIncense(now: 1_001) && store.incenseCount == 1, "double lighting blocked")
                try require(store.lightIncense(now: 2_800) && store.incenseCount == 2, "relight after burnout")
                try require(!store.lightIncense(now: .nan), "invalid clock blocked")
            }
        },
        CoreCheck(name: "persist across store recreation") {
            try withStore { store, defaults, suite in
                store.mode = .woodfish; store.volume = 0.25; store.soundEnabled = false; store.reduceMotion = true
                _ = store.lightIncense(now: 1_000); store.strikeWoodfish()
                store.recordDivination(DivinationReading(first: .yin, second: .yang))
                defaults.synchronize()
                let reopened = BlessingStore(defaults: UserDefaults(suiteName: suite)!)
                try require(reopened.incenseStartedAt == 1_000 && reopened.incenseCount == 1 && reopened.meritCount == 1 && reopened.divinationCount == 1, "persistent counters")
                try require(reopened.lastReading?.outcome == .holy, "persistent reading")
                try require(reopened.mode == .woodfish && reopened.volume == 0.25 && !reopened.soundEnabled && reopened.reduceMotion, "persistent settings")
                try require(IncenseBurnState(startedAt: reopened.incenseStartedAt, now: 1_900).remainingSeconds == 900, "closed window timer")
            }
        },
        CoreCheck(name: "statistics reset retains burning and settings") {
            try withStore { store, _, _ in
                _ = store.lightIncense(now: 1_000); store.strikeWoodfish()
                store.recordDivination(DivinationReading(first: .yin, second: .yin)); store.volume = 0.3; store.soundEnabled = false
                store.resetStatistics()
                try require(store.incenseCount == 0 && store.divinationCount == 0 && store.meritCount == 0 && store.lastReading == nil, "reset statistics")
                try require(store.incenseStartedAt == 1_000 && store.volume == 0.3 && !store.soundEnabled, "preserved state")
            }
        },
        CoreCheck(name: "volume normalization") {
            try withStore { store, defaults, _ in
                try require(store.volume == 0.7 && store.soundEnabled, "sound defaults")
                store.volume = -1; try require(store.volume == 0, "lower bound")
                store.volume = 2; try require(store.volume == 1, "upper bound")
                store.volume = .nan; try require(store.volume == 0.7, "nonfinite setter")
                defaults.set(Double.infinity, forKey: "sound.volume"); try require(store.volume == 0.7, "nonfinite stored value")
            }
        },
        CoreCheck(name: "counter saturation and negative repair") {
            try withStore { store, defaults, _ in
                defaults.set(Int.max, forKey: "woodfish.merit"); store.strikeWoodfish()
                try require(store.meritCount == Int.max, "overflow safe")
                defaults.set(-99, forKey: "woodfish.merit"); store.strikeWoodfish()
                try require(store.meritCount == 1, "negative counter repaired")
            }
        },
        CoreCheck(name: "rapid woodfish counts") {
            try withStore { store, _, _ in
                for _ in 0..<200 { store.strikeWoodfish() }
                try require(store.meritCount == 200, "rapid counts")
            }
        },
        CoreCheck(name: "duplicate toss blocked") {
            var x = RitualSession()
            let id = x.beginToss()!
            try require(x.beginToss() == nil && x.tossID == id, "toss reentry blocked")
        },
        CoreCheck(name: "landing commits exactly once") {
            var x = RitualSession(); let id = x.beginToss()!
            x.landToss(id); try require(!x.cupsInAir && x.isTossing, "landing phase")
            let reading = DivinationReading(first: .yang, second: .yin)
            try require(x.completeToss(id, reading: reading), "first completion")
            try require(!x.completeToss(id, reading: reading) && x.reading == reading && !x.isTossing, "single completion")
        },
        CoreCheck(name: "cancelled toss cannot commit on another page") {
            var x = RitualSession(); let old = x.beginToss()!; x.cancelToss(); let current = x.beginToss()!
            x.landToss(old)
            try require(x.cupsInAir && x.tossID == current, "obsolete landing ignored")
            try require(!x.completeToss(old, reading: DivinationReading(first: .yin, second: .yin)), "obsolete commit ignored")
            x.cancelToss(); try require(!x.isTossing && !x.cupsInAir, "cancel state")
        },
        CoreCheck(name: "latest strike owns completion") {
            var x = RitualSession(); let old = x.beginStrike(); let current = x.beginStrike()
            x.endStrike(old); try require(x.strikeID == current && x.isStriking, "old strike ignored")
            x.endStrike(current); try require(!x.isStriking, "latest strike completed")
        },
        CoreCheck(name: "new beads mode and persistence") {
            try withStore { store, defaults, suite in
                store.mode = .beads; store.recordBeads(12)
                defaults.synchronize()
                let other = BlessingStore(defaults: UserDefaults(suiteName: suite)!)
                try require(other.mode == .beads && other.beadCount == 12, "beads persist")
                other.resetStatistics(); try require(other.beadCount == 0, "beads reset")
            }
        },
        CoreCheck(name: "precise scroll accumulation") {
            var x = BeadScrollState()
            for i in 0..<4 { _ = x.scroll(delta: 6, precise: true, now: Double(i) / 60 + 1) }
            try require(x.rolledCount == 1 && abs(x.position - 1) < 0.0001, "four quarter movements make one bead")
        },
        CoreCheck(name: "wheel direction and continuous position") {
            var x = BeadScrollState()
            _ = x.scroll(delta: 18, precise: false, now: 1)
            _ = x.scroll(delta: 6, precise: false, now: 1.1)
            _ = x.scroll(delta: 1, precise: false, now: 1.2)
            try require(x.position == 19, "no reverse animation at ring wrap")
            _ = x.scroll(delta: -2, precise: false, now: 1.3)
            try require(x.position == 17 && x.rolledCount == 21, "reverse movement still counts travel")
        },
        CoreCheck(name: "wheel speed follows frequency and decays") {
            var slow = BeadScrollState(); var fast = BeadScrollState()
            _ = slow.scroll(delta: 1, precise: false, now: 1)
            _ = slow.scroll(delta: 1, precise: false, now: 1.2)
            _ = fast.scroll(delta: 1, precise: false, now: 1)
            _ = fast.scroll(delta: 1, precise: false, now: 1.02)
            try require(fast.velocity > slow.velocity, "speed follows input frequency")
            try require(fast.speed(now: 1.52) < fast.speed(now: 1.02), "speed decays")
            fast.stop(); try require(fast.velocity == 0, "stop feedback")
        },
        CoreCheck(name: "invalid scroll rejected") {
            var x = BeadScrollState()
            _ = x.scroll(delta: .nan, precise: true, now: 1)
            _ = x.scroll(delta: .infinity, precise: false, now: 1)
            _ = x.scroll(delta: 1, precise: true, now: .nan)
            try require(x.position == 0 && x.rolledCount == 0, "invalid scroll")
        },
        CoreCheck(name: "ignition duplicate and stale phase guarded") {
            var x = RitualSession(); let old = x.beginIgnition()!
            try require(x.beginIgnition() == nil && x.ignitionStage == .striking, "ignition cannot reenter")
            x.cancelIgnition(); let current = x.beginIgnition()!
            x.advanceIgnition(old, stage: .lighting)
            try require(x.ignitionID == current && x.ignitionStage == .striking, "obsolete phase ignored")
            x.advanceIgnition(current, stage: .approaching)
            try require(x.ignitionStage == .approaching, "current phase accepted")
            x.cancelIgnition(); try require(!x.isIgniting && x.ignitionStage == .idle, "cancel ignition")
        },
        CoreCheck(name: "random generator injection") {
            struct Seeded: RandomNumberGenerator {
                var seed: UInt64 = 20261005
                mutating func next() -> UInt64 { seed = seed &* 6364136223846793005 &+ 1442695040888963407; return seed }
            }
            var a = Seeded(); var b = Seeded(); var holy = 0; var laughing = 0; var yin = 0
            for _ in 0..<10_000 {
                let value = DivinationReading.cast(using: &a)
                try require(value == DivinationReading.cast(using: &b), "reproducible RNG")
                switch value.outcome { case .holy: holy += 1; case .laughing: laughing += 1; case .yin: yin += 1 }
            }
            try require((4_500...5_500).contains(holy) && (2_000...3_000).contains(laughing) && (2_000...3_000).contains(yin), "fixed-seed distribution")
        }
    ]
}
