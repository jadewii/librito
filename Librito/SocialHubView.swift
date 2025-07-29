//
//  SocialHubView.swift
//  Librito
//
//  Social hub showing users and what they're listening to
//

import SwiftUI

struct SocialHubView: View {
    @StateObject private var premiumManager: PremiumManager = PremiumManager.shared
    @StateObject private var decentralizedStorage: DecentralizedStorage = DecentralizedStorage.shared
    @StateObject private var uploadManager: ArchiveUploadManager = ArchiveUploadManager.shared
    @State private var featuredUsers: [UserProfile] = UserProfile.mockUsers
    @State private var selectedUser: UserProfile?
    @State private var showingPremiumUpgrade = false
    @State private var isBroadcasting = false
    @State private var showingUploadView = false
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            userGridView
        }
        .sheet(item: $selectedUser) { user in
            UserProfileView(user: user)
        }
        .sheet(isPresented: $showingPremiumUpgrade) {
            PremiumUpgradeView()
        }
        .sheet(isPresented: $showingUploadView) {
            NavigationView {
                ArchiveUploadView()
                    .navigationBarItems(
                        trailing: Button("Done") { showingUploadView = false }
                    )
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("MUSIC HUB")
                .font(.system(size: 31, weight: .heavy))
                .foregroundColor(.black)
            
            Spacer()
            
            HStack(spacing: 16) {
                broadcastButton
                refreshButton
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }
    
    private var broadcastButton: some View {
        Group {
            if decentralizedStorage.userProfile != nil {
                Button(action: {
                    if premiumManager.hasFeature.canBroadcastNowPlaying {
                        isBroadcasting.toggle()
                    } else {
                        showingPremiumUpgrade = true
                    }
                }) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(isBroadcasting ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                        Text(isBroadcasting ? "LIVE" : "GO LIVE")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(isBroadcasting ? .green : .gray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(16)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var refreshButton: some View {
        Button(action: {
            // Refresh users
        }) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 20))
                .foregroundColor(.gray)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var userGridView: some View {
        ScrollView {
            VStack(spacing: 24) {
                activeNowSection
                friendsSection
            }
            .padding(.vertical, 20)
        }
    }
    
    private var activeNowSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Active Now")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)
                .padding(.horizontal, 20)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(featuredUsers.prefix(4)) { user in
                    UserMusicCard(
                        user: user,
                        showingUploadView: $showingUploadView,
                        showingPremiumUpgrade: $showingPremiumUpgrade,
                        onTap: {
                            selectedUser = user
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Friends")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)
                .padding(.horizontal, 20)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(featuredUsers.dropFirst(4)) { user in
                    UserMusicCard(
                        user: user,
                        showingUploadView: $showingUploadView,
                        showingPremiumUpgrade: $showingPremiumUpgrade,
                        onTap: {
                            selectedUser = user
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - User Music Card
struct UserMusicCard: View {
    let user: UserProfile
    @Binding var showingUploadView: Bool
    @Binding var showingPremiumUpgrade: Bool
    let onTap: () -> Void
    @State private var isPlaying = false
    @StateObject private var globalAudioManager: GlobalAudioManager = GlobalAudioManager.shared
    @StateObject private var premiumManager: PremiumManager = PremiumManager.shared
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                cardImage
                cardInfo
            }
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.black, lineWidth: 3)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var cardImage: some View {
        ZStack(alignment: .bottomTrailing) {
            backgroundImage
            playButton
        }
        .frame(height: 180)
        .clipped()
    }
    
    private var backgroundImage: some View {
        Group {
            if let artworkURL = user.currentTrack?.artworkURL {
                AsyncImage(url: URL(string: artworkURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    userAvatar
                }
            } else {
                userAvatar
            }
        }
    }
    
    private var userAvatar: some View {
        Image(systemName: "person.circle.fill")
            .font(.system(size: 80))
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.1))
    }
    
    private var playButton: some View {
        Button(action: {
            playUserTrack()
        }) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.black.opacity(0.8))
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .padding(8)
    }
    
    private var cardInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            topRow
            trackInfo
        }
        .padding(12)
    }
    
    private var topRow: some View {
        HStack {
            Text(user.displayName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
                .lineLimit(1)
            
            Spacer()
            
            uploadButton
            
            if user.isCurrentlyListening {
                liveIndicator
            }
        }
    }
    
    private var uploadButton: some View {
        Button(action: {
            if premiumManager.isPremium {
                showingUploadView = true
            } else {
                showingPremiumUpgrade = true
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 16))
                Text("UPLOAD")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(premiumManager.isPremium ? Color.clear : Color.orange, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var liveIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
            Text("LIVE")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.green)
        }
    }
    
    private var trackInfo: some View {
        Group {
            if let track = user.currentTrack ?? user.featuredTrack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black)
                        .lineLimit(1)
                    
                    Text(track.artist)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            } else {
                Text("Not playing")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func playUserTrack() {
        if let track = user.currentTrack ?? user.featuredTrack {
            print("Playing track: \(track.title) by \(track.artist)")
            isPlaying.toggle()
        }
    }
}

// UserProfileView is defined in UserProfileView.swift

// MARK: - User Profile Model
struct UserProfile: Identifiable, Codable {
    let id: UUID
    let username: String
    let displayName: String
    let avatarURL: String?
    let bio: String
    var isCurrentlyListening: Bool
    var currentTrack: MusicTrack?
    var featuredTrack: MusicTrack?
    var uploadedTracks: [MusicTrack]
    let favoriteGenres: [String]
    let joinedDate: Date
    
    init(username: String, displayName: String, avatarURL: String? = nil, bio: String, isCurrentlyListening: Bool = false, currentTrack: MusicTrack? = nil, featuredTrack: MusicTrack? = nil, uploadedTracks: [MusicTrack] = [], favoriteGenres: [String] = [], joinedDate: Date = Date()) {
        self.id = UUID()
        self.username = username
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.bio = bio
        self.isCurrentlyListening = isCurrentlyListening
        self.currentTrack = currentTrack
        self.featuredTrack = featuredTrack
        self.uploadedTracks = uploadedTracks
        self.favoriteGenres = favoriteGenres
        self.joinedDate = joinedDate
    }
    
    // Mock data for development
    static let mockUsers: [UserProfile] = [
        UserProfile(
            username: "jadewii",
            displayName: "Jade",
            avatarURL: nil,
            bio: "Electronic music enthusiast",
            isCurrentlyListening: true,
            currentTrack: MusicTrack(
                title: "Fortyone - Music That's Better Than It Sounds",
                artist: "Classic Source",
                artworkURL: "https://archive.org/services/img/fortyone"
            ),
            featuredTrack: nil,
            uploadedTracks: [],
            favoriteGenres: ["Electronic", "Trance", "Lo-Fi"],
            joinedDate: Date()
        ),
        UserProfile(
            username: "musiclover23",
            displayName: "Alex Chen",
            avatarURL: nil,
            bio: "Jazz and classical vibes",
            isCurrentlyListening: true,
            currentTrack: MusicTrack(
                title: "Blue in Green",
                artist: "Miles Davis",
                artworkURL: nil
            ),
            featuredTrack: nil,
            uploadedTracks: [],
            favoriteGenres: ["Jazz", "Classical"],
            joinedDate: Date()
        ),
        UserProfile(
            username: "beatsmaster",
            displayName: "Sarah K",
            avatarURL: nil,
            bio: "Producer | Sharing my beats",
            isCurrentlyListening: false,
            currentTrack: nil,
            featuredTrack: MusicTrack(
                title: "Midnight Dreams",
                artist: "Sarah K",
                artworkURL: nil
            ),
            uploadedTracks: [],
            favoriteGenres: ["Hip-Hop", "R&B"],
            joinedDate: Date()
        ),
        UserProfile(
            username: "vinylcollector",
            displayName: "Marcus",
            avatarURL: nil,
            bio: "Collecting rare sounds",
            isCurrentlyListening: true,
            currentTrack: MusicTrack(
                title: "Interstellar Overdrive",
                artist: "Pink Floyd",
                artworkURL: nil
            ),
            featuredTrack: nil,
            uploadedTracks: [],
            favoriteGenres: ["Rock", "Psychedelic"],
            joinedDate: Date()
        )
    ]
}

// MARK: - Music Track Model
struct MusicTrack: Identifiable, Codable {
    let id: UUID
    let title: String
    let artist: String
    let artworkURL: String?
    var duration: TimeInterval
    var streamURL: String?
    var isUserUploaded: Bool
    var archiveOrgID: String?
    
    init(title: String, artist: String, artworkURL: String? = nil, duration: TimeInterval = 0, streamURL: String? = nil, isUserUploaded: Bool = false, archiveOrgID: String? = nil) {
        self.id = UUID()
        self.title = title
        self.artist = artist
        self.artworkURL = artworkURL
        self.duration = duration
        self.streamURL = streamURL
        self.isUserUploaded = isUserUploaded
        self.archiveOrgID = archiveOrgID
    }
}

#Preview {
    SocialHubView()
}