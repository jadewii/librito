//
//  PlaylistSelectionView.swift
//  Librito
//
//  Modal for selecting playlists when adding music
//

import SwiftUI

struct PlaylistSelectionView: View {
    let item: ArchiveOrgService.ArchiveItem
    @Environment(\.dismiss) var dismiss
    @StateObject private var playlistService = PlaylistService.shared
    @State private var showingCreatePlaylist = false
    @State private var newPlaylistName = ""
    @State private var selectedPlaylistId: UUID?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add to Playlist")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("Choose a playlist for \"\(item.title)\"")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Create New Playlist Button
                Button(action: {
                    showingCreatePlaylist = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Create New Playlist")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.black)
                            Text("Start a new collection")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(Color.gray.opacity(0.05))
                }
                .buttonStyle(PlainButtonStyle())
                
                // Existing Playlists
                if playlistService.getMusicPlaylists().isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        
                        Image(systemName: "music.note.list")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No Playlists Yet")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Text("Create your first playlist to get started")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 40)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(playlistService.getMusicPlaylists()) { playlist in
                                PlaylistRowView(
                                    playlist: playlist,
                                    isSelected: selectedPlaylistId == playlist.id,
                                    onTap: {
                                        selectedPlaylistId = playlist.id
                                        addToPlaylistAndDismiss(playlist.id)
                                    }
                                )
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                
                Spacer()
            }
            .navigationBarItems(
                trailing: Button("Cancel") {
                    dismiss()
                }
            )
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingCreatePlaylist) {
            CreatePlaylistView(
                item: item,
                onPlaylistCreated: { playlistId in
                    selectedPlaylistId = playlistId
                    addToPlaylistAndDismiss(playlistId)
                }
            )
        }
    }
    
    private func addToPlaylistAndDismiss(_ playlistId: UUID) {
        playlistService.addToPlaylist(playlistId, item: item)
        dismiss()
    }
}

struct PlaylistRowView: View {
    let playlist: ArchivePlaylist
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Playlist Icon
                Image(systemName: "music.note.list")
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(playlist.name)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                        .lineLimit(1)
                    
                    HStack {
                        Text("\(playlist.itemCount) songs")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        if playlist.itemCount > 0 {
                            Text("•")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            Text(formatDuration(playlist.duration))
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let hours = minutes / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes % 60)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct CreatePlaylistView: View {
    let item: ArchiveOrgService.ArchiveItem
    let onPlaylistCreated: (UUID) -> Void
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var playlistService = PlaylistService.shared
    @State private var playlistName = ""
    @State private var playlistDescription = ""
    @State private var isCreating = false
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("New Playlist")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("Create a playlist for your music")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Playlist Name")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                        
                        TextField("Enter playlist name...", text: $playlistName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: 16))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (Optional)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                        
                        TextField("Add a description...", text: $playlistDescription, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: 16))
                            .lineLimit(3...6)
                    }
                }
                
                Spacer()
                
                // Create Button
                Button(action: createPlaylist) {
                    HStack {
                        if isCreating {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        }
                        
                        Text(isCreating ? "Creating..." : "Create Playlist")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(playlistName.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(12)
                }
                .disabled(playlistName.isEmpty || isCreating)
                .buttonStyle(PlainButtonStyle())
            }
            .padding(24)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
            )
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            // Pre-fill with song title if no name entered
            if playlistName.isEmpty {
                playlistName = "My \(item.title) Playlist"
            }
        }
    }
    
    private func createPlaylist() {
        isCreating = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let playlist = playlistService.createPlaylist(
                name: playlistName,
                description: playlistDescription.isEmpty ? nil : playlistDescription
            )
            
            onPlaylistCreated(playlist.id)
            dismiss()
        }
    }
}

#Preview {
    PlaylistSelectionView(
        item: ArchiveOrgService.ArchiveItem(
            id: "test",
            title: "Test Song",
            creator: "Test Artist",
            date: "2023",
            description: "A test song",
            mediatype: "audio",
            identifier: "test"
        )
    )
}