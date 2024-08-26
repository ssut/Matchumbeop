import AppKit

@MainActor final class ServicesProvider: NSObject {
    private var appDelegate: AppDelegate

    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
    }
    
    
    @objc func handlePasteAndCheck(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        if let data = pboard.data(forType: .rtf) {
            if let text = NSAttributedString(rtf: data, documentAttributes: nil)?.string {
                appDelegate.pasteAndCheck(input: text)
            } else {
                error.pointee = "텍스트를 가져오는 데 실패했습니다." as NSString
            }
        } else if let data = pboard.data(forType: .rtfd) {
            if let text = NSAttributedString(rtf: data, documentAttributes: nil)?.string {
                appDelegate.pasteAndCheck(input: text)
            } else {
                error.pointee = "텍스트를 가져오는 데 실패했습니다." as NSString
            }
        } else if let text = pboard.string(forType: .string) {
            appDelegate.pasteAndCheck(input: text)
        } else {
            error.pointee = "텍스트를 가져오는 데 실패했습니다." as NSString
        }
    }
    
}
