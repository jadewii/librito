//
//  UserProfileView.swift
//  Librito
//
//  User profile page with customizable sections
//

import SwiftUI

struct UserProfileView: View {
    let user: UserProfile
    @State private var selectedTab = 0
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with close button
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                        .frame(width: 32, height: 32)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                // Share profile button
                Button(action: shareProfile) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 18))
                        .foregroundColor(.black)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Profile header
                    VStack(spacing: 16) {
                        // Avatar
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 100))
                            .foregroundColor(.gray)
                        
                        // Name and username
                        VStack(spacing: 4) {
                            Text(user.displayName)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.black)
                            
                            Text("@\(user.username)")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                        
                        // Bio
                        if !user.bio.isEmpty {
                            Text(user.bio)
                                .font(.system(size: 16))
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        
                        // Stats
                        HStack(spacing: 40) {
                            VStack {
                                Text("\(user.uploadedTracks.count)")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.black)
                                Text("Uploads")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            
                            VStack {
                                Text("247")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.black)
                                Text("Plays")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            
                            VStack {
                                Text("12")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.black)
                                Text("Friends")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    // Tab selector
                    HStack(spacing: 0) {
                        ProfileTabButton(title: "Now Playing", isSelected: selectedTab == 0) {
                            selectedTab = 0
                        }
                        ProfileTabButton(title: "Uploads", isSelected: selectedTab == 1) {
                            selectedTab = 1
                        }
                        ProfileTabButton(title: "Favorites", isSelected: selectedTab == 2) {
                            selectedTab = 2
                        }
                    }
                    .overlay(
                        Rectangle()
                            .stroke(Color.black, lineWidth: 3)
                    )
                    .padding(.horizontal, 20)
                    
                    // Tab content
                    switch selectedTab {
                    case 0:
                        NowPlayingSection(user: user)
                    case 1:
                        UploadsSection(user: user)
                    case 2:
                        FavoritesSection(user: user)
                    default:
                        EmptyView()
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
    
    private func shareProfile() {
        // Generate QR code with user profile data
        // This will contain IPFS hash or peer ID
        print("Sharing profile via QR code")
    }
}

// MARK: - Tab Button
struct ProfileTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isSelected ? .white : .black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.black : Color.white)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Now Playing Section
struct NowPlayingSection: View {
    let user: UserProfile
    
    var body: some View {
        VStack(spacing: 20) {
            if let track = user.currentTrack {
                // Currently playing card
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                        Text("LIVE NOW")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.green)
                        Spacer()
                    }
                    
                    HStack {
                        // Album art
                        if track.artworkURL != nil {
                            AsyncImage(url: URL(string: track.artworkURL!)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 80, height: 80)
                            }
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 80, height: 80)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(track.title)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                            Text(track.artist)
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(20)
                .background(Color.gray.opacity(0.05))
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 3)
                )
                .padding(.horizontal, 20)
            }
            
            // Featured track
            if let featured = user.featuredTrack {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Featured Track")
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.horizontal, 20)
                    
                    TrackRow(track: featured)
                        .padding(.horizontal, 20)
                }
            }
        }
    }
}

// MARK: - Uploads Section
struct UploadsSection: View {
    let user: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if user.uploadedTracks.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "music.note.house")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No uploads yet")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                    
                    if user.username == "jadewii" { // Check if current user
                        Button(action: {}) {
                            Text("Upload Your First Track")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.black)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                ForEach(user.uploadedTracks) { track in
                    TrackRow(track: track)
                        .padding(.horizontal, 20)
                }
            }
        }
    }
}

// MARK: - Favorites Section
struct FavoritesSection: View {
    let user: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Favorite genres
            VStack(alignment: .leading, spacing: 12) {
                Text("Favorite Genres")
                    .font(.system(size: 18, weight: .semibold))
                    .padding(.horizontal, 20)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(user.favoriteGenres, id: \.self) { genre in
                            Text(genre)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.gray.opacity(0.1))
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.black, lineWidth: 2)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            // Placeholder for favorite tracks
            VStack(spacing: 12) {
                Text("Favorite Tracks")
                    .font(.system(size: 18, weight: .semibold))
                    .padding(.horizontal, 20)
                
                Text("Coming soon...")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .padding(.vertical, 40)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Track Row
struct TrackRow: View {
    let track: MusicTrack
    
    var body: some View {
        HStack {
            // Album art
            if track.artworkURL != nil {
                AsyncImage(url: URL(string: track.artworkURL!)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                Text(track.artist)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "play.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .frame(width: 36, height: 36)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(12)
        .background(Color.white)
        .overlay(
            Rectangle()
                .stroke(Color.black, lineWidth: 2)
        )
    }
}

#Preview {
    UserProfileView(user: UserProfile.mockUsers.first!)
}