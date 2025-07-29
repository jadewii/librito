//
//  RadioView.swift
//  Librito
//
//  Fixed and simplified radio view
//

import SwiftUI
import UniformTypeIdentifiers

struct RadioView: View {
    @StateObject private var downloadManager = StationDownloadManager.shared
    @StateObject private var playlistManager = PlaylistManager.shared
    @State private var selectedStation: MusicStation? = nil
    @State private var showingStationDetail = false
    @State private var showingMusicPlayer = false
    @State private var showingFilePicker = false
    @State private var showingNamePrompt = false
    @State private var selectedAudioFiles: [URL] = []
    @State private var newPlaylistName = ""
    @State private var showingCustomFileBrowser = false
    
    let stations = StationDownloadManager.shared.stations
    
    var backgroundColor: Color {
        Color(red: 0.4, green: 0.9, blue: 0.6) // Radio green
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            contentView
        }
        .background(backgroundColor.ignoresSafeArea())
        .sheet(isPresented: $showingStationDetail) {
            if let station = selectedStation {
                SimpleStationDetailView(
                    station: station,
                    downloadManager: downloadManager,
                    onClose: {
                        showingStationDetail = false
                        selectedStation = nil
                    }
                )
            }
        }
        .alert("Name Your Playlist", isPresented: $showingNamePrompt) {
            TextField("Playlist name", text: $newPlaylistName)
            Button("Cancel", role: .cancel) {
                selectedAudioFiles = []
                newPlaylistName = ""
            }
            Button("Create") {
                if !newPlaylistName.isEmpty {
                    playlistManager.createPlaylist(name: newPlaylistName, audioFiles: Set(selectedAudioFiles.map { $0.path }))
                    selectedAudioFiles = []
                    newPlaylistName = ""
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("📻 RADIO")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            Text("Stream and download music stations")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 20)
        }
    }
    
    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                stationsSection
                playlistsSection
            }
            .padding()
        }
    }
    
    private var stationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Music Stations")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(stations) { station in
                    StationCard(
                        station: station,
                        downloadState: downloadManager.downloadStates[station.id] ?? .notDownloaded,
                        action: {
                            selectedStation = station
                            showingStationDetail = true
                        }
                    )
                }
            }
        }
    }
    
    private var playlistsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Playlists")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("+ Add") {
                    showingFilePicker = true
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.2))
                .cornerRadius(20)
            }
            
            if playlistManager.playlists.isEmpty {
                Text("No playlists yet. Create one by adding audio files!")
                    .foregroundColor(.white.opacity(0.7))
                    .padding()
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(playlistManager.playlists) { playlist in
                        PlaylistCard(playlist: playlist) {
                            // Handle playlist tap
                        }
                        .contextMenu {
                            Button("Delete Playlist", role: .destructive) {
                                playlistManager.deletePlaylist(playlist)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Station Card
struct StationCard: View {
    let station: MusicStation
    let downloadState: StationDownloadState
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: "music.note")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
                    .background(station.color.opacity(0.3))
                    .cornerRadius(16)
                
                VStack(spacing: 4) {
                    Text(station.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(station.description)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                }
                
                statusIndicator
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
        }
    }
    
    private var statusIndicator: some View {
        Group {
            switch downloadState {
            case .notDownloaded:
                Text("Tap to Download")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            case .downloading(let progress):
                VStack {
                    Text("Downloading...")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .scaleEffect(x: 1, y: 0.5)
                }
            case .downloaded:
                Text("Downloaded ✓")
                    .font(.caption)
                    .foregroundColor(.green)
            case .failed:
                Text("Failed - Tap to Retry")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Playlist Card
struct PlaylistCard: View {
    let playlist: Playlist
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
                    .background(Color.purple.opacity(0.3))
                    .cornerRadius(16)
                
                VStack(spacing: 4) {
                    Text(playlist.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text("\(playlist.songCount) songs")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
        }
    }
}

#Preview {
    RadioView()
}