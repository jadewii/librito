//
//  LibritoMainView.swift
//  Librito
//
//  Main interface for the minimalist Library media browser
//

import SwiftUI
import AVFoundation

struct LibritoMainView: View {
    @StateObject private var bookManager = BookManager.shared
    @StateObject private var archiveService = ArchiveOrgService.shared
    @StateObject private var appState = AppStateManager.shared
    
    @State private var selectedSection: LibrarySection = .archiveLibrary
    @State private var selectedMediaType: MediaType = .audiobooks
    @State private var searchText = ""
    @State private var showingSearch = false
    
    var body: some View {
        GeometryReader { geometry in
            #if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .pad {
                // iPad layout
                iPadLayout
            } else {
                // iPhone layout
                iPhoneLayout
            }
            #else
            // macOS layout
            if appState.isMiniMode {
                MiniPlayerView()
                    .frame(width: 400, height: 120)
            } else {
                iPadLayout
            }
            #endif
        }
        .background(Color.white)
        .onAppear {
            // Start with Library -> Audiobooks on app launch
            selectedSection = .archiveLibrary
            selectedMediaType = .audiobooks
        }
    }
    
    // MARK: - iPad/Desktop Layout
    var iPadLayout: some View {
        HStack(spacing: 0) {
            // Left Sidebar
            LibritoSidebar(
                selectedSection: $selectedSection,
                selectedMediaType: $selectedMediaType,
                showNowPlaying: true
            )
            .frame(width: 300)
            .background(Color.white)
            
            // Main Content Area
            VStack(spacing: 0) {
                // Top section toggle (hide for Journal)
                if selectedMediaType != .journal {
                    LibritoSectionToggle(
                        selectedSection: $selectedSection
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                // Content based on section
                if selectedMediaType == .hub {
                    SocialHubView()
                } else if selectedMediaType == .journal {
                    JournalView()
                } else {
                    switch selectedSection {
                    case .myLibrary:
                        MyLibraryContentView(
                            bookManager: bookManager,
                            selectedMediaType: $selectedMediaType
                        )
                    case .archiveLibrary:
                        ArchiveLibraryContentView(
                            selectedMediaType: $selectedMediaType,
                            onNavigateToMyLibrary: {
                                // Switch to My Library tab
                                selectedSection = .myLibrary
                            }
                        )
                    }
                }
            }
            .background(Color.white)
        }
    }
    
    // MARK: - iPhone Layout
    var iPhoneLayout: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top section toggle (hide for Journal)
                if selectedMediaType != .journal {
                    LibritoSectionToggle(
                        selectedSection: $selectedSection
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                
                // Media type selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(MediaType.allCases, id: \.self) { mediaType in
                            Button(action: {
                                selectedMediaType = mediaType
                            }) {
                                Text(mediaType.displayName)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(selectedMediaType == mediaType ? .white : .black)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedMediaType == mediaType ? Color.black : Color.gray.opacity(0.1))
                                    .cornerRadius(20)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 10)
                
                // Content based on section
                if selectedMediaType == .hub {
                    SocialHubView()
                } else if selectedMediaType == .journal {
                    JournalView()
                } else {
                    switch selectedSection {
                    case .myLibrary:
                        MyLibraryContentView(
                            bookManager: bookManager,
                            selectedMediaType: $selectedMediaType
                        )
                    case .archiveLibrary:
                        ArchiveLibraryContentView(
                            selectedMediaType: $selectedMediaType,
                            onNavigateToMyLibrary: {
                                // Switch to My Library tab
                                selectedSection = .myLibrary
                            }
                        )
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Section Toggle
struct LibritoSectionToggle: View {
    @Binding var selectedSection: LibrarySection
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(LibrarySection.allCases, id: \.self) { section in
                Button(action: {
                    selectedSection = section
                }) {
                    Text(section.displayName)
                        .font(.system(size: 23, weight: .bold))
                        .foregroundColor(selectedSection == section ? .white : .black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedSection == section ? Color.black : Color.clear)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Sidebar for iPad/Desktop
struct LibritoSidebar: View {
    @Binding var selectedSection: LibrarySection
    @Binding var selectedMediaType: MediaType
    var showNowPlaying: Bool = false
    @StateObject private var globalAudioManager = GlobalAudioManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App Title - Clickable to go to Archive Library
            Button(action: {
                selectedSection = .archiveLibrary
            }) {
                HStack {
                    Text("LIBRITO")
                        .font(.system(size: 41, weight: .heavy))
                        .foregroundColor(.black)
                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .padding(.bottom, 30)
            
            // Section Toggle
            LibritoSectionToggle(selectedSection: $selectedSection)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            
            // Media Type Filters
            VStack(spacing: 12) {
                ForEach(MediaType.allCases, id: \.self) { mediaType in
                    Button(action: {
                        selectedMediaType = mediaType
                    }) {
                        Text(mediaType.displayName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(selectedMediaType == mediaType ? .white : .black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(selectedMediaType == mediaType ? Color.black : Color.clear)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Now Playing Info at bottom of sidebar
            if showNowPlaying && (globalAudioManager.isPlaying || globalAudioManager.currentPlayer != nil) {
                VStack(spacing: 12) {
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Thumbnail
                    if !globalAudioManager.currentItemIdentifier.isEmpty {
                        AsyncImage(url: URL(string: "https://archive.org/services/img/\(globalAudioManager.currentItemIdentifier)")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 200, height: 200)
                                .cornerRadius(12)
                        } placeholder: {
                            Image(systemName: "building.columns")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                                .frame(width: 200, height: 200)
                                .background(Color.black)
                                .cornerRadius(12)
                        }
                    } else {
                        Image(systemName: "building.columns")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .frame(width: 200, height: 200)
                            .background(Color.black)
                            .cornerRadius(12)
                    }
                    
                    // Title
                    Text(globalAudioManager.currentTitle)
                        .font(.system(size: 20, weight: .medium))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                    
                    Text("Classic Source")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                    
                    // Compact Transport Controls
                    CompactTransportControls()
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
            }
        }
        .background(Color.white)
    }
}

// MARK: - Compact Transport Controls for Sidebar
struct CompactTransportControls: View {
    @StateObject private var globalAudioManager = GlobalAudioManager.shared
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isDragging = false
    
    // Determine if current content is music based on queue
    private var isMusic: Bool {
        !globalAudioManager.musicQueue.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Transport buttons
            HStack(spacing: 20) {
                if isMusic {
                    // Previous track button for music
                    Button(action: {
                        previousTrack()
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 23))
                            .foregroundColor(.black)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!globalAudioManager.hasPreviousTrack)
                    .opacity(globalAudioManager.hasPreviousTrack ? 1.0 : 0.5)
                } else {
                    // Skip backward 15 seconds for audiobooks
                    Button(action: {
                        skipBackward()
                    }) {
                        Image(systemName: "gobackward.15")
                            .font(.system(size: 23))
                            .foregroundColor(.black)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Play/Pause
                Button(action: {
                    togglePlayPause()
                }) {
                    Image(systemName: globalAudioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 41))
                        .foregroundColor(.black)
                }
                .buttonStyle(PlainButtonStyle())
                
                if isMusic {
                    // Next track button for music
                    Button(action: {
                        nextTrack()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 23))
                            .foregroundColor(.black)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!globalAudioManager.hasNextTrack)
                    .opacity(globalAudioManager.hasNextTrack ? 1.0 : 0.5)
                } else {
                    // Skip forward 15 seconds for audiobooks
                    Button(action: {
                        skipForward()
                    }) {
                        Image(systemName: "goforward.15")
                            .font(.system(size: 23))
                            .foregroundColor(.black)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Progress slider
            VStack(spacing: 4) {
                Slider(
                    value: Binding(
                        get: { currentTime },
                        set: { newValue in
                            currentTime = newValue
                            if isDragging {
                                seek(to: newValue)
                            }
                        }
                    ),
                    in: 0...max(1, duration),
                    onEditingChanged: { editing in
                        isDragging = editing
                    }
                )
                .accentColor(.black)
                
                // Time display
                HStack {
                    Text(formatTime(currentTime))
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(formatTime(duration))
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            
        }
        .onAppear {
            startTimeObserver()
        }
    }
    
    private func togglePlayPause() {
        if globalAudioManager.isPlaying {
            globalAudioManager.pause()
        } else {
            globalAudioManager.play()
        }
    }
    
    private func skipForward() {
        guard let player = globalAudioManager.currentPlayer else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: 15, preferredTimescale: 600))
        player.seek(to: newTime)
    }
    
    private func skipBackward() {
        guard let player = globalAudioManager.currentPlayer else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeSubtract(currentTime, CMTime(seconds: 15, preferredTimescale: 600))
        player.seek(to: CMTime(seconds: max(0, newTime.seconds), preferredTimescale: 600))
    }
    
    private func seek(to time: Double) {
        guard let player = globalAudioManager.currentPlayer else { return }
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: cmTime)
    }
    
    private func startTimeObserver() {
        guard let player = globalAudioManager.currentPlayer else { return }
        
        // Observe player time
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            if !isDragging {
                currentTime = time.seconds
            }
            
            if let duration = player.currentItem?.duration.seconds, duration.isFinite {
                self.duration = duration
            }
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func previousTrack() {
        globalAudioManager.playPreviousTrack()
    }
    
    private func nextTrack() {
        globalAudioManager.playNextTrack()
    }
}

#Preview {
    LibritoMainView()
}