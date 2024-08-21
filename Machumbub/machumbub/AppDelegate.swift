import SwiftUI
import KeyboardShortcuts
import FirebaseCore

class AppDelegate: NSObject, NSApplicationDelegate {
    @StateObject var appState = AppState.shared
    
    var popover: NSPopover!
    var statusBarItem: NSStatusItem!
    var menu: NSMenu!
    var settingsWindow: NSWindow?
    var resultWindowController: NSWindowController?
    
    let updateChecker = UpdateChecker(
        hostBundle: locateHostBundleURL(url: Bundle.main.bundleURL)
            .flatMap(Bundle.init(url:)),
        shouldAutomaticallyCheckForUpdate: true
    )
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppState.shared.setAppDelegate(self)
        updateChecker.updateCheckerDelegate = self
        
        FirebaseApp.configure()
        
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusBarItem?.button {
            button.image = NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: "한글 맞춤법 검사기")
            button.target = self
            button.action = #selector(handleStatusBarClick(sender:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        popover = NSPopover()
        popover.contentViewController = NSHostingController(rootView: ContentView())
        popover.behavior = .transient
        
        let statusBarMenu = NSMenu()
        statusBarMenu.minimumWidth = 120
        statusBarMenu.addItem(NSMenuItem(title: "설정", action: #selector(openSettings), keyEquivalent: ""))
        statusBarMenu.addItem(NSMenuItem(title: "업데이트 확인", action: #selector(checkForUpdate), keyEquivalent: ""))
        statusBarMenu.addItem(NSMenuItem.separator())
        statusBarMenu.addItem(NSMenuItem(title: "종료", action: #selector(quitApp), keyEquivalent: ""))
        
        menu = statusBarMenu
    }
    
    @MainActor @objc func pasteAndCheck(input: String? = nil) {
        togglePopover()
        
        let text = (input ?? NSPasteboard.general.string(forType: .string) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty {
            return
        }
        
        AppState.shared.text = text
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            AppState.shared.isLoading = true
            Task {
                await AppState.shared.checkSpelling(text: text)
            }
        }
    }
    
    func handleServiceRequest(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        if let data = pboard.data(forType: .rtf) {
            if let text = NSAttributedString(rtf: data, documentAttributes: nil)?.string {
                pasteAndCheck(input: text)
            } else {
                error.pointee = "텍스트를 가져오는 데 실패했습니다." as NSString
            }
        } else if let data = pboard.data(forType: .rtfd) {
            if let text = NSAttributedString(rtf: data, documentAttributes: nil)?.string {
                pasteAndCheck(input: text)
            } else {
                error.pointee = "텍스트를 가져오는 데 실패했습니다." as NSString
            }
        } else if let text = pboard.string(forType: .string) {
            pasteAndCheck(input: text)
        } else {
            error.pointee = "텍스트를 가져오는 데 실패했습니다." as NSString
        }
    }
    
    @objc func handleStatusBarClick(sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        
        if event.type ==  NSEvent.EventType.rightMouseUp {
            statusBarItem.menu = menu
            statusBarItem.button?.performClick(nil)
            statusBarItem.menu = nil
        } else {
            togglePopover()
        }
    }
    
    @objc func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            if let button = statusBarItem?.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    @MainActor @objc func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
                .environmentObject(AppState.shared)
            
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 300),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered, defer: false)
            
            settingsWindow?.center()
            settingsWindow?.title = "설정"
            settingsWindow?.contentView = NSHostingView(rootView: settingsView)
            settingsWindow?.isReleasedWhenClosed = false
        }
        
        NSApp.deactivate()
        if let settingsWindow = settingsWindow {
            settingsWindow.makeKeyAndOrderFront(nil)
            settingsWindow.orderFrontRegardless()
            
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    @objc func checkForUpdate() {
        updateChecker.checkForUpdates()
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}

extension AppDelegate: UpdateCheckerDelegate {
    func prepareForRelaunch(finish: @escaping () -> Void) {
        Task {
            finish()
        }
    }
}
