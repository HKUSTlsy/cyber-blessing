import Foundation

public enum BlessingMode: String, CaseIterable {
    case incense, divination, woodfish, beads

    public var title: String {
        switch self {
        case .incense: return "上香"
        case .divination: return "掷圣杯"
        case .woodfish: return "敲木鱼"
        case .beads: return "盘串"
        }
    }

    public var symbol: String {
        switch self {
        case .incense: return "flame"
        case .divination: return "moonphase.waning.crescent"
        case .woodfish: return "hand.tap"
        case .beads: return "circle.dotted"
        }
    }
}

/// Retains the original preference keys so upgrades preserve existing counts.
public final class BlessingStore {
    private let defaults: UserDefaults
    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    public var mode: BlessingMode {
        get {
            if let raw = defaults.string(forKey: "blessing.mode"), let mode = BlessingMode(rawValue: raw) { return mode }
            if defaults.object(forKey: "blessing.mode") != nil { return .incense }
            return defaults.object(forKey: "blessing.showingIncense") == nil || defaults.bool(forKey: "blessing.showingIncense") ? .incense : .divination
        }
        set { defaults.set(newValue.rawValue, forKey: "blessing.mode") }
    }
    public var incenseStartedAt: TimeInterval {
        get { defaults.double(forKey: "incense.startedAt") }
        set { defaults.set(newValue, forKey: "incense.startedAt") }
    }
    public var incenseCount: Int { max(0, defaults.integer(forKey: "incense.count")) }
    public var divinationCount: Int { max(0, defaults.integer(forKey: "divination.count")) }
    public var beadCount: Int { max(0, defaults.integer(forKey: "beads.count")) }
    public var meritCount: Int { max(0, defaults.integer(forKey: "woodfish.merit")) }
    public var soundEnabled: Bool {
        get { defaults.object(forKey: "sound.enabled") == nil || defaults.bool(forKey: "sound.enabled") }
        set { defaults.set(newValue, forKey: "sound.enabled") }
    }
    public var volume: Double {
        get {
            guard defaults.object(forKey: "sound.volume") != nil else { return 0.7 }
            let value = defaults.double(forKey: "sound.volume")
            return value.isFinite ? min(1, max(0, value)) : 0.7
        }
        set { defaults.set(newValue.isFinite ? min(1, max(0, newValue)) : 0.7, forKey: "sound.volume") }
    }
    public var reduceMotion: Bool {
        get { defaults.bool(forKey: "motion.reduced") }
        set { defaults.set(newValue, forKey: "motion.reduced") }
    }
    public var lastReading: DivinationReading? {
        get {
            guard let a = defaults.string(forKey: "divination.first").flatMap(CupFace.init(rawValue:)),
                  let b = defaults.string(forKey: "divination.second").flatMap(CupFace.init(rawValue:)) else { return nil }
            return DivinationReading(first: a, second: b)
        }
        set {
            defaults.set(newValue?.first.rawValue, forKey: "divination.first")
            defaults.set(newValue?.second.rawValue, forKey: "divination.second")
        }
    }
    public func lightIncense(now: TimeInterval, duration: TimeInterval = 1_800) -> Bool {
        guard now.isFinite, now > 0,
              !IncenseBurnState(startedAt: incenseStartedAt, now: now, duration: duration).isBurning else { return false }
        increment("incense.count")
        incenseStartedAt = now
        return true
    }
    public func recordDivination(_ reading: DivinationReading) {
        increment("divination.count")
        lastReading = reading
    }
    public func strikeWoodfish() { increment("woodfish.merit") }
    public func recordBeads(_ count: Int) {
        guard count > 0 else { return }
        let value = beadCount
        defaults.set(value > Int.max - count ? Int.max : value + count, forKey: "beads.count")
    }
    private func increment(_ key: String) {
        let value = max(0, defaults.integer(forKey: key))
        defaults.set(value == Int.max ? value : value + 1, forKey: key)
    }
    /// Only statistics are erased; a burning incense and user settings survive.
    public func resetStatistics() {
        ["incense.count", "divination.count", "woodfish.merit", "beads.count", "divination.first", "divination.second"].forEach(defaults.removeObject(forKey:))
    }
}
