import ApplicationServices
import SwiftUI
import SwiftSoup

func getSelectedText() -> String? {
    let systemWideElement = AXUIElementCreateSystemWide()

    var selectedTextValue: AnyObject?
    let errorCode = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &selectedTextValue)
    
    if errorCode == .success {
        let selectedTextElement = selectedTextValue as! AXUIElement
        var selectedText: AnyObject?
        let textErrorCode = AXUIElementCopyAttributeValue(selectedTextElement, kAXSelectedTextAttribute as CFString, &selectedText)
        
        if textErrorCode == .success, let selectedTextString = selectedText as? String {
            return selectedTextString
        } else {
            return nil
        }
    } else {
        return nil
    }
}

func formatCorrectedText(_ htmlString: String) -> AttributedString? {
     do {
          let document = try SwiftSoup.parseBodyFragment(htmlString)
          let body = document.body()
          
          let attributedString = NSMutableAttributedString()
          for node in body?.getChildNodes() ?? [] {
               if let textNode = node as? TextNode {
                    let text = textNode.text()
                    attributedString.append(NSAttributedString(string: text, attributes: [.foregroundColor: NSColor.textColor]))
               } else if let element = node as? Element {
                    let tagName = element.tagName()
                    if tagName == "br" {
                         attributedString.append(NSAttributedString(string: "\n"))
                    } else if tagName == "em" {
                         let elementText = try element.text()
                         var attrs: [NSAttributedString.Key: Any] = [:]
                         
                         if let className = try? element.className() {
                              switch className {
                              case "green_text":
                                   attrs[.foregroundColor] = NSColor(Green).withAlphaComponent(1)
                                   
                              case "violet_text":
                                   attrs[.foregroundColor] = NSColor(Violet).withAlphaComponent(1)
                                   
                              case "red_text":
                                   attrs[.foregroundColor] = NSColor(Red).withAlphaComponent(1)
                                   
                              case "blue_text":
                                   attrs[.foregroundColor] = NSColor(Blue).withAlphaComponent(1)
                                   
                              default:
                                   break
                              }
                         }
                         
                         let attributedElement = NSAttributedString(string: elementText, attributes: attrs)
                         attributedString.append(attributedElement)
                    } else {
                         let elementText = try element.text()
                         attributedString.append(NSAttributedString(string: elementText, attributes: [.foregroundColor: NSColor.textColor]))
                    }
               }
          }
          
          return AttributedString(attributedString)
     } catch {
          print(error)
          return nil
     }
}

func locateHostBundleURL(url: URL) -> URL? {
    var nextURL = url
    while nextURL.path != "/" {
        nextURL = nextURL.deletingLastPathComponent()
        if nextURL.lastPathComponent.hasSuffix(".app") {
            return nextURL
        }
    }
    
    let devAppURL = url
        .deletingLastPathComponent()
        .appendingPathComponent("Machumbub Dev.app")
    return devAppURL
}
