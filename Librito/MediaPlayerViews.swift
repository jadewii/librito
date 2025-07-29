//
//  MediaPlayerViews.swift
//  Todomai-iOS
//
//  PDF reader and audiobook player views
//

import SwiftUI
import PDFKit
import AVFoundation

// Helper function to get color for media type
private func getColorForType(_ type: String) -> Color {
    switch type.lowercased() {
    case "pdf", "book", "books":
        return .blue
    case "audio", "audiobook", "audiobooks", "music":
        return .purple
    case "video":
        return .red
    default:
        return .gray
    }
}

// MARK: - PDF Reader View
struct TodomaiPDFReaderView: View {
    let item: LibraryManager.LibraryItem
    @ObservedObject var libraryManager: LibraryManager
    @Environment(\.dismiss) var dismiss
    @State private var currentPage = 1
    @State private var totalPages = 1
    @State private var showingBookmarks = false
    @State private var bookmarks: [Int] = []
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text(item.title)
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(.black)
                            .lineLimit(1)
                        
                        Text("Page \(currentPage) of \(totalPages)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button(action: {
                            toggleBookmark()
                        }) {
                            Label(bookmarks.contains(currentPage) ? "Remove Bookmark" : "Add Bookmark", 
                                  systemImage: bookmarks.contains(currentPage) ? "bookmark.fill" : "bookmark")
                        }
                        
                        Button(action: {
                            showingBookmarks = true
                        }) {
                            Label("View Bookmarks", systemImage: "list.bullet")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 30)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                .padding(.bottom, 20)
                
                // PDF View
                if let url = URL(string: item.fileURL) {
                    PDFViewWrapper(url: url, currentPage: $currentPage, totalPages: $totalPages)
                        .background(Color.gray.opacity(0.1))
                } else {
                    Text("Unable to load PDF")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Bottom controls
                HStack(spacing: 30) {
                    Button(action: {
                        if currentPage > 1 {
                            currentPage -= 1
                            updateProgress()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(currentPage > 1 ? .black : .gray)
                    }
                    .disabled(currentPage <= 1)
                    
                    // Page slider
                    Slider(value: Binding(
                        get: { Double(currentPage) },
                        set: { currentPage = Int($0) }
                    ), in: 1...Double(totalPages), step: 1)
                    .accentColor(getColorForType(item.type))
                    
                    Button(action: {
                        if currentPage < totalPages {
                            currentPage += 1
                            updateProgress()
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(currentPage < totalPages ? .black : .gray)
                    }
                    .disabled(currentPage >= totalPages)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 1),
                    alignment: .top
                )
            }
        }
        .sheet(isPresented: $showingBookmarks) {
            SimpleBookmarksView(bookmarks: $bookmarks, currentPage: $currentPage)
        }
        .onAppear {
            loadBookmarks()
        }
        .onDisappear {
            saveBookmarks()
        }
    }
    
    private func updateProgress() {
        let progress = Double(currentPage) / Double(totalPages)
        libraryManager.updateProgress(for: item.id, progress: progress)
    }
    
    private func toggleBookmark() {
        if let index = bookmarks.firstIndex(of: currentPage) {
            bookmarks.remove(at: index)
        } else {
            bookmarks.append(currentPage)
            bookmarks.sort()
        }
    }
    
    private func loadBookmarks() {
        // Load from UserDefaults or item metadata
    }
    
    private func saveBookmarks() {
        // Save to UserDefaults or item metadata
    }
}

// MARK: - PDF View Wrapper
struct PDFViewWrapper: UIViewRepresentable {
    let url: URL
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        
        if let document = PDFDocument(url: url) {
            pdfView.document = document
            DispatchQueue.main.async {
                self.totalPages = document.pageCount
            }
        }
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        if let document = pdfView.document,
           let page = document.page(at: currentPage - 1) {
            pdfView.go(to: page)
        }
    }
}

// MARK: - Audiobook Player View
struct AudiobookPlayerView: View {
    let item: LibraryManager.LibraryItem
    @ObservedObject var libraryManager: LibraryManager
    @Environment(\.dismiss) var dismiss
    @StateObject private var audioPlayer = MediaAudioPlayerManager()
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var playbackSpeed: Float = 1.0
    
    let speeds: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [getColorForType(item.type).opacity(0.3), getColorForType(item.type).opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    Text("AUDIOBOOK")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Menu {
                        Button(action: {
                            // Add bookmark
                        }) {
                            Label("Add Bookmark", systemImage: "bookmark")
                        }
                        
                        Button(action: {
                            // Show chapters
                        }) {
                            Label("Chapters", systemImage: "list.bullet")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 30)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                .padding(.bottom, 40)
                
                Spacer()
                
                // Cover art placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(getColorForType(item.type))
                        .frame(width: 250, height: 250)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.black, lineWidth: 6)
                        )
                    
                    Image(systemName: "headphones")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 40)
                
                // Title
                Text(item.title)
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineLimit(2)
                
                Spacer()
                
                // Progress bar
                VStack(spacing: 8) {
                    Slider(value: $currentTime, in: 0...duration) { editing in
                        if !editing {
                            audioPlayer.seek(to: currentTime)
                        }
                    }
                    .accentColor(getColorForType(item.type))
                    
                    HStack {
                        Text(timeString(from: currentTime))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text(timeString(from: duration))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
                
                // Playback controls
                HStack(spacing: 40) {
                    // Speed control
                    Button(action: {
                        if let currentIndex = speeds.firstIndex(of: playbackSpeed) {
                            let nextIndex = (currentIndex + 1) % speeds.count
                            playbackSpeed = speeds[nextIndex]
                            audioPlayer.setPlaybackSpeed(playbackSpeed)
                        }
                    }) {
                        Text("\(String(format: "%.1fx", playbackSpeed))")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(.black)
                            .frame(width: 50, height: 50)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    // Skip backward
                    Button(action: {
                        audioPlayer.skip(by: -30)
                    }) {
                        Image(systemName: "gobackward.30")
                            .font(.system(size: 30))
                            .foregroundColor(.black)
                    }
                    
                    // Play/Pause
                    Button(action: {
                        if isPlaying {
                            audioPlayer.pause()
                        } else {
                            audioPlayer.play()
                        }
                        isPlaying.toggle()
                    }) {
                        ZStack {
                            Circle()
                                .fill(getColorForType(item.type))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Circle()
                                        .stroke(Color.black, lineWidth: 6)
                                )
                            
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Skip forward
                    Button(action: {
                        audioPlayer.skip(by: 30)
                    }) {
                        Image(systemName: "goforward.30")
                            .font(.system(size: 30))
                            .foregroundColor(.black)
                    }
                    
                    // Sleep timer
                    Button(action: {
                        // Show sleep timer
                    }) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.black)
                            .frame(width: 50, height: 50)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            if let url = URL(string: item.fileURL) {
                audioPlayer.loadAudio(from: url)
                audioPlayer.onTimeUpdate = { time in
                    currentTime = time
                }
                audioPlayer.onDurationAvailable = { dur in
                    duration = dur
                }
                
                // Resume from saved progress
                if item.progress > 0 {
                    audioPlayer.seek(to: duration * item.progress)
                }
            }
        }
        .onDisappear {
            audioPlayer.pause()
            let progress = duration > 0 ? currentTime / duration : 0
            libraryManager.updateProgress(for: item.id, progress: progress)
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Audio Player Manager
class MediaAudioPlayerManager: NSObject, ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    var onTimeUpdate: ((TimeInterval) -> Void)?
    var onDurationAvailable: ((TimeInterval) -> Void)?
    
    func loadAudio(from url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            if let duration = audioPlayer?.duration {
                onDurationAvailable?(duration)
            }
            
            // Start timer for progress updates
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                if let currentTime = self?.audioPlayer?.currentTime {
                    self?.onTimeUpdate?(currentTime)
                }
            }
        } catch {
            print("Error loading audio: \(error)")
        }
    }
    
    func play() {
        audioPlayer?.play()
    }
    
    func pause() {
        audioPlayer?.pause()
    }
    
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
    }
    
    func skip(by seconds: TimeInterval) {
        if let player = audioPlayer {
            let newTime = player.currentTime + seconds
            player.currentTime = max(0, min(newTime, player.duration))
        }
    }
    
    func setPlaybackSpeed(_ speed: Float) {
        audioPlayer?.rate = speed
    }
    
    deinit {
        timer?.invalidate()
    }
}

extension MediaAudioPlayerManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Handle completion
    }
}

// MARK: - Bookmarks View
struct SimpleBookmarksView: View {
    @Binding var bookmarks: [Int]
    @Binding var currentPage: Int
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(bookmarks, id: \.self) { page in
                    Button(action: {
                        currentPage = page
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "bookmark.fill")
                                .foregroundColor(.orange)
                            
                            Text("Page \(page)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black)
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
                .onDelete { indices in
                    bookmarks.remove(atOffsets: indices)
                }
            }
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}