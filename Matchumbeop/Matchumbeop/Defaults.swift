import Foundation
import Defaults

enum SpellCheckerEngine: String, Defaults.Serializable, CaseIterable, Identifiable, CustomStringConvertible {
    case naver
    
    var id: Self { self }

    var description: String {
        switch self {
        case .naver:
            return "네이버 (NAVER)"
//        case .kakao:
//            return "카카오 (Daum)"
        }
    }
}

extension Defaults.Keys {
    static let hasLaunchedOnce = Key<Bool>("hasLaunchedOnce", default: false)
    static let spellCheckerEngine = Key<SpellCheckerEngine>("spellCheckerEngine", default: .naver)
}
