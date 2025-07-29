//
//  GlobalAudioManager.swift
//  Librito
//
//  Manages global audio playback state to ensure only one audio stream plays at a time
//

import SwiftUI
import AVFoundation
import Combine

class GlobalAudioManager: ObservableObject {
    static let shared = GlobalAudioManager()
    
    @Published var currentPlayer: AVPlayer?
    @Published var currentAudioManager: AudioPlayerManager?
    @Published var isPlaying = false
    @Published var currentTitle = ""
    @Published var currentItemIdentifier: String = ""
    
    // Music queue management
    @Published var musicQueue: [ArchiveOrgService.ArchiveItem] = []
    @Published var currentTrackIndex: Int = 0
    @Published var hasPreviousTrack: Bool = false
    @Published var hasNextTrack: Bool = false
    
    private init() {
        // Set up audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func startNewStream(player: AVPlayer, title: String, identifier: String = "") {
        // Stop any existing playback
        stopAllPlayback()
        
        // Set the new player
        currentPlayer = player
        currentTitle = title
        currentItemIdentifier = identifier
        isPlaying = true
        
        print("GlobalAudioManager: Starting stream for \(title)")
    }
    
    func startNewAudioManager(manager: AudioPlayerManager, title: String) {
        // Stop any existing playback
        stopAllPlayback()
        
        // Set the new audio manager
        currentAudioManager = manager
        currentTitle = title
        isPlaying = true
        
        print("GlobalAudioManager: Starting audio manager for \(title)")
    }
    
    func stopAllPlayback() {
        print("GlobalAudioManager: Stopping all playback")
        
        // Remove any player observers
        if let player = currentPlayer, let currentItem = player.currentItem {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: currentItem)
        }
        
        // Stop AVPlayer if exists
        currentPlayer?.pause()
        currentPlayer = nil
        
        // Stop AudioPlayerManager if exists
        currentAudioManager?.pause()
        currentAudioManager = nil
        
        // Clear music queue
        musicQueue = []
        currentTrackIndex = 0
        hasPreviousTrack = false
        hasNextTrack = false
        
        isPlaying = false
        currentTitle = ""
        currentItemIdentifier = ""
    }
    
    func pause() {
        currentPlayer?.pause()
        currentAudioManager?.pause()
        isPlaying = false
    }
    
    func play() {
        currentPlayer?.play()
        currentAudioManager?.play()
        isPlaying = true
    }
    
    // MARK: - Music Queue Management
    func setMusicQueue(_ items: [ArchiveOrgService.ArchiveItem], startingAt index: Int = 0) {
        musicQueue = items
        currentTrackIndex = index
        updateQueueStatus()
    }
    
    func addToQueue(_ item: ArchiveOrgService.ArchiveItem) {
        musicQueue.append(item)
        updateQueueStatus()
    }
    
    func playPreviousTrack() {
        guard hasPreviousTrack else { return }
        currentTrackIndex -= 1
        updateQueueStatus()
        playCurrentTrack()
    }
    
    func playNextTrack() {
        guard hasNextTrack else { return }
        currentTrackIndex += 1
        updateQueueStatus()
        playCurrentTrack()
    }
    
    private func updateQueueStatus() {
        hasPreviousTrack = currentTrackIndex > 0
        hasNextTrack = currentTrackIndex < musicQueue.count - 1
    }
    
    func playCurrentTrack() {
        guard currentTrackIndex >= 0 && currentTrackIndex < musicQueue.count else { 
            print("GlobalAudioManager: Invalid track index \(currentTrackIndex)")
            return 
        }
        
        let currentTrack = musicQueue[currentTrackIndex]
        print("GlobalAudioManager: Playing track \(currentTrackIndex + 1) of \(musicQueue.count): \(currentTrack.title)")
        
        // Start streaming the current track
        ArchiveOrgService.shared.getStreamingURL(for: currentTrack) { [weak self] url in
            guard let streamURL = url else { 
                print("GlobalAudioManager: Failed to get streaming URL for \(currentTrack.title)")
                return 
            }
            
            print("GlobalAudioManager: Got streaming URL: \(streamURL)")
            
            DispatchQueue.main.async {
                let playerItem = AVPlayerItem(url: streamURL)
                let player = AVPlayer(playerItem: playerItem)
                
                // Add observer for when the track finishes
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: playerItem,
                    queue: .main
                ) { _ in
                    print("GlobalAudioManager: Track finished playing, moving to next")
                    self?.playNextTrack()
                }
                
                self?.startNewStream(player: player, title: currentTrack.title, identifier: currentTrack.identifier)
                player.play()
                print("GlobalAudioManager: Started playback")
            }
        }
    }
    
    func startTrackInContext(item: ArchiveOrgService.ArchiveItem, from allItems: [ArchiveOrgService.ArchiveItem]) {
        // Set up the queue with all music items and start playing the selected one
        let musicItems = allItems.filter { $0.mediatype.lowercased() == "audio" }
        
        print("GlobalAudioManager: Setting up music queue with \(musicItems.count) items from \(allItems.count) total items")
        
        if let index = musicItems.firstIndex(where: { $0.id == item.id }) {
            setMusicQueue(musicItems, startingAt: index)
            print("GlobalAudioManager: Starting playback at index \(index)")
            playCurrentTrack() // Actually play the selected track
        } else {
            print("GlobalAudioManager: Could not find item in music items")
        }
    }
}