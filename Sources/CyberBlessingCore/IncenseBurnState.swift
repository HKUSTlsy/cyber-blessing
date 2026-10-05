import Foundation

public struct IncenseBurnState: Equatable {
    public let progress: Double
    public let remainingSeconds: Int
    public let isBurning: Bool

    public init(startedAt: TimeInterval, now: TimeInterval, duration: TimeInterval = 30 * 60) {
        // Bound malformed imported preferences before any conversion to Int.
        let safeDuration = duration.isFinite ? min(86_400, max(1, duration)) : 1_800
        guard startedAt.isFinite, startedAt > 0, now.isFinite else {
            progress = 0
            remainingSeconds = Int(ceil(safeDuration))
            isBurning = false
            return
        }
        // Wall-clock rollback never produces negative progress or an overlong countdown.
        let elapsed = max(0, now - startedAt)
        progress = min(1, elapsed / safeDuration)
        remainingSeconds = Int(ceil(max(0, safeDuration - elapsed)))
        isBurning = elapsed < safeDuration
    }
}
