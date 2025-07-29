//
//  DecentralizedStorage.swift
//  Librito
//
//  Handles decentralized storage using IPFS and peer-to-peer sharing
//

import Foundation
import SwiftUI

// MARK: - Decentralized Storage Manager
class DecentralizedStorage: ObservableObject {
    static let shared = DecentralizedStorage()
    
    @Published var userProfile: UserProfile?
    @Published var isConnected = false
    
    // Local storage for offline access
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let profileFileName = "librito_profile.json"
    private let musicCacheDirectory = "music_cache"
    
    private init() {
        setupLocalStorage()
        loadLocalProfile()
    }
    
    // MARK: - Local Storage Setup
    private func setupLocalStorage() {
        let musicCachePath = documentsDirectory.appendingPathComponent(musicCacheDirectory)
        if !FileManager.default.fileExists(atPath: musicCachePath.path) {
            try? FileManager.default.createDirectory(at: musicCachePath, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Profile Management
    func saveProfile(_ profile: UserProfile) {
        userProfile = profile
        
        // Save locally
        if let encoded = try? JSONEncoder().encode(profile) {
            let fileURL = documentsDirectory.appendingPathComponent(profileFileName)
            try? encoded.write(to: fileURL)
        }
        
        // Generate shareable data
        _ = generateShareableProfile(profile)
    }
    
    private func loadLocalProfile() {
        let fileURL = documentsDirectory.appendingPathComponent(profileFileName)
        if let data = try? Data(contentsOf: fileURL),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            userProfile = profile
        }
    }
    
    // MARK: - Music Upload (Local + IPFS)
    func uploadMusic(fileURL: URL, metadata: MusicTrack) async throws -> MusicTrack {
        // 1. Copy to local cache
        let cacheURL = documentsDirectory
            .appendingPathComponent(musicCacheDirectory)
            .appendingPathComponent(fileURL.lastPathComponent)
        
        try FileManager.default.copyItem(at: fileURL, to: cacheURL)
        
        // 2. For IPFS upload, we'd use Web3.Storage API (free tier)
        // This is a placeholder - in production, you'd integrate with Web3.Storage
        var updatedTrack = metadata
        updatedTrack.streamURL = cacheURL.absoluteString
        updatedTrack.isUserUploaded = true
        
        // 3. Update profile with new track
        if var profile = userProfile {
            profile.uploadedTracks.append(updatedTrack)
            saveProfile(profile)
        }
        
        return updatedTrack
    }
    
    // MARK: - Peer-to-Peer Sharing
    func generateShareableProfile(_ profile: UserProfile) -> String {
        // Create a shareable link that includes:
        // 1. User metadata
        // 2. IPFS hashes for uploaded tracks
        // 3. Peer ID for direct connections
        
        let shareData = ShareableProfile(
            username: profile.username,
            displayName: profile.displayName,
            bio: profile.bio,
            uploadedTracksCount: profile.uploadedTracks.count,
            favoriteGenres: profile.favoriteGenres,
            // In production: Include IPFS CIDs for tracks
            timestamp: Date()
        )
        
        if let encoded = try? JSONEncoder().encode(shareData),
           let jsonString = String(data: encoded, encoding: .utf8) {
            // In production: Generate QR code from this data
            return jsonString
        }
        
        return ""
    }
    
    // MARK: - Import Profile from QR/Link
    func importProfile(from data: String) {
        if let jsonData = data.data(using: .utf8),
           let shareData = try? JSONDecoder().decode(ShareableProfile.self, from: jsonData) {
            // Create a new friend profile from shared data
            print("Imported profile: \(shareData.username)")
        }
    }
}

// MARK: - Shareable Profile Format
struct ShareableProfile: Codable {
    let username: String
    let displayName: String
    let bio: String
    let uploadedTracksCount: Int
    let favoriteGenres: [String]
    let timestamp: Date
    // In production: Add IPFS CIDs, peer IDs, etc.
}

// MARK: - Storage Options View
struct StorageOptionsView: View {
    @StateObject private var storage = DecentralizedStorage.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Storage Options")
                .font(.system(size: 24, weight: .bold))
            
            // Local storage info
            StorageOptionCard(
                icon: "iphone",
                title: "Local Storage",
                description: "Music stored on your device",
                status: "Active",
                statusColor: .green
            )
            
            // IPFS status
            StorageOptionCard(
                icon: "network",
                title: "IPFS Network",
                description: "Decentralized storage via Web3.Storage",
                status: "Available",
                statusColor: .blue
            )
            
            // Archive.org integration
            StorageOptionCard(
                icon: "building.columns",
                title: "Archive.org",
                description: "Public domain & creative commons",
                status: "Connected",
                statusColor: .green
            )
            
            // Peer-to-peer
            StorageOptionCard(
                icon: "person.2.fill",
                title: "Peer-to-Peer",
                description: "Direct sharing with friends",
                status: "Ready",
                statusColor: .orange
            )
        }
        .padding()
    }
}

// MARK: - Storage Option Card
struct StorageOptionCard: View {
    let icon: String
    let title: String
    let description: String
    let status: String
    let statusColor: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.gray)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                Text(status)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(statusColor)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .overlay(
            Rectangle()
                .stroke(Color.black, lineWidth: 2)
        )
    }
}

// MARK: - Music Upload View
struct MusicUploadView: View {
    @StateObject private var storage = DecentralizedStorage.shared
    @State private var showingFilePicker = false
    @State private var uploadProgress: Double = 0
    @State private var isUploading = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Drop zone
            VStack(spacing: 16) {
                Image(systemName: "music.note.house")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("Drop music files here")
                    .font(.system(size: 20, weight: .semibold))
                
                Text("or")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                
                Button(action: { showingFilePicker = true }) {
                    Text("Choose Files")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.black)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
            .background(Color.gray.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .foregroundColor(.gray)
            )
            
            // Storage info
            VStack(alignment: .leading, spacing: 12) {
                Text("Your music will be stored:")
                    .font(.system(size: 16, weight: .semibold))
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Locally on your device")
                        .font(.system(size: 14))
                }
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Optionally on IPFS (free via Web3.Storage)")
                        .font(.system(size: 14))
                }
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Shareable via QR code")
                        .font(.system(size: 14))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if isUploading {
                ProgressView(value: uploadProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .accentColor(.black)
            }
        }
        .padding()
    }
}

#Preview {
    StorageOptionsView()
}