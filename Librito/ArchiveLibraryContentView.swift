//
//  ArchiveLibraryContentView.swift
//  Librito
//
//  Content view for Archive.org media browsing and streaming
//

import SwiftUI
import AVFoundation
import Combine

struct ArchiveLibraryContentView: View {
    @Binding var selectedMediaType: MediaType
    @StateObject private var archiveService = ArchiveOrgService.shared
    @StateObject private var classificationService = ContentClassificationService.shared
    @State private var searchQuery = ""
    @State private var hasSearched = false
    @State private var isGridView = false
    @State private var selectedGenreFilter: String? = nil
    @State private var selectedSourceFilter: SourceType? = nil
    @State private var selectedContentTypeFilter: ContentType? = nil
    var onNavigateToMyLibrary: (() -> Void)?
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header with search
                VStack(spacing: 16) {
                    HStack {
                        Text("LIBRARY")
                            .font(.system(size: 31, weight: .heavy))
                            .foregroundColor(.black)
                        
                        // Minimize button
                        Button(action: {
                            AppStateManager.shared.toggleMiniMode()
                        }) {
                            Image(systemName: "rectangle.compress.vertical")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                                .frame(width: 28, height: 28)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Minimize to mini player")
                        
                        Spacer()
                        
                        // Only show view toggle for Music
                        if selectedMediaType == .music {
                            Button(action: {
                                isGridView.toggle()
                            }) {
                                Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                                    .font(.system(size: 24))
                                    .foregroundColor(.black)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search Library...", text: $searchQuery)
                            .textFieldStyle(PlainTextFieldStyle())
                            .onSubmit {
                                searchLibrary()
                            }
                        
                        if !searchQuery.isEmpty {
                            Button(action: {
                                searchQuery = ""
                                archiveService.searchResults = []
                                hasSearched = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Filter chips when there are results or filters applied
                    if !archiveService.searchResults.isEmpty || selectedGenreFilter != nil || selectedSourceFilter != nil || selectedContentTypeFilter != nil {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                // Genre filter chip
                                if selectedGenreFilter != nil {
                                    FilterChip(
                                        title: selectedGenreFilter!,
                                        isSelected: true,
                                        action: { clearAllFilters() }
                                    )
                                }
                                
                                // Source filter chip
                                if let source = selectedSourceFilter {
                                    FilterChip(
                                        title: source.rawValue,
                                        isSelected: true,
                                        action: { clearAllFilters() }
                                    )
                                }
                                
                                // Content type filter chip
                                if let contentType = selectedContentTypeFilter {
                                    FilterChip(
                                        title: contentType.rawValue,
                                        isSelected: true,
                                        action: { clearAllFilters() }
                                    )
                                }
                                
                                // Clear all button if any filters are active
                                if selectedGenreFilter != nil || selectedSourceFilter != nil || selectedContentTypeFilter != nil {
                                    Button(action: {
                                        clearAllFilters()
                                    }) {
                                        Text("Clear All")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                // Content based on media type and search state
                if selectedMediaType == .radio {
                    RadioStreamingView()
                } else if archiveService.isLoading {
                    LoadingView()
                } else if archiveService.searchResults.isEmpty && hasSearched && !searchQuery.isEmpty {
                    EmptySearchView(error: archiveService.error)
                } else if (!archiveService.searchResults.isEmpty) || (hasSearched && (selectedGenreFilter != nil || selectedSourceFilter != nil || selectedContentTypeFilter != nil)) {
                    SearchResultsView(
                        selectedMediaType: selectedMediaType,
                        isGridView: isGridView,
                        selectedGenreFilter: $selectedGenreFilter,
                        selectedSourceFilter: $selectedSourceFilter,
                        selectedContentTypeFilter: $selectedContentTypeFilter,
                        onNavigateToMyLibrary: onNavigateToMyLibrary
                    )
                } else {
                    GenreCategoryView(
                        mediaType: selectedMediaType,
                        searchQuery: $searchQuery,
                        searchAction: searchLibrary,
                        selectedGenreFilter: $selectedGenreFilter,
                        selectedSourceFilter: $selectedSourceFilter,
                        selectedContentTypeFilter: $selectedContentTypeFilter,
                        onGenreSelected: loadContentForGenre
                    )
                }
            }
            .background(Color.white)
        }
        .onChange(of: selectedMediaType) { oldValue, newValue in
            // Clear search results when switching media types to show categories
            archiveService.searchResults = []
            hasSearched = false
            searchQuery = ""
            selectedGenreFilter = nil
            selectedSourceFilter = nil
            selectedContentTypeFilter = nil
        }
        .onAppear {
            // Start with empty state to show categories
            archiveService.searchResults = []
            hasSearched = false
        }
    }
    
    private func clearAllFilters() {
        selectedGenreFilter = nil
        selectedSourceFilter = nil
        selectedContentTypeFilter = nil
        hasSearched = false
        searchQuery = ""
        archiveService.searchResults = []
    }
    
    private func searchLibrary() {
        guard !searchQuery.isEmpty else { return }
        hasSearched = true
        
        // Clear previous results
        archiveService.searchResults = []
        
        // Get media type for search
        let mediaType = selectedMediaType.archiveMediaType
        
        // Trigger the search with both Archive.org media type and our library media type
        archiveService.search(query: searchQuery, mediaType: mediaType, libraryMediaType: selectedMediaType)
    }
    
    private func loadContentForGenre(_ genre: String) {
        // Load content for the genre
        hasSearched = true // This ensures SearchResultsView is shown
        
        // Reset pagination for new search
        archiveService.searchResults = []
        archiveService.currentPage = 0
        archiveService.hasMorePages = true
        
        let genreQuery = getGenreSearchQuery(genre)
        archiveService.search(
            query: genreQuery,
            mediaType: selectedMediaType.archiveMediaType,
            libraryMediaType: selectedMediaType
        )
    }
    
    private func getGenreSearchQuery(_ genre: String) -> String {
        switch selectedMediaType {
        case .audiobooks:
            switch genre {
            case "Philosophy": return "(subject:philosophy OR subject:stoicism OR subject:ethics) AND mediatype:audio"
            case "Fiction": return "subject:fiction AND mediatype:audio AND (collection:librivoxaudio OR subject:audiobook)"
            case "Non-Fiction": return "(subject:\"non-fiction\" OR subject:nonfiction) AND mediatype:audio AND (collection:librivoxaudio OR subject:audiobook)"
            case "Self-Help": return "(subject:\"self-help\" OR subject:\"self improvement\") AND mediatype:audio"
            case "History": return "(subject:history OR subject:historical) AND mediatype:audio AND (collection:librivoxaudio OR subject:audiobook)"
            case "Science": return "(subject:science OR subject:physics OR subject:biology OR subject:chemistry OR subject:mathematics) AND mediatype:audio AND (collection:librivoxaudio OR subject:audiobook)"
            case "Poetry": return "(subject:poetry OR subject:poems) AND mediatype:audio AND (collection:librivoxaudio OR subject:audiobook)"
            case "Classics": return "(subject:classics OR subject:literature) AND mediatype:audio AND (collection:librivoxaudio OR subject:audiobook)"
            case "Biography": return "(subject:biography OR subject:autobiography) AND mediatype:audio AND (collection:librivoxaudio OR subject:audiobook)"
            case "Mystery": return "(subject:mystery OR subject:detective OR subject:crime) AND mediatype:audio AND (collection:librivoxaudio OR subject:audiobook)"
            default: return "subject:" + genre.lowercased() + " AND mediatype:audio AND (collection:librivoxaudio OR subject:audiobook)"
            }
        case .books:
            switch genre {
            case "Philosophy": return "(subject:philosophy OR subject:stoicism OR subject:ethics) AND mediatype:texts"
            case "Fiction": return "subject:fiction AND mediatype:texts"
            case "Non-Fiction": return "(subject:\"non-fiction\" OR subject:nonfiction) AND mediatype:texts"
            case "Self-Help": return "(subject:\"self-help\" OR subject:\"self improvement\") AND mediatype:texts"
            case "History": return "(subject:history OR subject:historical) AND mediatype:texts"
            case "Science": return "(subject:science OR subject:physics OR subject:biology OR subject:chemistry OR subject:mathematics) AND mediatype:texts"
            case "Poetry": return "(subject:poetry OR subject:poems) AND mediatype:texts"
            case "Classics": return "(subject:classics OR subject:literature) AND mediatype:texts"
            case "Biography": return "(subject:biography OR subject:autobiography) AND mediatype:texts"
            case "Mystery": return "(subject:mystery OR subject:detective OR subject:crime) AND mediatype:texts"
            default: return "subject:" + genre.lowercased() + " AND mediatype:texts"
            }
        case .music:
            switch genre {
            case "Classical": return "(subject:classical OR subject:orchestra OR subject:symphony) AND mediatype:audio AND NOT subject:audiobook"
            case "Jazz": return "subject:jazz AND mediatype:audio AND NOT subject:audiobook"
            case "Folk": return "(subject:folk OR subject:traditional) AND mediatype:audio AND NOT subject:audiobook"
            case "Electronic": return "(subject:electronic OR subject:synthesizer OR subject:techno) AND mediatype:audio AND NOT subject:audiobook"
            case "Trance": return "(subject:trance OR subject:psychedelic) AND mediatype:audio AND NOT subject:audiobook"
            case "Lo-Fi": return "(subject:\"lo-fi\" OR subject:lofi OR subject:chill) AND mediatype:audio AND NOT subject:audiobook"
            case "Ambient": return "subject:ambient AND mediatype:audio AND NOT subject:audiobook"
            case "Rock": return "subject:rock AND mediatype:audio AND NOT subject:audiobook"
            case "Experimental": return "(subject:experimental OR subject:avant) AND mediatype:audio AND NOT subject:audiobook"
            case "World Music": return "(subject:world OR subject:ethnic OR subject:traditional) AND mediatype:audio AND NOT subject:audiobook"
            default: return "subject:" + genre.lowercased() + " AND mediatype:audio AND NOT subject:audiobook"
            }
        case .radio:
            switch genre {
            case "Old Time Radio": return "(collection:oldtimeradio OR subject:\"old time radio\") AND mediatype:audio"
            case "Talk Shows": return "(subject:talk OR subject:interview) AND mediatype:audio"
            case "Drama": return "(subject:drama OR subject:theater) AND mediatype:audio AND (collection:oldtimeradio OR subject:radio)"
            case "Comedy": return "(subject:comedy OR subject:humor) AND mediatype:audio AND (collection:oldtimeradio OR subject:radio)"
            case "News": return "(subject:news OR subject:report) AND mediatype:audio"
            case "Educational": return "(subject:educational OR subject:lecture) AND mediatype:audio"
            case "Music Programs": return "subject:music AND mediatype:audio AND (collection:oldtimeradio OR subject:radio)"
            default: return "subject:" + genre.lowercased() + " AND mediatype:audio"
            }
        case .journal:
            return "" // Journal is local only, no archive.org query
        case .hub:
            return "" // Hub doesn't use genre queries
        }
    }
    
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Searching Library...")
                .font(.system(size: 20))
                .foregroundColor(.gray)
            
            Spacer()
        }
    }
}

// MARK: - Empty Search Results
struct EmptySearchView: View {
    let error: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("🔍")
                .font(.system(size: 48))
            
            Text("No Results Found")
                .font(.system(size: 25, weight: .semibold))
                .foregroundColor(.black)
            
            if let error = error {
                Text("Error: \(error)")
                    .font(.system(size: 18))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            } else {
                Text("Try a different search term or browse suggestions below")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
}

// MARK: - Search Results
struct SearchResultsView: View {
    let selectedMediaType: MediaType
    let isGridView: Bool
    @StateObject private var archiveService = ArchiveOrgService.shared
    @StateObject private var classificationService = ContentClassificationService.shared
    @Binding var selectedGenreFilter: String?
    @Binding var selectedSourceFilter: SourceType?
    @Binding var selectedContentTypeFilter: ContentType?
    var onNavigateToMyLibrary: (() -> Void)?
    
    private var filteredResults: [ArchiveOrgService.ArchiveItem] {
        let results = archiveService.searchResults
        
        // Temporarily disable filtering to test if search results are coming through
        // TODO: Re-enable filtering once we confirm search is working
        
        // Apply genre filter
        // if let genreFilter = selectedGenreFilter {
        //     results = results.filter { item in
        //         let classification = classificationService.classifyItem(item, mediaType: selectedMediaType.rawValue)
        //         return classification.genre(for: selectedMediaType.rawValue) == genreFilter
        //     }
        // }
        
        // Apply source filter
        // if let sourceFilter = selectedSourceFilter {
        //     results = classificationService.itemsForSource(source: sourceFilter, in: results, mediaType: selectedMediaType.rawValue)
        // }
        
        // Apply content type filter
        // if let contentTypeFilter = selectedContentTypeFilter {
        //     results = classificationService.itemsForContentType(type: contentTypeFilter, in: results, mediaType: selectedMediaType.rawValue)
        // }
        
        return results
    }
    
    var body: some View {
        ScrollView {
            
            // Force grid view for books and audiobooks, use isGridView toggle only for music
            if selectedMediaType != .music || isGridView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(filteredResults) { item in
                        ArchiveItemGridCard(
                            item: item,
                            mediaType: selectedMediaType,
                            allItems: filteredResults,
                            onNavigateToMyLibrary: onNavigateToMyLibrary
                        )
                        .onAppear {
                            // Load more when reaching the last few items
                            if let index = filteredResults.firstIndex(where: { $0.id == item.id }),
                               index >= filteredResults.count - 8 {
                                archiveService.loadMore()
                            }
                        }
                    }
                    
                    // Loading indicator for more content
                    if archiveService.isLoadingMore {
                        HStack {
                            Spacer()
                            ProgressView()
                                .scaleEffect(1.2)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(filteredResults) { item in
                        ArchiveItemCard(
                            item: item, 
                            mediaType: selectedMediaType,
                            allItems: filteredResults,
                            onNavigateToMyLibrary: onNavigateToMyLibrary
                        )
                        .if(selectedMediaType == .music) { view in
                            view
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .cornerRadius(8)
                                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                        .onAppear {
                            // Load more when reaching the last few items
                            if let index = filteredResults.firstIndex(where: { $0.id == item.id }),
                               index >= filteredResults.count - 4 {
                                archiveService.loadMore()
                            }
                        }
                    }
                    
                    // Loading indicator for more content
                    if archiveService.isLoadingMore {
                        HStack {
                            Spacer()
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading more...")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .padding(.vertical, 20)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Archive Item Card
struct ArchiveItemCard: View {
    let item: ArchiveOrgService.ArchiveItem
    let mediaType: MediaType
    let allItems: [ArchiveOrgService.ArchiveItem]
    @State private var isDownloading = false
    @State private var downloadComplete = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isStreaming = false
    @State private var audioPlayer: AVPlayer?
    @State private var cancellables = Set<AnyCancellable>()
    @StateObject private var globalAudioManager = GlobalAudioManager.shared
    // @StateObject private var contentSafety = ContentSafetyService.shared // Temporarily disabled
    // @StateObject private var contentModeration = ContentModerationService.shared // Temporarily disabled
    @StateObject private var playlistService = PlaylistService.shared
    @State private var showingPlaylistSelection = false
    @State private var addedToLibraryFeedback = false
    @State private var showingPDFViewer = false
    @State private var pdfURL: URL?
    var onNavigateToMyLibrary: (() -> Void)?
    
    init(item: ArchiveOrgService.ArchiveItem, mediaType: MediaType, allItems: [ArchiveOrgService.ArchiveItem] = [], onNavigateToMyLibrary: (() -> Void)? = nil) {
        self.item = item
        self.mediaType = mediaType
        self.allItems = allItems
        self.onNavigateToMyLibrary = onNavigateToMyLibrary
    }
    
    var isCurrentlyPlaying: Bool {
        globalAudioManager.isPlaying && globalAudioManager.currentTitle == item.title
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail (completely removed for music, shown for other media)
            if mediaType != .music {
                AsyncImage(url: URL(string: "https://archive.org/services/img/\(item.identifier)")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            Image(systemName: getMediaIcon())
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 60, height: 80)
                .cornerRadius(8)
            }
            
            // Music track layout - clean and contained
            if mediaType == .music {
                HStack(spacing: 0) {
                    // Play button
                    Button(action: {
                        if isCurrentlyPlaying {
                            stopStreaming()
                        } else {
                            startStreaming()
                        }
                    }) {
                        Image(systemName: isCurrentlyPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(isCurrentlyPlaying ? .white : .black)
                            .frame(width: 44, height: 44)
                            .background(isCurrentlyPlaying ? Color.black : Color.clear)
                            .cornerRadius(22)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Track info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.system(size: 16, weight: .medium))
                            .lineLimit(1)
                            .foregroundColor(.black)
                        
                        if let creator = item.creator {
                            Text(creator)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }
                    .padding(.leading, 12)
                    
                    Spacer()
                    
                    // Action buttons inline
                    HStack(spacing: 8) {
                        // Add to Library
                        Button(action: {
                            addToLibrary()
                        }) {
                            Image(systemName: playlistService.isInLibrary(item.id) ? "checkmark.circle.fill" : "plus.circle")
                                .font(.system(size: 20))
                                .foregroundColor(playlistService.isInLibrary(item.id) ? .green : .gray)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Add to Playlist
                        Button(action: {
                            showingPlaylistSelection = true
                        }) {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
            } else {
                // Non-music layout (books, videos, etc)
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 20, weight: .medium))
                        .lineLimit(2)
                        .foregroundColor(.black)
                    
                    if let creator = item.creator {
                        Text(creator)
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    
                    Text("Source: Archive.org")
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.7))
                    
                    if let date = item.date {
                        Text(date)
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: 8) {
                        // First row: Stream/Play and Navigation
                        HStack(spacing: 12) {
                            if mediaType == .audiobooks && 
                               item.mediatype.lowercased() == "audio" {
                                // Stream button for audio/video content only
                                Button(action: {
                                    if isCurrentlyPlaying {
                                        stopStreaming()
                                    } else {
                                        startStreaming()
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: isCurrentlyPlaying ? "stop.fill" : "play.fill")
                                            .font(.system(size: 15))
                                        Text(isCurrentlyPlaying ? "Stop" : "Stream")
                                            .font(.system(size: 15, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.black)
                                    .cornerRadius(6)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            Spacer()
                        }
                        
                        // Second row: Library and PDF buttons
                        HStack(spacing: 8) {
                            // Add to Library button
                            Button(action: {
                                addToLibrary()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: playlistService.isInLibrary(item.id) ? "checkmark.circle.fill" : "plus.circle")
                                        .font(.system(size: 14))
                                    if addedToLibraryFeedback {
                                        Text("✓ Added!")
                                            .font(.system(size: 14, weight: .medium))
                                    } else {
                                        Text(playlistService.isInLibrary(item.id) ? "In Library" : "Add to Library")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                }
                                .foregroundColor(playlistService.isInLibrary(item.id) ? .green : .blue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(playlistService.isInLibrary(item.id))
                            
                            Spacer()
                            
                            // PDF View button for books
                            if mediaType == .books && item.mediatype.lowercased() == "texts" {
                                Button(action: {
                                    openPDFViewer()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "book.fill")
                                            .font(.system(size: 14))
                                        Text("Read")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(6)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        
                        // Download button
                        if downloadComplete {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 20))
                        } else if isDownloading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Button(action: {
                                downloadItem()
                            }) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
    }
    .padding(12)
    .background(Color.gray.opacity(0.05))
    .cornerRadius(12)
    .alert("Notice", isPresented: $showingAlert) {
            Button("OK") { 
                showingAlert = false
            }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingPlaylistSelection) {
            PlaylistSelectionView(item: item)
        }
        .fullScreenCover(isPresented: $showingPDFViewer) {
            if let pdfURL = pdfURL {
                InAppPDFViewer(item: item, pdfURL: pdfURL)
            }
        }
    }
    
    private func openPDFViewer() {
        ArchiveOrgService.shared.downloadItem(item) { url in
            guard let downloadURL = url else {
                DispatchQueue.main.async {
                    self.alertMessage = "PDF not available for viewing"
                    self.showingAlert = true
                }
                return
            }
            
            DispatchQueue.main.async {
                self.pdfURL = downloadURL
                self.showingPDFViewer = true
            }
        }
    }
    
    private func addToLibrary() {
        playlistService.addToLibrary(item)
        addedToLibraryFeedback = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            addedToLibraryFeedback = false
        }
    }
    
    private func playPreviousTrack() {
        globalAudioManager.playPreviousTrack()
    }
    
    private func playNextTrack() {
        globalAudioManager.playNextTrack()
    }
    
    private func getMediaIcon() -> String {
        switch mediaType {
        case .audiobooks: return "book.fill"
        case .books: return "doc.fill"
        case .music: return "music.note"
        case .radio: return "radio.fill"
        case .journal: return "doc.text.fill"
        case .hub:
            return "globe"
        }
    }
    
    private func downloadItem() {
        isDownloading = true
        
        ArchiveOrgService.shared.downloadItem(item) { url in
            guard let downloadURL = url else {
                DispatchQueue.main.async {
                    self.isDownloading = false
                    self.alertMessage = "No downloadable file found for this item"
                    self.showingAlert = true
                }
                return
            }
            
            // Download the file
            URLSession.shared.downloadTask(with: downloadURL) { tempURL, _, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.isDownloading = false
                        self.alertMessage = "Download failed: \(error.localizedDescription)"
                        self.showingAlert = true
                    }
                    return
                }
                
                guard let tempURL = tempURL else {
                    DispatchQueue.main.async {
                        self.isDownloading = false
                        self.alertMessage = "Download failed: No file received"
                        self.showingAlert = true
                    }
                    return
                }
                
                do {
                    let fileData = try Data(contentsOf: tempURL)
                    DispatchQueue.main.async {
                        // Add to library using shared BookManager
                        _ = BookManager.shared.addBook(
                            title: self.item.title,
                            author: self.item.creator ?? "Unknown Author",
                            fileData: fileData,
                            fileName: downloadURL.lastPathComponent,
                            mode: "library"
                        )
                        
                        self.isDownloading = false
                        self.downloadComplete = true
                        
                        // Navigate to My Library instead of showing alert
                        self.onNavigateToMyLibrary?()
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.isDownloading = false
                        self.alertMessage = "Failed to save file: \(error.localizedDescription)"
                        self.showingAlert = true
                    }
                }
            }.resume()
        }
    }
    
    private func startStreaming() {
        // For music, set up the queue context first
        if mediaType == .music {
            globalAudioManager.startTrackInContext(item: item, from: allItems)
        } else {
            // For non-music content, use the original streaming logic
            ArchiveOrgService.shared.getStreamingURL(for: item) { url in
                guard let streamURL = url else {
                    DispatchQueue.main.async {
                        self.alertMessage = "No streamable file found for this item"
                        self.showingAlert = true
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    print("Starting stream from URL: \(streamURL)")
                    
                    let playerItem = AVPlayerItem(url: streamURL)
                    self.audioPlayer = AVPlayer(playerItem: playerItem)
                    
                    GlobalAudioManager.shared.startNewStream(player: self.audioPlayer!, title: self.item.title, identifier: self.item.identifier)
                    
                    playerItem.publisher(for: \.error)
                        .compactMap { $0 }
                        .sink { error in
                            print("Player error: \(error)")
                            DispatchQueue.main.async {
                                self.isStreaming = false
                                self.alertMessage = "Streaming failed: \(error.localizedDescription)"
                                self.showingAlert = true
                            }
                        }
                        .store(in: &self.cancellables)
                    
                    playerItem.publisher(for: \.status)
                        .sink { status in
                            switch status {
                            case .readyToPlay:
                                print("Player ready to play")
                                self.audioPlayer?.play()
                            case .failed:
                                if let error = playerItem.error {
                                    print("Player failed with error: \(error)")
                                    let nsError = error as NSError
                                    print("Error domain: \(nsError.domain), code: \(nsError.code)")
                                    print("Error userInfo: \(nsError.userInfo)")
                                    print("Failed URL: \(streamURL)")
                                    DispatchQueue.main.async {
                                        self.isStreaming = false
                                        if nsError.code == -1102 {
                                            print("Streaming not available for this item due to transport security")
                                        } else if nsError.code == 1012 || nsError.code == 1013 {
                                            print("Item not available for streaming")
                                        } else {
                                            self.alertMessage = "Streaming not available. Try downloading instead."
                                            self.showingAlert = true
                                        }
                                    }
                                }
                            case .unknown:
                                print("Player status unknown")
                            @unknown default:
                                break
                            }
                        }
                        .store(in: &self.cancellables)
                    
                    self.isStreaming = true
                    self.audioPlayer?.volume = 1.0
                }
            }
        }
    }
    
    private func stopStreaming() {
        GlobalAudioManager.shared.stopAllPlayback()
        audioPlayer = nil
        isStreaming = false
    }
}

// MARK: - Archive Item Grid Card
struct ArchiveItemGridCard: View {
    let item: ArchiveOrgService.ArchiveItem
    let mediaType: MediaType
    let allItems: [ArchiveOrgService.ArchiveItem]
    @State private var isDownloading = false
    @State private var downloadComplete = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isStreaming = false
    @State private var audioPlayer: AVPlayer?
    @State private var cancellables = Set<AnyCancellable>()
    @StateObject private var globalAudioManager = GlobalAudioManager.shared
    // @StateObject private var contentSafety = ContentSafetyService.shared // Temporarily disabled
    // @StateObject private var contentModeration = ContentModerationService.shared // Temporarily disabled
    @StateObject private var playlistService = PlaylistService.shared
    @State private var showingPlaylistSelection = false
    @State private var addedToLibraryFeedback = false
    @State private var showingPDFViewer = false
    @State private var pdfURL: URL?
    var onNavigateToMyLibrary: (() -> Void)?
    
    init(item: ArchiveOrgService.ArchiveItem, mediaType: MediaType, allItems: [ArchiveOrgService.ArchiveItem] = [], onNavigateToMyLibrary: (() -> Void)? = nil) {
        self.item = item
        self.mediaType = mediaType
        self.allItems = allItems
        self.onNavigateToMyLibrary = onNavigateToMyLibrary
    }
    
    var isCurrentlyPlaying: Bool {
        globalAudioManager.isPlaying && globalAudioManager.currentTitle == item.title
    }
    
    var body: some View {
        VStack(spacing: 8) {
            if mediaType == .music {
                // For music: show text-based card with oscilloscope
                VStack(spacing: 12) {
                    VStack(spacing: 8) {
                        Text(item.title)
                            .font(.system(size: 16, weight: .semibold))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.black)
                        
                        if let creator = item.creator {
                            Text(creator)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                        
                        Text("♪ Audio Track")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 16)
                    
                    // Oscilloscope or placeholder
                    if isCurrentlyPlaying {
                        OscilloscopeVisualizer(player: audioPlayer, isPlaying: isCurrentlyPlaying)
                            .frame(height: 60)
                            .background(Color.black.opacity(0.05))
                            .cornerRadius(8)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 60)
                            .cornerRadius(8)
                            .overlay(
                                HStack(spacing: 4) {
                                    Image(systemName: "music.note")
                                        .font(.system(size: 20))
                                    Text("Tap to play")
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(.gray.opacity(0.6))
                            )
                    }
                }
                .frame(height: 180)
            } else {
                // For non-music: show thumbnail as before
                AsyncImage(url: URL(string: "https://archive.org/services/img/\(item.identifier)")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            Image(systemName: getMediaIcon())
                                .font(.system(size: 52))
                                .foregroundColor(.gray)
                        )
                }
                .frame(height: 254)
                .cornerRadius(12)
            }
            
            if mediaType != .music {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 16, weight: .medium))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.black)
                        .frame(minHeight: 48, alignment: .top)
                    
                    if let creator = item.creator {
                        Text(creator)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .frame(minHeight: 18, alignment: .top)
                    } else {
                        Spacer()
                            .frame(minHeight: 18)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 8)
                .frame(minHeight: 100, maxHeight: 100)
            } else {
                // For music: smaller action area
                Spacer()
            }
            
            // Action buttons
            VStack(spacing: 8) {
                // First row: Play and Navigation
                HStack(spacing: 8) {
                    if (mediaType == .audiobooks || mediaType == .music) && 
                       item.mediatype.lowercased() == "audio" {
                        Button(action: {
                            if isCurrentlyPlaying {
                                stopStreaming()
                            } else {
                                startStreaming()
                            }
                        }) {
                            Image(systemName: isCurrentlyPlaying ? "stop.fill" : "play.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.black)
                                .cornerRadius(18)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Spacer()
                    
                    // PDF View button for books (grid)
                    if mediaType == .books && item.mediatype.lowercased() == "texts" {
                        Button(action: {
                            openPDFViewer()
                        }) {
                            Image(systemName: "book.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.orange)
                                .cornerRadius(18)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Button(action: {
                        downloadItem()
                    }) {
                        if downloadComplete {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                        } else if isDownloading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: 36, height: 36)
                }
                
                // Second row: Library and Playlist
                HStack(spacing: 6) {
                    // Add to Library button
                    Button(action: {
                        addToLibraryGrid()
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: playlistService.isInLibrary(item.id) ? "checkmark.circle.fill" : "plus.circle")
                                .font(.system(size: 16))
                            Text(addedToLibraryFeedback ? "✓" : (playlistService.isInLibrary(item.id) ? "✓" : "+"))
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(playlistService.isInLibrary(item.id) ? .green : .blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(playlistService.isInLibrary(item.id))
                    
                    // Add to Playlist button (music only)
                    if mediaType == .music {
                        Button(action: {
                            showingPlaylistSelection = true
                        }) {
                            VStack(spacing: 2) {
                                Image(systemName: "music.note.list")
                                    .font(.system(size: 16))
                                Text("♪")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(.purple)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 8)
            .frame(minHeight: mediaType == .music ? 60 : 156, maxHeight: mediaType == .music ? 60 : 156)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .frame(minHeight: mediaType == .music ? 300 : 435, maxHeight: mediaType == .music ? 300 : 435)
        .alert("Notice", isPresented: $showingAlert) {
            Button("OK") { 
                showingAlert = false
            }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingPlaylistSelection) {
            PlaylistSelectionView(item: item)
        }
        .fullScreenCover(isPresented: $showingPDFViewer) {
            if let pdfURL = pdfURL {
                InAppPDFViewer(item: item, pdfURL: pdfURL)
            }
        }
    }
    
    private func openPDFViewer() {
        ArchiveOrgService.shared.downloadItem(item) { url in
            guard let downloadURL = url else {
                DispatchQueue.main.async {
                    self.alertMessage = "PDF not available for viewing"
                    self.showingAlert = true
                }
                return
            }
            
            DispatchQueue.main.async {
                self.pdfURL = downloadURL
                self.showingPDFViewer = true
            }
        }
    }
    
    private func getMediaIcon() -> String {
        switch mediaType {
        case .audiobooks: return "book.fill"
        case .books: return "doc.fill"
        case .music: return "music.note"
        case .radio: return "radio.fill"
        case .journal: return "doc.text.fill"
        case .hub:
            return "globe"
        }
    }
    
    private func downloadItem() {
        isDownloading = true
        
        ArchiveOrgService.shared.downloadItem(item) { url in
            guard let downloadURL = url else {
                DispatchQueue.main.async {
                    self.isDownloading = false
                    self.alertMessage = "No downloadable file found for this item"
                    self.showingAlert = true
                }
                return
            }
            
            URLSession.shared.downloadTask(with: downloadURL) { tempURL, _, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.isDownloading = false
                        self.alertMessage = "Download failed: \(error.localizedDescription)"
                        self.showingAlert = true
                    }
                    return
                }
                
                guard let tempURL = tempURL else {
                    DispatchQueue.main.async {
                        self.isDownloading = false
                        self.alertMessage = "Download failed: No file received"
                        self.showingAlert = true
                    }
                    return
                }
                
                do {
                    let fileData = try Data(contentsOf: tempURL)
                    DispatchQueue.main.async {
                        _ = BookManager.shared.addBook(
                            title: self.item.title,
                            author: self.item.creator ?? "Unknown Author",
                            fileData: fileData,
                            fileName: downloadURL.lastPathComponent,
                            mode: "library"
                        )
                        
                        self.isDownloading = false
                        self.downloadComplete = true
                        self.onNavigateToMyLibrary?()
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.isDownloading = false
                        self.alertMessage = "Failed to save file: \(error.localizedDescription)"
                        self.showingAlert = true
                    }
                }
            }.resume()
        }
    }
    
    private func startStreaming() {
        // For music, set up the queue context first
        if mediaType == .music {
            globalAudioManager.startTrackInContext(item: item, from: allItems)
        } else {
            // For non-music content, use the original streaming logic
            ArchiveOrgService.shared.getStreamingURL(for: item) { url in
                guard let streamURL = url else {
                    DispatchQueue.main.async {
                        self.alertMessage = "No streamable file found for this item"
                        self.showingAlert = true
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    let playerItem = AVPlayerItem(url: streamURL)
                    self.audioPlayer = AVPlayer(playerItem: playerItem)
                    
                    GlobalAudioManager.shared.startNewStream(player: self.audioPlayer!, title: self.item.title, identifier: self.item.identifier)
                    
                    playerItem.publisher(for: \.error)
                        .compactMap { $0 }
                        .sink { error in
                            print("Player error: \(error)")
                            DispatchQueue.main.async {
                                self.isStreaming = false
                                self.alertMessage = "Streaming failed: \(error.localizedDescription)"
                                self.showingAlert = true
                            }
                        }
                        .store(in: &self.cancellables)
                    
                    playerItem.publisher(for: \.status)
                        .sink { status in
                            switch status {
                            case .readyToPlay:
                                self.audioPlayer?.play()
                            case .failed:
                                if let error = playerItem.error {
                                    let nsError = error as NSError
                                    DispatchQueue.main.async {
                                        self.isStreaming = false
                                        if nsError.code == -1102 || nsError.code == 1012 || nsError.code == 1013 {
                                            print("Item not available for streaming")
                                        } else {
                                            self.alertMessage = "Streaming not available. Try downloading instead."
                                            self.showingAlert = true
                                        }
                                    }
                                }
                            case .unknown:
                                print("Player status unknown")
                            @unknown default:
                                break
                            }
                        }
                        .store(in: &self.cancellables)
                    
                    self.isStreaming = true
                    self.audioPlayer?.volume = 1.0
                }
            }
        }
    }
    
    private func stopStreaming() {
        GlobalAudioManager.shared.stopAllPlayback()
        audioPlayer = nil
        isStreaming = false
    }
    
    private func addToLibraryGrid() {
        playlistService.addToLibrary(item)
        addedToLibraryFeedback = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            addedToLibraryFeedback = false
        }
    }
}

// MARK: - Welcome/Suggestions View
struct WelcomeToLibraryView: View {
    let mediaType: MediaType
    @Binding var searchQuery: String
    let searchAction: () -> Void
    
    private var suggestions: [String] {
        switch mediaType {
        case .audiobooks:
            return ["Philosophy", "Stoicism", "Ancient History", "Classical Literature", "Ethics", "Meditations"]
        case .books:
            return ["Marcus Aurelius", "Seneca", "Epictetus", "Newton", "Philosophy", "Science"]
        case .music:
            return ["Classical", "Jazz", "Instrumental", "Public Radio", "NPR Archives", "University Collections"]
        case .radio:
            return [] // Radio has its own interface
        case .journal:
            return [] // Journal is local only
        case .hub:
            return []
        }
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 20) {
                Text("🏛️")
                    .font(.system(size: 48))
                
                Text("Welcome to Library")
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundColor(.black)
                
                Text("Discover timeless \(mediaType.rawValue) from public collections")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Popular Searches:")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.black)
                    
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button(action: {
                            searchQuery = suggestion
                            searchAction()
                        }) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 18))
                                    .foregroundColor(.gray)
                                Text(suggestion)
                                    .font(.system(size: 20))
                                    .foregroundColor(.black)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 18))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
}

// MARK: - Radio Streaming (Placeholder)
struct RadioStreamingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("📻")
                .font(.system(size: 48))
            
            Text("Classic Radio")
                .font(.system(size: 25, weight: .semibold))
                .foregroundColor(.black)
            
            Text("Stream timeless radio programs and educational content")
                .font(.system(size: 18))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            // Radio player controls would go here
            
            Spacer()
        }
    }
}

// MARK: - Genre Category View
struct GenreCategoryView: View {
    let mediaType: MediaType
    @Binding var searchQuery: String
    let searchAction: () -> Void
    @Binding var selectedGenreFilter: String?
    @Binding var selectedSourceFilter: SourceType?
    @Binding var selectedContentTypeFilter: ContentType?
    let onGenreSelected: (String) -> Void
    @StateObject private var archiveService = ArchiveOrgService.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Welcome Section
                VStack(spacing: 20) {
                    Text("🏛️")
                        .font(.system(size: 48))
                    
                    Text("Discover by Genre")
                        .font(.system(size: 25, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text("Browse curated \(mediaType.rawValue) by category")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 30)
                
                // Genre Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(genresForMediaType(), id: \.self) { genre in
                        GenreTileView(
                            genre: genre,
                            mediaType: mediaType,
                            onTap: {
                                selectedGenreFilter = genre
                                onGenreSelected(genre)
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
                
                // Quick Filters Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Filter by Source")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(SourceType.allCases, id: \.self) { source in
                                SourceChip(
                                    source: source,
                                    isSelected: selectedSourceFilter == source,
                                    action: {
                                        selectedSourceFilter = source == selectedSourceFilter ? nil : source
                                        if source != selectedSourceFilter {
                                            loadContentForSource(source)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.top, 20)
                
                Spacer(minLength: 50)
            }
        }
    }
    
    private func genresForMediaType() -> [String] {
        switch mediaType {
        case .audiobooks:
            return AudiobookGenre.allCases.map { $0.rawValue }
        case .music:
            return MusicGenre.allCases.map { $0.rawValue }
        case .radio:
            return RadioGenre.allCases.map { $0.rawValue }
        case .books:
            return AudiobookGenre.allCases.map { $0.rawValue } // Use audiobook genres for books
        case .journal:
            return [] // Journal is local only
        case .hub:
            return []
        }
    }
    
    
    private func loadContentForSource(_ source: SourceType) {
        // Load content filtered by source
        archiveService.search(
            query: "",
            mediaType: mediaType.archiveMediaType,
            libraryMediaType: mediaType
        )
    }
}

// MARK: - Genre Tile View
struct GenreTileView: View {
    let genre: String
    let mediaType: MediaType
    let onTap: () -> Void
    
    private var genreIcon: String {
        switch mediaType {
        case .audiobooks:
            return AudiobookGenre(rawValue: genre)?.icon ?? "book.fill"
        case .music:
            return MusicGenre(rawValue: genre)?.icon ?? "music.note"
        case .radio:
            return RadioGenre(rawValue: genre)?.icon ?? "radio.fill"
        case .books:
            return AudiobookGenre(rawValue: genre)?.icon ?? "book.fill"
        case .journal:
            return "doc.text.fill"
        case .hub:
            return "globe"
        }
    }
    
    private var genreColor: Color {
        switch mediaType {
        case .audiobooks, .books:
            return AudiobookGenre(rawValue: genre)?.color ?? .blue
        case .music:
            return MusicGenre(rawValue: genre)?.color ?? .purple
        case .radio:
            return RadioGenre(rawValue: genre)?.color ?? .brown
        default:
            return .gray
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: genreIcon)
                    .font(.system(size: 36))
                    .foregroundColor(.black)
                
                Text(genre)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .padding(.horizontal, 16)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .stroke(Color.black, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Source Chip
struct SourceChip: View {
    let source: SourceType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: sourceIcon)
                    .font(.system(size: 14))
                Text(source.rawValue)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .black)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.black : Color.gray.opacity(0.1))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var sourceIcon: String {
        switch source {
        case .classicSource: return "building.columns"
        case .universityArchive: return "graduationcap"
        case .librivox: return "book.closed"
        case .publicDomain: return "globe"
        case .community: return "person.3"
        case .museum: return "building.2"
        case .library: return "books.vertical"
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                if isSelected {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                }
            }
            .foregroundColor(isSelected ? .white : .black)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.black : Color.gray.opacity(0.1))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - View Extension for Conditional Modifier
extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    ArchiveLibraryContentView(selectedMediaType: .constant(.audiobooks))
}