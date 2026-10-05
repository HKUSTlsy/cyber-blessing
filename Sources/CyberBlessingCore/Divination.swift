import Foundation

public enum CupFace: String, Equatable {
    case yang
    case yin
}

public enum DivinationOutcome: String, Equatable {
    case holy
    case laughing
    case yin

    public static func resolve(_ first: CupFace, _ second: CupFace) -> DivinationOutcome {
        switch (first, second) {
        case (.yang, .yin), (.yin, .yang): .holy
        case (.yang, .yang): .laughing
        case (.yin, .yin): .yin
        }
    }

    public var title: String {
        switch self {
        case .holy: "圣杯"
        case .laughing: "笑杯"
        case .yin: "阴杯"
        }
    }

    public var explanation: String {
        switch self {
        case .holy: "一阴一阳，常被视作允准的象征。"
        case .laughing: "两面皆阳，传统上常解作笑而未决。"
        case .yin: "两面皆阴，传统上常解作暂不允准。"
        }
    }

    public var symbol: String {
        switch self {
        case .holy: "sparkles"
        case .laughing: "face.smiling"
        case .yin: "moon"
        }
    }
}

public struct DivinationReading: Equatable {
    public let first: CupFace
    public let second: CupFace

    public var outcome: DivinationOutcome {
        DivinationOutcome.resolve(first, second)
    }

    public init(first: CupFace, second: CupFace) {
        self.first = first
        self.second = second
    }

    public static func cast<R: RandomNumberGenerator>(using generator: inout R) -> DivinationReading {
        let first: CupFace = Bool.random(using: &generator) ? .yang : .yin
        let second: CupFace = Bool.random(using: &generator) ? .yang : .yin
        return DivinationReading(first: first, second: second)
    }
}
