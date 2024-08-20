import SwiftUI
import AppKit

struct DraggableTextView: NSViewRepresentable {
    let attributedText: NSAttributedString
    var font: NSFont
    
    init(attributedText: NSAttributedString, font: NSFont = .systemFont(ofSize: 14)) {
        self.attributedText = attributedText
        self.font = font
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 0, height: 0)
        textView.backgroundColor = .clear
        textView.registerForDraggedTypes([.string])
        
        if let textContainer = textView.textContainer {
            textContainer.lineFragmentPadding = 0
            textContainer.heightTracksTextView = false
            textContainer.widthTracksTextView = true
            textContainer.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        }
        
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.documentView = textView
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        textView.textStorage?.setAttributedString(attributedText)
        textView.font = font
        
        nsView.invalidateIntrinsicContentSize()
    }
}
