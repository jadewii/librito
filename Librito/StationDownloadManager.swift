//
//  StationDownloadManager.swift
//  Librito
//
//  Manages music station downloads and streaming
//

import Foundation
import SwiftUI

// MARK: - Music Station Model
struct MusicStation: Identifiable, Codable {
    var id = UUID()
    var name: String
    var description: String
    var genre: String
    var streamURL: String
    var imageURL: String?
    var isPreset: Bool = true
    var bitrate: Int = 128
    var format: String = "mp3"
    
    // Computed properties
    var isAvailable: Bool {
        return true // All stations are available for now
    }
    
    var color: Color {
        switch genre {
        case "lofi": return .purple
        case "piano": return .blue
        case "hiphop": return .orange
        case "jungle": return .green
        default: return .gray
        }
    }
    
    var songCount: Int {
        return Int.random(in: 50...200) // Random song count for demo
    }
    
    var totalSizeMB: Double {
        return Double.random(in: 100...500) // Random size for demo
    }
}

// MARK: - Download State
enum StationDownloadState: Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded
    case failed(error: String)
}

// MARK: - Station Download Manager
class StationDownloadManager: ObservableObject {
    static let shared = StationDownloadManager()
    
    @Published var stations: [MusicStation] = []
    @Published var downloadStates: [UUID: StationDownloadState] = [:]
    @Published var currentlyPlaying: MusicStation?
    
    // Preset stations
    let lofiStation = MusicStation(
        name: "Lofi Hip Hop",
        description: "Relaxing beats to study/work to",
        genre: "lofi",
        streamURL: "https://example.com/lofi-stream",
        imageURL: "lofi-cover"
    )
    
    private init() {
        setupPresetStations()
    }
    
    private func setupPresetStations() {
        stations = [
            lofiStation,
            MusicStation(
                name: "Classical Piano",
                description: "Beautiful classical piano compositions",
                genre: "piano",
                streamURL: "https://example.com/piano-stream",
                imageURL: "piano-cover"
            ),
            MusicStation(
                name: "Hip Hop Classics",
                description: "Old school and modern hip hop",
                genre: "hiphop",
                streamURL: "https://example.com/hiphop-stream",
                imageURL: "hiphop-cover"
            ),
            MusicStation(
                name: "Jungle & Drum'n'Bass",
                description: "High energy jungle and DnB",
                genre: "jungle",
                streamURL: "https://example.com/jungle-stream",
                imageURL: "jungle-cover"
            )
        ]
        
        // Initialize all as not downloaded
        for station in stations {
            downloadStates[station.id] = .notDownloaded
        }
    }
    
    // MARK: - Station Management
    func getStation(by genre: String) -> MusicStation? {
        stations.first { $0.genre.lowercased() == genre.lowercased() }
    }
    
    func downloadState(for station: MusicStation) -> StationDownloadState {
        downloadStates[station.id] ?? .notDownloaded
    }
    
    // MARK: - Download Management
    func downloadStation(_ station: MusicStation) {
        downloadStates[station.id] = .downloading(progress: 0)
        
        // Simulate download progress
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            guard case .downloading(let progress) = self.downloadStates[station.id] else {
                timer.invalidate()
                return
            }
            
            let newProgress = min(progress + 0.1, 1.0)
            self.downloadStates[station.id] = .downloading(progress: newProgress)
            
            if newProgress >= 1.0 {
                timer.invalidate()
                self.downloadStates[station.id] = .downloaded
            }
        }
    }
    
    func cancelDownload(_ station: MusicStation) {
        downloadStates[station.id] = .notDownloaded
    }
    
    func deleteDownload(_ station: MusicStation) {
        downloadStates[station.id] = .notDownloaded
        // In a real app, delete the downloaded files here
    }
    
    // MARK: - Playback
    func play(_ station: MusicStation) {
        currentlyPlaying = station
        // In a real app, start audio playback here
    }
    
    func stop() {
        currentlyPlaying = nil
        // In a real app, stop audio playback here
    }
}

// MARK: - Playlist Manager (for RadioView compatibility)
class PlaylistManager: ObservableObject {
    static let shared = PlaylistManager()
    
    @Published var playlists: [Playlist] = []
    
    private init() {
        loadPlaylists()
    }
    
    func createPlaylist(name: String, audioFiles: Set<String>) {
        let playlist = Playlist(
            name: name,
            audioFiles: Array(audioFiles),
            dateCreated: Date()
        )
        playlists.append(playlist)
        savePlaylists()
    }
    
    func deletePlaylist(_ playlist: Playlist) {
        playlists.removeAll { $0.id == playlist.id }
        savePlaylists()
    }
    
    private func savePlaylists() {
        // Save to UserDefaults or file system
    }
    
    private func loadPlaylists() {
        // Load from UserDefaults or file system
        playlists = [] // Start with empty for now
    }
}

// MARK: - Playlist Model
struct Playlist: Identifiable, Codable {
    var id = UUID()
    var name: String
    var audioFiles: [String]
    var dateCreated: Date
    var coverImage: String?
    
    var songCount: Int {
        return audioFiles.count
    }
}