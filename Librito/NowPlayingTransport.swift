//
//  NowPlayingTransport.swift
//  Librito
//
//  Minimal transport controls for Now Playing
//

import SwiftUI
import AVFoundation

struct NowPlayingTransport: View {
    @StateObject private var globalAudioManager = GlobalAudioManager.shared
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isDragging = false
    @State private var timeObserver: Any?
    
    var body: some View {
        if globalAudioManager.isPlaying || globalAudioManager.currentPlayer != nil {
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 30) {
                    // Time display
                    Text(formatTime(currentTime))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .frame(width: 45)
                    
                    if globalAudioManager.musicQueue.isEmpty {
                        // Skip backward 15 seconds for audiobooks
                        Button(action: {
                            skipBackward()
                        }) {
                            Image(systemName: "gobackward.15")
                                .font(.system(size: 20))
                                .foregroundColor(.black)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        // Previous track for music
                        Button(action: {
                            globalAudioManager.playPreviousTrack()
                        }) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 20))
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
                            .font(.system(size: 36))
                            .foregroundColor(.black)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if globalAudioManager.musicQueue.isEmpty {
                        // Skip forward 15 seconds for audiobooks
                        Button(action: {
                            skipForward()
                        }) {
                            Image(systemName: "goforward.15")
                                .font(.system(size: 20))
                                .foregroundColor(.black)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        // Next track for music
                        Button(action: {
                            globalAudioManager.playNextTrack()
                        }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.black)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(!globalAudioManager.hasNextTrack)
                        .opacity(globalAudioManager.hasNextTrack ? 1.0 : 0.5)
                    }
                    
                    // Progress bar
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
                    .frame(maxWidth: 400)
                    
                    // Duration
                    Text(formatTime(duration))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .frame(width: 45)
                    
                    Spacer()
                    
                    // Stop button
                    Button(action: {
                        globalAudioManager.stopAllPlayback()
                    }) {
                        Image(systemName: "stop.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 20)
                }
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.05))
                .onAppear {
                    startTimeObserver()
                }
                .onDisappear {
                    removeTimeObserver()
                }
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
    
    private func seek(to time: Double) {
        guard let player = globalAudioManager.currentPlayer else { return }
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: cmTime)
    }
    
    private func startTimeObserver() {
        removeTimeObserver() // Remove any existing observer
        
        guard let player = globalAudioManager.currentPlayer else { return }
        
        // Observe player time
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            if !isDragging {
                currentTime = time.seconds
            }
            
            if let duration = player.currentItem?.duration.seconds, duration.isFinite {
                self.duration = duration
            }
        }
    }
    
    private func removeTimeObserver() {
        if let observer = timeObserver {
            globalAudioManager.currentPlayer?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    NowPlayingTransport()
}