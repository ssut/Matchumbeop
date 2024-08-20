import SwiftUI
import KeyboardShortcuts

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState(appDelegate: nil)
    
    @Published var text = ""
    @Published var isLoading = false
    @Published var result: AttributedString?
    @Published var errorMessage: String?
    @Published var showToast = false
    
    @Published var appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    
    var spellChecker = SpellChecker()
    private weak var appDelegate: AppDelegate?
    
    init(appDelegate: AppDelegate?) {
        self.appDelegate = appDelegate
        
        KeyboardShortcuts.onKeyUp(for: .togglePopover) { [weak self] in
            self?.toggleWindow()
        }
        
//        KeyboardShortcuts.onKeyUp(for: .checkSelection) { [weak self] in
//            if let text = getSelectedText() {
//                self?.pasteAndCheck(text: text)
//            }
//        }
        
        KeyboardShortcuts.onKeyUp(for: .pasteAndCheck) { [weak self] in
            self?.pasteAndCheck()
        }
    }
    
    func setAppDelegate(_ appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
    }
    
    func openSettings() {
        appDelegate?.openSettings()
    }
    
    func toggleWindow() {
        appDelegate?.togglePopover()
    }
    
    func checkForUpdate() {
        appDelegate?.checkForUpdate()
    }
    
    func pasteAndCheck(text: String? = nil) {
        appDelegate?.pasteAndCheck(input: text)
    }
    
    @MainActor
    func checkSpelling(text: String) async {
        guard !text.isEmpty else {
            self.result = nil
            return
        }
        
        isLoading = true
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
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "오류: 잠시 후 다시 시도해 주세요."
                self.isLoading = false
            }
        }
    }
}
