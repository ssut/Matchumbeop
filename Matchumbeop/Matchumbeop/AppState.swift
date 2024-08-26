import SwiftUI
import KeyboardShortcuts
import Combine
import Defaults

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState(appDelegate: nil)
    
    private weak var appDelegate: AppDelegate?
    
    @Published var text = ""
    @Published var isLoading = false
    @Published var result: AttributedString?
    @Published var errorMessage: String?
    @Published var showToast = false
    @Published var progress: Double = 0
    
    @Published var appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    
    private lazy var analytics: Analytics = MatchumbeopAnalytics.shared
    
    @Published var spellChecker: SpellChecker
    private var cancellables = Set<AnyCancellable>()
    
    init(appDelegate: AppDelegate?) {
        self.spellChecker = AppState.createSpellChecker(for: Defaults[.spellCheckerEngine])
        self.appDelegate = appDelegate
        
        Defaults.publisher(.spellCheckerEngine)
            .removeDuplicates()
            .sink { [weak self] value in
                self?.updateSpellChecker(for: value.newValue)
            }
            .store(in: &cancellables)
        
        KeyboardShortcuts.onKeyUp(for: .togglePopover) { [weak self] in
            self?.toggleWindow()
        }
        
        //        KeyboardShortcuts.onKeyUp(for: .checkSelection) { [weak self] in
        //            if let text = getSelectedText() {
        //                self?.pasteAndCheck(text: text)
        //            }
        //        }
        
        KeyboardShortcuts.onKeyUp(for: .pasteAndCheck) { [weak self] in
            let text = NSPasteboard.general.string(forType: .string) ?? ""
            self?.pasteAndCheck(input: text)
            
            if !text.isEmpty {
                self?.analytics.send(.spellChecked(method: .clipboard, length: text.count))
            }
        }
    }
    
    private static func createSpellChecker(for engine: SpellCheckerEngine) -> SpellChecker {
        switch engine {
        case .naver:
            return NaverSpellChecker()
            //        case .kakao:
            //            print("changed to kakao")
            //            return NaverSpellChecker()
        }
    }
    
    private func updateSpellChecker(for engine: SpellCheckerEngine) {
        self.spellChecker = AppState.createSpellChecker(for: engine)
    }
    
    func setAppDelegate(_ appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
    }
    
    func openSettings() {
        appDelegate?.openSettings()
    }
    
    func toggleWindow() {
        if appDelegate?.togglePopover() == true {
            self.analytics.send(.applicationDidBecomeActive(method: .keyboardShortcut))
        }
    }
    
    func checkForUpdate() {
        appDelegate?.checkForUpdate()
    }
    
    func pasteAndCheck(input: String) {
        appDelegate?.pasteAndCheck(input: input)
    }
    
    @MainActor func checkSpelling(text: String) async {
        guard !text.isEmpty else {
            self.result = nil
            return
        }
        
        isLoading = true
        progress = 10
        errorMessage = nil
        result = nil
        
        do {
            let htmlString: String
            if text.count > 300 {
                let responses = try await spellChecker.correctLongText(text, eol: "\n")
                htmlString = responses.map { $0.message.result.html }.joined(separator: " ")
            } else {
                let response = try await spellChecker.correctText(text, eol: "\n")
                htmlString = response.message.result.html
            }
            
            DispatchQueue.main.async {
                self.result = formatCorrectedText(htmlString)
                self.isLoading = false
                self.progress = 100
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "오류: 잠시 후 다시 시도해 주세요."
                self.isLoading = false
                self.progress = 100
            }
        }
    }
}
