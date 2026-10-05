import Foundation

/// Converts smooth trackpad deltas and stepped wheel events to bead movement.
public struct BeadScrollState {
    public private(set) var position = 0.0
    public private(set) var rolledCount = 0
    public private(set) var lastInputAt: TimeInterval?
    public private(set) var velocity = 0.0
    private var travel = 0.0

    public init() { }
    @discardableResult public mutating func scroll(delta: Double, precise: Bool, now: TimeInterval) -> Int {
        guard delta.isFinite, now.isFinite, delta != 0 else { return 0 }
        // Each ordinary wheel notch advances one bead. Precise devices accumulate pixels.
        let movement = precise ? delta / 24 : delta
        let safeMovement = min(12, max(-12, movement))
        let interval = lastInputAt.map { min(0.25, max(1.0 / 120, now - $0)) } ?? 0.08
        velocity = min(45, abs(safeMovement) / interval)
        lastInputAt = now
        position += safeMovement
        if abs(position) > 1_000_000 { position = position.truncatingRemainder(dividingBy: 18) }
        travel += abs(safeMovement)
        let count = Int(floor(travel + 1e-9))
        travel -= Double(count)
        rolledCount = min(Int.max - count, rolledCount) + count
        return count
    }
    public func speed(now: TimeInterval) -> Double {
        guard now.isFinite, let lastInputAt else { return 0 }
        return velocity * exp(-max(0, now - lastInputAt) / 0.13)
    }
    public mutating func stop() { velocity = 0; lastInputAt = nil }
}
