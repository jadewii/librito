//
//  AppStateManager.swift
//  Librito
//
//  Manages the app's view mode (full/mini player)
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

class AppStateManager: ObservableObject {
    static let shared = AppStateManager()
    
    @Published var isMiniMode = false
    @Published var miniPlayerPosition = CGPoint(x: 100, y: 100)
    @Published var isAlwaysOnTop = false
    
    private init() {}
    
    func toggleMiniMode() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isMiniMode.toggle()
        }
    }
    
    func setAlwaysOnTop(_ enabled: Bool) {
        isAlwaysOnTop = enabled
        #if os(macOS)
        if let window = NSApplication.shared.windows.first {
            window.level = enabled && isMiniMode ? .floating : .normal
        }
        #endif
    }
}