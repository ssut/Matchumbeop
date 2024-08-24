import Foundation

enum ApplicationActivationMethod: String {
    case menuBar, keyboardShortcut
}

enum SpellCheckMethod: String {
    case inApp, service, clipboard
}

extension AnalyticsEvent {
    static let settingsOpened = MatchumbeopAnalyticsEvent(name: "settings_opened")
    static let quit = MatchumbeopAnalyticsEvent(name: "quit")
    static let textCopied = MatchumbeopAnalyticsEvent(name: "text_copied")

    static func applicationDidBecomeActive(method: ApplicationActivationMethod) -> MatchumbeopAnalyticsEvent {
        MatchumbeopAnalyticsEvent(name: "app_opened", parameters: ["method": method.rawValue])
    }

    static func spellChecked(method: SpellCheckMethod, length: Int) -> MatchumbeopAnalyticsEvent {
        MatchumbeopAnalyticsEvent(name: "spell_checked", parameters: ["method": method.rawValue, "length": length])
    }
}
