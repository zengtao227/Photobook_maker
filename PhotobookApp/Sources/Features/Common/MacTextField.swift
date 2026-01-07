import SwiftUI
import AppKit

/// A wrapper around NSTextField to solve SwiftUI focus issues on macOS
struct MacTextField: NSViewRepresentable {
    var placeholder: String
    @Binding var text: String
    var onCommit: () -> Void
    var onCancel: () -> Void
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
        textField.focusRingType = .default
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
        
        // Auto-focus logic: If the view is in a window, try to make it first responder
        DispatchQueue.main.async {
            if let window = nsView.window, window.firstResponder != nsView.currentEditor() && window.firstResponder != nsView {
                window.makeFirstResponder(nsView)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: MacTextField
        
        init(parent: MacTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            parent.text = textField.stringValue
        }
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onCommit()
                return true
            } else if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                parent.onCancel()
                return true
            }
            return false
        }
    }
}
