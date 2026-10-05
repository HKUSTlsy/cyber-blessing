import Foundation

public enum IgnitionStage: String, CaseIterable {
    case idle, striking, flaring, approaching, lighting, withdrawing
}

/// Tokens keep obsolete animation completions from changing a newer ritual.
public struct RitualSession {
    public private(set) var reading: DivinationReading?
    public private(set) var tossID: UUID?
    public private(set) var cupsInAir = false
    public private(set) var ignitionID: UUID?
    public private(set) var ignitionStage: IgnitionStage = .idle
    public var isIgniting: Bool { ignitionID != nil }
    public private(set) var strikeID: UUID?
    public var isTossing: Bool { tossID != nil }
    public var isStriking: Bool { strikeID != nil }

    public init(reading: DivinationReading? = nil) { self.reading = reading }
    public mutating func beginToss() -> UUID? {
        guard !isTossing else { return nil }
        let id = UUID()
        tossID = id
        cupsInAir = true
        return id
    }
    public mutating func landToss(_ id: UUID) {
        guard tossID == id else { return }
        cupsInAir = false
    }
    @discardableResult public mutating func completeToss(_ id: UUID, reading: DivinationReading) -> Bool {
        guard tossID == id else { return false }
        self.reading = reading
        tossID = nil
        cupsInAir = false
        return true
    }
    public mutating func cancelToss() { tossID = nil; cupsInAir = false }
    public mutating func beginStrike() -> UUID {
        let id = UUID()
        strikeID = id
        return id
    }
    public mutating func endStrike(_ id: UUID) {
        if strikeID == id { strikeID = nil }
    }
    public mutating func beginIgnition() -> UUID? {
        guard !isIgniting else { return nil }
        let id = UUID(); ignitionID = id; ignitionStage = .striking
        return id
    }
    public mutating func advanceIgnition(_ id: UUID, stage: IgnitionStage) {
        if ignitionID == id { ignitionStage = stage }
    }
    public mutating func cancelIgnition() { ignitionID = nil; ignitionStage = .idle }
    public mutating func clearReading() { reading = nil }
}
