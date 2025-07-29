//
//  AudioPlayerView.swift
//  Librito
//
//  Audio player for MP3/audio files in library
//

import SwiftUI
import AVFoundation
import Combine

struct AudioPlayerView: View {
    let filePath: String
    let book: Book
    @ObservedObject var bookManager: BookManager
    @StateObject private var audioPlayerManager = AudioPlayerManager()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 30) {
                Spacer(minLength: 40)
            
                // Cover Art or Icon
                if let coverImage = book.coverImage {
                    coverImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: min(geometry.size.width * 0.6, 400), 
                               maxHeight: min(geometry.size.height * 0.4, 400))
                        .cornerRadius(20)
                        .shadow(radius: 20)
                } else {
                    Image(systemName: "music.note")
                        .font(.system(size: min(geometry.size.width * 0.3, 150)))
                        .foregroundColor(.purple)
                        .frame(width: min(geometry.size.width * 0.6, 400), 
                               height: min(geometry.size.height * 0.4, 400))
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(20)
                }
            
                // Title and Author
                VStack(spacing: 12) {
                    Text(book.title)
                        .font(.system(size: min(geometry.size.width * 0.05, 32), weight: .bold))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text(book.author)
                        .font(.system(size: min(geometry.size.width * 0.04, 24)))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 40)
            
                // Progress Bar
                VStack(spacing: 8) {
                    GeometryReader { progressGeometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 6)
                                .cornerRadius(3)
                            
                            Rectangle()
                                .fill(Color.purple)
                                .frame(width: progressGeometry.size.width * audioPlayerManager.progress, height: 6)
                                .cornerRadius(3)
                        }
                        .onTapGesture { location in
                            // Seek to tapped position
                            let progress = location.x / progressGeometry.size.width
                            audioPlayerManager.seek(to: progress)
                        }
                    }
                    .frame(height: 6)
                    
                    HStack {
                        Text(audioPlayerManager.currentTimeString)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text(audioPlayerManager.durationString)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, min(geometry.size.width * 0.15, 100))
            
                // Playback Controls
                HStack(spacing: min(geometry.size.width * 0.1, 60)) {
                    // Rewind 15 seconds
                    Button(action: {
                        audioPlayerManager.skip(by: -15)
                    }) {
                        Image(systemName: "gobackward.15")
                            .font(.system(size: min(geometry.size.width * 0.08, 40)))
                            .foregroundColor(.black)
                    }
                    
                    // Play/Pause
                    Button(action: {
                        if audioPlayerManager.isPlaying {
                            audioPlayerManager.pause()
                        } else {
                            audioPlayerManager.play()
                        }
                    }) {
                        Image(systemName: audioPlayerManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: min(geometry.size.width * 0.15, 80)))
                            .foregroundColor(.black)
                    }
                    
                    // Forward 15 seconds
                    Button(action: {
                        audioPlayerManager.skip(by: 15)
                    }) {
                        Image(systemName: "goforward.15")
                            .font(.system(size: min(geometry.size.width * 0.08, 40)))
                            .foregroundColor(.black)
                    }
                }
            
            // Playback Speed
            HStack {
                Text("Speed:")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                ForEach([0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { speed in
                    Button(action: {
                        audioPlayerManager.setPlaybackRate(Float(speed))
                    }) {
                        Text("\(speed, specifier: "%.2g")x")
                            .font(.system(size: 14, weight: audioPlayerManager.playbackRate == Float(speed) ? .bold : .regular))
                            .foregroundColor(audioPlayerManager.playbackRate == Float(speed) ? .black : .gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(audioPlayerManager.playbackRate == Float(speed) ? Color.gray.opacity(0.2) : Color.clear)
                            .cornerRadius(4)
                    }
                }
            }
            .padding(.top, 20)
            
                Spacer(minLength: 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.white)
        .onAppear {
            print("AudioPlayerView: Loading audio for book: \(book.title)")
            print("AudioPlayerView: File path: \(filePath)")
            audioPlayerManager.loadAudio(from: filePath)
            // Register with GlobalAudioManager for choke effect
            GlobalAudioManager.shared.startNewAudioManager(manager: audioPlayerManager, title: book.title)
        }
        .onDisappear {
            // Save progress
            bookManager.updateProgress(for: book, page: Int(audioPlayerManager.progress * 100))
            // Don't stop playback when navigating away - let it continue playing
            // Only stop when another audio starts (choke effect)
        }
    }
}

// MARK: - Audio Player Manager
class AudioPlayerManager: ObservableObject {
    @Published var isPlaying = false
    @Published var progress: Double = 0
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playbackRate: Float = 1.0
    
    private var player: AVPlayer?
    private var timeObserver: Any?
    
    var currentTimeString: String {
        formatTime(currentTime)
    }
    
    var durationString: String {
        formatTime(duration)
    }
    
    func loadAudio(from path: String) {
        print("AudioPlayerManager: Loading audio from path: \(path)")
        let url = URL(fileURLWithPath: path)
        
        // Check if file exists
        if !FileManager.default.fileExists(atPath: path) {
            print("AudioPlayerManager: File does not exist at path: \(path)")
            return
        }
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        print("AudioPlayerManager: Created player with URL: \(url)")
        
        // Configure audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        
        // Observe time
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, let player = self.player else { return }
            
            self.currentTime = time.seconds
            
            if let duration = player.currentItem?.duration.seconds, duration.isFinite {
                self.duration = duration
                self.progress = self.currentTime / duration
            }
        }
        
        // Observe player status
        playerItem.publisher(for: \.status)
            .sink { [weak self] status in
                switch status {
                case .readyToPlay:
                    print("AudioPlayerManager: Player ready to play")
                    if let duration = self?.player?.currentItem?.duration.seconds, duration.isFinite {
                        self?.duration = duration
                        print("AudioPlayerManager: Duration set to \(duration) seconds")
                    } else {
                        print("AudioPlayerManager: Duration not available")
                    }
                case .failed:
                    print("AudioPlayerManager: Player failed with error: \(playerItem.error?.localizedDescription ?? "Unknown")")
                case .unknown:
                    print("AudioPlayerManager: Player status unknown")
                @unknown default:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    func play() {
        player?.play()
        isPlaying = true
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func stop() {
        player?.pause()
        player?.seek(to: .zero)
        isPlaying = false
    }
    
    func skip(by seconds: Double) {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: seconds, preferredTimescale: 600))
        player.seek(to: newTime)
    }
    
    func seek(to progress: Double) {
        guard let player = player, let duration = player.currentItem?.duration else { return }
        let time = CMTimeMultiplyByFloat64(duration, multiplier: progress)
        player.seek(to: time)
    }
    
    func setPlaybackRate(_ rate: Float) {
        player?.rate = rate
        playbackRate = rate
        if rate > 0 && !isPlaying {
            isPlaying = true
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
    }
}

#Preview {
    AudioPlayerView(
        filePath: "/path/to/audio.mp3",
        book: Book(
            title: "Sample Audiobook",
            author: "Sample Author",
            fileName: "sample.mp3",
            fileType: .mp3,
            dateAdded: Date(),
            mode: "library"
        ),
        bookManager: BookManager()
    )
}