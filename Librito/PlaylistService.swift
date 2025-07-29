//
//  PlaylistService.swift
//  Librito
//
//  Service for managing user playlists
//

import Foundation
import SwiftUI

// MARK: - Archive Playlist Models (distinct from local Playlist)
struct ArchivePlaylist: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var description: String?
    var items: [PlaylistItem] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    var duration: TimeInterval {
        items.reduce(0) { $0 + $1.duration }
    }
    
    var itemCount: Int {
        items.count
    }
}

struct PlaylistItem: Identifiable, Codable {
    var id: UUID = UUID()
    let archiveId: String
    let title: String
    let creator: String?
    let duration: TimeInterval
    let mediaType: String
    var addedAt: Date = Date()
}

// MARK: - Library Item for My Library
struct LibraryItem: Identifiable, Codable {
    var id: UUID = UUID()
    let archiveId: String
    let title: String
    let creator: String?
    let mediaType: String
    let description: String?
    var addedAt: Date = Date()
    var lastAccessed: Date?
    var isFavorite: Bool = false
}

// MARK: - Playlist Service
class PlaylistService: ObservableObject {
    static let shared = PlaylistService()
    
    @Published var playlists: [ArchivePlaylist] = []
    @Published var libraryItems: [LibraryItem] = []
    
    private let playlistsKey = "librito_playlists"
    private let libraryKey = "librito_library"
    
    init() {
        loadPlaylists()
        loadLibrary()
    }
    
    // MARK: - Playlist Management
    func createPlaylist(name: String, description: String? = nil) -> ArchivePlaylist {
        let playlist = ArchivePlaylist(name: name, description: description)
        playlists.append(playlist)
        savePlaylists()
        return playlist
    }
    
    func deletePlaylist(_ playlist: ArchivePlaylist) {
        playlists.removeAll { $0.id == playlist.id }
        savePlaylists()
    }
    
    func addToPlaylist(_ playlistId: UUID, item: ArchiveOrgService.ArchiveItem) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistId }) else { return }
        
        let playlistItem = PlaylistItem(
            archiveId: item.id,
            title: item.title,
            creator: item.creator,
            duration: 0, // TODO: Get actual duration from metadata
            mediaType: item.mediatype
        )
        
        // Check if item already exists
        if !playlists[index].items.contains(where: { $0.archiveId == item.id }) {
            playlists[index].items.append(playlistItem)
            playlists[index].updatedAt = Date()
            savePlaylists()
        }
    }
    
    func removeFromPlaylist(_ playlistId: UUID, itemId: UUID) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistId }) else { return }
        playlists[index].items.removeAll { $0.id == itemId }
        playlists[index].updatedAt = Date()
        savePlaylists()
    }
    
    // MARK: - Library Management
    func addToLibrary(_ item: ArchiveOrgService.ArchiveItem) {
        // Check if item already exists
        if !libraryItems.contains(where: { $0.archiveId == item.id }) {
            let libraryItem = LibraryItem(
                archiveId: item.id,
                title: item.title,
                creator: item.creator,
                mediaType: item.mediatype,
                description: item.description
            )
            libraryItems.append(libraryItem)
            saveLibrary()
        }
    }
    
    func removeFromLibrary(_ itemId: UUID) {
        libraryItems.removeAll { $0.id == itemId }
        saveLibrary()
    }
    
    func toggleFavorite(_ itemId: UUID) {
        if let index = libraryItems.firstIndex(where: { $0.id == itemId }) {
            libraryItems[index].isFavorite.toggle()
            saveLibrary()
        }
    }
    
    func updateLastAccessed(_ itemId: UUID) {
        if let index = libraryItems.firstIndex(where: { $0.id == itemId }) {
            libraryItems[index].lastAccessed = Date()
            saveLibrary()
        }
    }
    
    func isInLibrary(_ archiveId: String) -> Bool {
        return libraryItems.contains { $0.archiveId == archiveId }
    }
    
    // MARK: - Filtering and Sorting
    func getRecentLibraryItems(limit: Int = 10) -> [LibraryItem] {
        return libraryItems
            .sorted { $0.addedAt > $1.addedAt }
            .prefix(limit)
            .map { $0 }
    }
    
    func getFavoriteLibraryItems() -> [LibraryItem] {
        return libraryItems.filter { $0.isFavorite }
    }
    
    func getLibraryItems(for mediaType: String) -> [LibraryItem] {
        return libraryItems.filter { $0.mediaType.lowercased() == mediaType.lowercased() }
    }
    
    func getMusicPlaylists() -> [ArchivePlaylist] {
        return playlists.filter { playlist in
            playlist.items.allSatisfy { $0.mediaType.lowercased() == "audio" }
        }
    }
    
    // MARK: - Persistence
    private func savePlaylists() {
        if let encoded = try? JSONEncoder().encode(playlists) {
            UserDefaults.standard.set(encoded, forKey: playlistsKey)
        }
    }
    
    private func loadPlaylists() {
        if let data = UserDefaults.standard.data(forKey: playlistsKey),
           let decoded = try? JSONDecoder().decode([ArchivePlaylist].self, from: data) {
            playlists = decoded
        }
    }
    
    private func saveLibrary() {
        if let encoded = try? JSONEncoder().encode(libraryItems) {
            UserDefaults.standard.set(encoded, forKey: libraryKey)
        }
    }
    
    private func loadLibrary() {
        if let data = UserDefaults.standard.data(forKey: libraryKey),
           let decoded = try? JSONDecoder().decode([LibraryItem].self, from: data) {
            libraryItems = decoded
        }
    }
}