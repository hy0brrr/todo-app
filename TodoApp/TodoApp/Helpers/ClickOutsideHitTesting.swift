import AppKit

enum ClickOutsideHitTesting {
    static func shouldTreatAsOutsideClick(hitView: NSView?) -> Bool {
        !isTextEditingView(hitView)
    }

    static func isTextEditingView(_ view: NSView?) -> Bool {
        guard let view else { return false }

        if containsTextEditingView(inSuperviewChainOf: view) {
            return true
        }

        return containsTextEditingView(inResponderChainOf: view)
    }

    private static func containsTextEditingView(inSuperviewChainOf view: NSView) -> Bool {
        var currentView: NSView? = view

        while let candidateView = currentView {
            if candidateView is NSTextView || candidateView is NSTextField {
                return true
            }

            currentView = candidateView.superview
        }

        return false
    }

    private static func containsTextEditingView(inResponderChainOf view: NSView) -> Bool {
        var currentResponder: NSResponder? = view

        while let candidateResponder = currentResponder {
            if candidateResponder is NSTextView || candidateResponder is NSTextField {
                return true
            }

            currentResponder = candidateResponder.nextResponder
        }

        return false
    }
}
