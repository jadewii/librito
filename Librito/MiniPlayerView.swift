//
//  MiniPlayerView.swift
//  Librito
//
//  Compact now playing widget for mini mode
//

import SwiftUI
import AVFoundation

struct MiniPlayerView: View {
    @StateObject private var globalAudioManager = GlobalAudioManager.shared
    @StateObject private var appState = AppStateManager.shared
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isDragging = false
    @State private var isHovering = false
    @State private var showingQueue = false
    @State private var volume: Float = AVAudioSession.sharedInstance().outputVolume
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar with restore button
            HStack {
                // Drag area
                Color.clear
                    .frame(height: 20)
                    .onHover { hovering in
                        #if os(macOS)
                        if hovering {
                            NSCursor.openHand.push()
                        } else {
                            NSCursor.pop()
                        }
                        #endif
                    }
                
                Spacer()
                
                // Always on top toggle
                Button(action: {
                    appState.setAlwaysOnTop(!appState.isAlwaysOnTop)
                }) {
                    Image(systemName: appState.isAlwaysOnTop ? "pin.fill" : "pin")
                        .font(.system(size: 12))
                        .foregroundColor(appState.isAlwaysOnTop ? .black : .gray)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Keep on top")
                
                // Restore button
                Button(action: {
                    appState.toggleMiniMode()
                }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Restore to full view")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.05))
            
            // Main content
            HStack(spacing: 16) {
                // Small thumbnail
                if !globalAudioManager.currentItemIdentifier.isEmpty {
                    AsyncImage(url: URL(string: "https://archive.org/services/img/\(globalAudioManager.currentItemIdentifier)")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .cornerRadius(6)
                    } placeholder: {
                        Image(systemName: "building.columns")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.black)
                            .cornerRadius(6)
                    }
                } else {
                    Image(systemName: "building.columns")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.black)
                        .cornerRadius(6)
                }
                
                // Title and controls
                VStack(spacing: 8) {
                    // Title
                    Text(globalAudioManager.currentTitle)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Compact controls
                    HStack(spacing: 12) {
                        if globalAudioManager.musicQueue.isEmpty {
                            // Skip backward 15 seconds for audiobooks
                            Button(action: { skipBackward() }) {
                                Image(systemName: "gobackward.15")
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            // Previous track for music
                            Button(action: { globalAudioManager.playPreviousTrack() }) {
                                Image(systemName: "backward.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(!globalAudioManager.hasPreviousTrack)
                            .opacity(globalAudioManager.hasPreviousTrack ? 1.0 : 0.5)
                        }
                        
                        // Play/Pause
                        Button(action: { togglePlayPause() }) {
                            Image(systemName: globalAudioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.black)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if globalAudioManager.musicQueue.isEmpty {
                            // Skip forward 15 seconds for audiobooks
                            Button(action: { skipForward() }) {
                                Image(systemName: "goforward.15")
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            // Next track for music
                            Button(action: { globalAudioManager.playNextTrack() }) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(!globalAudioManager.hasNextTrack)
                            .opacity(globalAudioManager.hasNextTrack ? 1.0 : 0.5)
                        }
                        
                        Spacer()
                        
                        // Volume control
                        HStack(spacing: 4) {
                            Image(systemName: "speaker.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                            
                            Slider(value: $volume, in: 0...1) { _ in
                                // Set system volume if possible
                                #if os(macOS)
                                // macOS volume control would go here
                                #endif
                            }
                            .frame(width: 60)
                            .accentColor(.gray)
                        }
                        
                        // Queue button (for music)
                        if !globalAudioManager.musicQueue.isEmpty {
                            Button(action: {
                                showingQueue.toggle()
                            }) {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .popover(isPresented: $showingQueue) {
                                QueuePopover()
                                    .frame(width: 300, height: 400)
                            }
                        }
                        
                        // Time display
                        Text("\(formatTime(currentTime)) / \(formatTime(duration))")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 10)
        .onAppear {
            startTimeObserver()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
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
}

// MARK: - Queue Popover
struct QueuePopover: View {
    @StateObject private var globalAudioManager = GlobalAudioManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Queue")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                Text("\(globalAudioManager.musicQueue.count) tracks")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding()
            
            Divider()
            
            // Queue list
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(globalAudioManager.musicQueue.enumerated()), id: \.element.id) { index, item in
                        HStack {
                            // Track number
                            Text("\(index + 1)")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .frame(width: 30)
                            
                            // Track info
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.system(size: 14, weight: index == globalAudioManager.currentTrackIndex ? .semibold : .regular))
                                    .lineLimit(1)
                                
                                Text(item.creator ?? "Unknown Artist")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            // Now playing indicator
                            if index == globalAudioManager.currentTrackIndex {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(index == globalAudioManager.currentTrackIndex ? Color.blue.opacity(0.1) : Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // Jump to track
                            globalAudioManager.currentTrackIndex = index
                            globalAudioManager.playCurrentTrack()
                        }
                    }
                }
            }
        }
        .background(Color.white)
    }
}

#Preview {
    MiniPlayerView()
        .frame(width: 400, height: 120)
}