//
//  NowPlayingBar.swift
//  Librito
//
//  Now Playing bar for streaming audio with controls
//

import SwiftUI
import AVFoundation

struct NowPlayingBar: View {
    @StateObject private var globalAudioManager = GlobalAudioManager.shared
    let currentItemIdentifier: String?
    
    var body: some View {
        if globalAudioManager.isPlaying || globalAudioManager.currentPlayer != nil {
            VStack(spacing: 0) {
                Divider()
                
                NowPlayingView(itemIdentifier: currentItemIdentifier)
            }
        }
    }
}

struct NowPlayingView: View {
    @StateObject private var globalAudioManager = GlobalAudioManager.shared
    let itemIdentifier: String?
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 20) {
                // Left section - Large thumbnail
                HStack {
                    Spacer()
                    
                    if let identifier = itemIdentifier {
                        AsyncImage(url: URL(string: "https://archive.org/services/img/\(identifier)")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 200, height: 200)
                                .cornerRadius(12)
                                .shadow(radius: 5)
                        } placeholder: {
                            Image(systemName: "building.columns")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                                .frame(width: 200, height: 200)
                                .background(Color.black)
                                .cornerRadius(12)
                                .shadow(radius: 5)
                        }
                    } else {
                        Image(systemName: "building.columns")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                            .frame(width: 200, height: 200)
                            .background(Color.black)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    }
                    
                    Spacer()
                }
                .frame(width: geometry.size.width * 0.3)
                
                // Right section - Controls and info
                VStack(spacing: 20) {
                    // Title and source
                    VStack(spacing: 8) {
                        Text(globalAudioManager.currentTitle)
                            .font(.system(size: 24, weight: .semibold))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.black)
                        
                        Text("Classic Source")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    
                    // Progress bar with time
                    VStack(spacing: 8) {
                        HStack {
                            Text(formatTime(currentTime))
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .frame(width: 50, alignment: .leading)
                            
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
                            
                            Text(formatTime(duration))
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .frame(width: 50, alignment: .trailing)
                        }
                    }
                    
                    // Playback controls
                    HStack(spacing: 40) {
                        if globalAudioManager.musicQueue.isEmpty {
                            // Skip backward 15 seconds for audiobooks
                            Button(action: {
                                skipBackward()
                            }) {
                                Image(systemName: "gobackward.15")
                                    .font(.system(size: 24))
                                    .foregroundColor(.black)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            // Previous track for music
                            Button(action: {
                                globalAudioManager.playPreviousTrack()
                            }) {
                                Image(systemName: "backward.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.black)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(!globalAudioManager.hasPreviousTrack)
                            .opacity(globalAudioManager.hasPreviousTrack ? 1.0 : 0.5)
                        }
                        
                        // Play/Pause
                        Button(action: {
                            togglePlayPause()
                        }) {
                            Image(systemName: globalAudioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.black)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if globalAudioManager.musicQueue.isEmpty {
                            // Skip forward 15 seconds for audiobooks
                            Button(action: {
                                skipForward()
                            }) {
                                Image(systemName: "goforward.15")
                                    .font(.system(size: 24))
                                    .foregroundColor(.black)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            // Next track for music
                            Button(action: {
                                globalAudioManager.playNextTrack()
                            }) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.black)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(!globalAudioManager.hasNextTrack)
                            .opacity(globalAudioManager.hasNextTrack ? 1.0 : 0.5)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 40)
                
                // Close button in top right
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            globalAudioManager.stopAllPlayback()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    Spacer()
                }
                .padding(20)
            }
        }
        .frame(height: 250)
        .background(Color.gray.opacity(0.05))
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
}

#Preview {
    NowPlayingBar(currentItemIdentifier: nil)
}