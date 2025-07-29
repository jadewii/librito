//
//  LibritoApp.swift
//  Librito
//
//  Minimalist Archive.org media browser and downloader
//

import SwiftUI
import AVFoundation

@main
struct LibritoApp: App {
    @StateObject private var appState = AppStateManager.shared
    
    var body: some Scene {
        WindowGroup {
            LibritoMainView()
                .frame(
                    minWidth: appState.isMiniMode ? 400 : 800,
                    idealWidth: appState.isMiniMode ? 400 : 1200,
                    maxWidth: appState.isMiniMode ? 400 : .infinity,
                    minHeight: appState.isMiniMode ? 120 : 600,
                    idealHeight: appState.isMiniMode ? 120 : 800,
                    maxHeight: appState.isMiniMode ? 120 : .infinity
                )
        }
        #if os(macOS)
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(appState.isMiniMode ? .contentSize : .automatic)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Search Archive") {
                    // TODO: Implement search shortcut
                }
                .keyboardShortcut("f", modifiers: .command)
            }
        }
        #endif
    }
}

// MARK: - Media Types
enum MediaType: String, CaseIterable {
    case hub = "hub"
    case journal = "journal"
    case audiobooks = "audiobooks"
    case books = "books"
    case music = "music"
    case radio = "radio"
    
    var displayName: String {
        switch self {
        case .hub: return "🌐 Hub"
        case .journal: return "📝 Journal"
        case .audiobooks: return "📚 Audiobooks"
        case .books: return "📖 Books / PDFs"
        case .music: return "🎵 Music"
        case .radio: return "📻 Radio"
        }
    }
    
    var archiveMediaType: String? {
        switch self {
        case .hub: return nil // Hub is social features
        case .journal: return nil // Journal is local only
        case .audiobooks: return "audio"
        case .books: return "texts"
        case .music: return "audio"
        case .radio: return nil // Special handling for radio
        }
    }
}

// MARK: - Library Section
enum LibrarySection: String, CaseIterable {
    case myLibrary = "My Collection"
    case archiveLibrary = "Library"
    
    var displayName: String {
        return self.rawValue
    }
}