//
// Copyright (c) Vatsal Manot
//

#if os(iOS) || targetEnvironment(macCatalyst)

import Combine
import SwiftUI

@available(macCatalystApplicationExtension, unavailable)
@available(iOSApplicationExtension, unavailable)
private struct AddKeyboardPadding: ViewModifier {
    let isActive: Bool
    let isForced: Bool
    let isBasic: Bool
    let animation: Animation?
    
    @State var padding: CGFloat = 0
    
    private var isSystemEnabled: Bool {
        if #available(iOS 14.0, *) {
            return true
        } else {
            return false
        }
    }
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .padding(.bottom, (isActive && (!isSystemEnabled || isForced)) ? padding : 0)
                .onReceive(keyboardHeightPublisher, perform: { keyboardHeight in
                    if isBasic {
                        if !isForced {
                            padding = keyboardHeight > 0
                                ? keyboardHeight - geometry.safeAreaInsets.bottom
                                : 0
                        } else {
                            padding = keyboardHeight
                        }
                    } else {
                        padding = max(0, min((UIResponder.firstResponder?.globalFrame?.maxY ?? 0) - (geometry.frame(in: .global).height - keyboardHeight), keyboardHeight) - geometry.safeAreaInsets.bottom)
                    }
                })
                .animation(animation)
        }
    }
    
    private var keyboardHeightPublisher: Publishers.Merge<Publishers.CompactMap<NotificationCenter.Publisher, CGFloat>, Publishers.Map<NotificationCenter.Publisher, CGFloat>> {
        Publishers.Merge(
            NotificationCenter
                .default
                .publisher(for: UIResponder.keyboardWillShowNotification)
                .compactMap({ $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect })
                .map({ $0.height }),
            
            NotificationCenter
                .default
                .publisher(for: UIResponder.keyboardWillHideNotification)
                .map({ _ in 0 })
        )
    }
}

#endif

// MARK: - API -

public enum KeyboardPadding {
    case keyboard
    case keyboardForced // if you don't want this modifier automatically disabled for iOS 14
    case keyboardIntelligent // experimental
}

@available(macCatalystApplicationExtension, unavailable)
@available(iOSApplicationExtension, unavailable)
extension View {
    /// Pads this view with the active system height of the keyboard.
    public func padding(
        _ padding: KeyboardPadding?,
        animation: Animation = .spring()
    ) -> some View {
        #if os(iOS) || targetEnvironment(macCatalyst)
        return modifier(
            AddKeyboardPadding(
                isActive: padding != nil,
                isForced: padding == .keyboardForced,
                isBasic: !(padding == .keyboardIntelligent),
                animation: animation
            )
        )
        #else
        return self
        #endif
    }
}
