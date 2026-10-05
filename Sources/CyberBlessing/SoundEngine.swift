import AVFoundation

@MainActor
final class SoundEngine {
    private var players: [String: [AVAudioPlayer]] = [:]
    private var cursor: [String: Int] = [:]

    init() {
        for (name, count) in [("woodfish-tap", 6), ("wood-clack", 2), ("match-strike", 1), ("match-light", 1), ("bead-click", 4)] {
            guard let url = AppMetadata.resourceURL(name, withExtension: "wav") else {
                NSLog("Missing bundled sound: %@", name)
                continue
            }
            do {
                players[name] = try (0..<count).map { _ in
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    return player
                }
            } catch { NSLog("Could not prepare %@: %@", name, error.localizedDescription) }
        }
    }

    func play(_ name: String, volume: Double, enabled: Bool) {
        guard enabled, volume > 0, let pool = players[name], !pool.isEmpty else { return }
        let index = pool.firstIndex(where: { !$0.isPlaying }) ?? (cursor[name, default: 0] % pool.count)
        let player = pool[index]
        if player.isPlaying { player.stop() }
        player.currentTime = 0
        player.volume = Float(min(1, max(0, volume))) * (name == "bead-click" ? 0.20 : (name == "woodfish-tap" ? 0.55 : 0.75))
        player.play()
        cursor[name] = index + 1
    }

    func stopAll() { players.values.flatMap { $0 }.forEach { $0.stop() } }
    var preparedPlayerCount: Int { players.values.reduce(0) { $0 + $1.count } }
    var activePlayerCount: Int { players.values.flatMap { $0 }.filter(\.isPlaying).count }
}
