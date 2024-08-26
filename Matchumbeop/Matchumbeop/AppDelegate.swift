import SwiftUI
import KeyboardShortcuts
import FirebaseCore
import Defaults

class AppDelegate: NSObject, NSApplicationDelegate {
    @StateObject var appState = AppState.shared

    var popover: NSPopover!
    var statusBarItem: NSStatusItem!
    var menu: NSMenu!
    var settingsWindow: NSWindow?
    var resultWindowController: NSWindowController?

    private lazy var analytics: Analytics = MatchumbeopAnalytics.shared

    let updateChecker = UpdateChecker(
        hostBundle: locateHostBundleURL(url: Bundle.main.bundleURL)
            .flatMap(Bundle.init(url:)),
        shouldAutomaticallyCheckForUpdate: true
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppState.shared.setAppDelegate(self)
        updateChecker.updateCheckerDelegate = self

        FirebaseApp.configure()
        
        NSApp.servicesProvider = ServicesProvider(appDelegate: self)

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
        
        _ = updateHasLaunchedOnce()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            _ = self.togglePopover()
        }
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        NSApp.unhide(self)
        
        if !popover.isShown {
            _ = togglePopover()
        }
    }
    
    func updateHasLaunchedOnce() -> Bool {
        if !Defaults[.hasLaunchedOnce] {
            Defaults[.hasLaunchedOnce] = true
            return true
        }
        
        return false
    }

    @MainActor @objc func pasteAndCheck(input: String) {
        _ = togglePopover()

        let text = input.trimmed()
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

    @objc func handleStatusBarClick(sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!

        if event.type ==  NSEvent.EventType.rightMouseUp {
            statusBarItem.menu = menu
            statusBarItem.button?.performClick(nil)
            statusBarItem.menu = nil
        } else {
            if togglePopover() {
                self.analytics.send(.applicationDidBecomeActive(method: .menuBar))
            }
        }
    }

    @objc func togglePopover() -> Bool {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            if let button = statusBarItem?.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
                return true
            }
        }

        return false
    }

    @MainActor @objc func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
                .environmentObject(AppState.shared)

            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 360),
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
            self.analytics.send(.settingsOpened)
        }
    }

    @objc func checkForUpdate() {
        updateChecker.checkForUpdates()
    }

    @objc func quitApp() {
        self.analytics.send(.quit, forceSend: true)

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
