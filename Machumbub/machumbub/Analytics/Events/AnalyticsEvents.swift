import Foundation

enum ApplicationActivationMethod: String {
    case menuBar, keyboardShortcut
}

enum SpellCheckMethod: String {
    case inApp, service, clipboard
}

extension AnalyticsEvent {
    static let settingsOpened = MachumbubAnalyticsEvent(name: "settings_opened")
    static let quit = MachumbubAnalyticsEvent(name: "quit")
    static let textCopied = MachumbubAnalyticsEvent(name: "text_copied")
    
    static func applicationDidBecomeActive(method: ApplicationActivationMethod) -> MachumbubAnalyticsEvent {
        MachumbubAnalyticsEvent(name: "app_opened", parameters: ["method": method.rawValue])
    }
    
    static func spellChecked(method: SpellCheckMethod, length: Int) -> MachumbubAnalyticsEvent {
        MachumbubAnalyticsEvent(name: "spell_checked", parameters: ["method": method.rawValue, "length": length])
    }
}
