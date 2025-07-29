//
//  ContentClassification.swift
//  Librito
//
//  Genre and type classification for Archive.org content
//

import Foundation
import SwiftUI

// MARK: - Genre Classification
enum MusicGenre: String, CaseIterable {
    case trance = "Trance"
    case jazz = "Jazz"
    case lofi = "Lo-Fi"
    case ambient = "Ambient"
    case classical = "Classical"
    case electronic = "Electronic"
    case rock = "Rock"
    case folk = "Folk"
    case experimental = "Experimental"
    case world = "World Music"
    
    var icon: String {
        switch self {
        case .trance, .electronic: return "waveform"
        case .jazz: return "music.note"
        case .lofi, .ambient: return "cloud"
        case .classical: return "pianokeys"
        case .rock: return "guitars"
        case .folk: return "banjo"
        case .experimental: return "dial.high"
        case .world: return "globe"
        }
    }
    
    var color: Color {
        switch self {
        case .trance, .electronic: return .purple
        case .jazz: return .orange
        case .lofi, .ambient: return .blue
        case .classical: return .brown
        case .rock: return .red
        case .folk: return .green
        case .experimental: return .pink
        case .world: return .teal
        }
    }
}

enum AudiobookGenre: String, CaseIterable {
    case fiction = "Fiction"
    case nonFiction = "Non-Fiction"
    case philosophy = "Philosophy"
    case selfHelp = "Self-Help"
    case history = "History"
    case science = "Science"
    case poetry = "Poetry"
    case classics = "Classics"
    case biography = "Biography"
    case mystery = "Mystery"
    
    var icon: String {
        switch self {
        case .fiction: return "book.fill"
        case .nonFiction: return "doc.text.fill"
        case .philosophy: return "brain"
        case .selfHelp: return "heart.fill"
        case .history: return "clock.fill"
        case .science: return "atom"
        case .poetry: return "text.quote"
        case .classics: return "building.columns.fill"
        case .biography: return "person.fill"
        case .mystery: return "magnifyingglass"
        }
    }
    
    var color: Color {
        switch self {
        case .fiction: return .blue
        case .nonFiction: return .green
        case .philosophy: return .purple
        case .selfHelp: return .pink
        case .history: return .brown
        case .science: return .cyan
        case .poetry: return .orange
        case .classics: return .indigo
        case .biography: return .gray
        case .mystery: return .red
        }
    }
}

enum VideoGenre: String, CaseIterable {
    case educational = "Educational"
    case documentary = "Documentary"
    case classicTV = "Classic TV"
    case animation = "Animation"
    case lectures = "Lectures"
    case publicAccess = "Public Access"
    case artFilms = "Art Films"
    case historical = "Historical"
    
    var icon: String {
        switch self {
        case .educational: return "graduationcap.fill"
        case .documentary: return "doc.plaintext.fill"
        case .classicTV: return "tv.fill"
        case .animation: return "paintbrush.fill"
        case .lectures: return "person.wave.2.fill"
        case .publicAccess: return "antenna.radiowaves.left.and.right"
        case .artFilms: return "theatermasks.fill"
        case .historical: return "building.2.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .educational: return .blue
        case .documentary: return .orange
        case .classicTV: return .purple
        case .animation: return .pink
        case .lectures: return .green
        case .publicAccess: return .red
        case .artFilms: return .indigo
        case .historical: return .brown
        }
    }
}

enum ArtStyle: String, CaseIterable {
    case impressionism = "Impressionism"
    case modernArt = "Modern Art"
    case classical = "Classical"
    case photography = "Photography"
    case digital = "Digital"
    case sketches = "Sketches"
    case paintings = "Paintings"
    case sculptures = "Sculptures"
    
    var icon: String {
        switch self {
        case .impressionism: return "paintpalette.fill"
        case .modernArt: return "cube.fill"
        case .classical: return "building.columns.fill"
        case .photography: return "camera.fill"
        case .digital: return "desktopcomputer"
        case .sketches: return "pencil"
        case .paintings: return "paintbrush.fill"
        case .sculptures: return "pyramid.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .impressionism: return .purple
        case .modernArt: return .orange
        case .classical: return .brown
        case .photography: return .gray
        case .digital: return .cyan
        case .sketches: return .black
        case .paintings: return .red
        case .sculptures: return .green
        }
    }
}

enum RadioGenre: String, CaseIterable {
    case oldTimeRadio = "Old Time Radio"
    case talkShows = "Talk Shows"
    case drama = "Drama"
    case comedy = "Comedy"
    case news = "News"
    case educational = "Educational"
    case music = "Music Programs"
    
    var icon: String {
        switch self {
        case .oldTimeRadio: return "radio.fill"
        case .talkShows: return "bubble.left.and.bubble.right.fill"
        case .drama: return "theatermasks.fill"
        case .comedy: return "face.smiling.fill"
        case .news: return "newspaper.fill"
        case .educational: return "book.fill"
        case .music: return "music.note"
        }
    }
    
    var color: Color {
        switch self {
        case .oldTimeRadio: return .brown
        case .talkShows: return .blue
        case .drama: return .purple
        case .comedy: return .yellow
        case .news: return .red
        case .educational: return .green
        case .music: return .orange
        }
    }
}

// MARK: - Content Type
enum ContentType: String, CaseIterable {
    case djSet = "DJ Set"
    case liveConcert = "Live Concert"
    case studioRecording = "Studio Recording"
    case lecture = "Lecture"
    case audiobook = "Audiobook"
    case podcast = "Podcast"
    case documentary = "Documentary"
    case tutorial = "Tutorial"
}

// MARK: - Source Type
enum SourceType: String, CaseIterable {
    case classicSource = "Classic Source"
    case universityArchive = "University Archive"
    case librivox = "LibriVox"
    case publicDomain = "Public Domain"
    case community = "Community Upload"
    case museum = "Museum Collection"
    case library = "Library Archive"
}

// MARK: - Classification Storage Model (Codable)
private struct ContentClassificationStorage: Codable {
    let itemId: String
    var musicGenre: String?
    var audiobookGenre: String?
    var videoGenre: String?
    var artStyle: String?
    var radioGenre: String?
    var contentType: String?
    var sourceType: String?
    var customTags: [String] = []
    var inferredAt: Date = Date()
}

// MARK: - Classification Model
struct ContentClassification {
    let itemId: String
    var musicGenre: MusicGenre?
    var audiobookGenre: AudiobookGenre?
    var videoGenre: VideoGenre?
    var artStyle: ArtStyle?
    var radioGenre: RadioGenre?
    var contentType: ContentType?
    var sourceType: SourceType?
    var customTags: [String] = []
    var inferredAt: Date = Date()
    
    // Computed property to get the appropriate genre based on media type
    func genre(for mediaType: String) -> String? {
        switch mediaType {
        case "Music":
            return musicGenre?.rawValue
        case "Audiobooks":
            return audiobookGenre?.rawValue
        case "Videos":
            return videoGenre?.rawValue
        case "Art":
            return artStyle?.rawValue
        case "Radio":
            return radioGenre?.rawValue
        case "Books":
            return audiobookGenre?.rawValue // Books use audiobook genres
        default:
            return nil
        }
    }
}

// MARK: - Classification Service
class ContentClassificationService: ObservableObject {
    static let shared = ContentClassificationService()
    
    @Published var classifications: [String: ContentClassification] = [:]
    private let classificationsKey = "libritoClassifications"
    
    init() {
        loadClassifications()
    }
    
    // MARK: - Classification Logic
    func classifyItem(_ item: ArchiveOrgService.ArchiveItem, mediaType: String) -> ContentClassification {
        // Check if already classified
        if let existing = classifications[item.id] {
            return existing
        }
        
        // Create new classification
        var classification = ContentClassification(itemId: item.id)
        
        // Infer source type
        classification.sourceType = inferSourceType(from: item)
        
        // Infer content type
        classification.contentType = inferContentType(from: item)
        
        // Classify based on media type
        switch mediaType {
        case "Music":
            classification.musicGenre = inferMusicGenre(from: item)
        case "Audiobooks":
            classification.audiobookGenre = inferAudiobookGenre(from: item)
        case "Videos":
            classification.videoGenre = inferVideoGenre(from: item)
        case "Art":
            classification.artStyle = inferArtStyle(from: item)
        case "Radio":
            classification.radioGenre = inferRadioGenre(from: item)
        case "Books":
            // Books use audiobook genres for now
            classification.audiobookGenre = inferAudiobookGenre(from: item)
        default:
            break
        }
        
        // Store classification - defer to avoid SwiftUI update issues
        DispatchQueue.main.async { [weak self] in
            self?.classifications[item.id] = classification
            self?.saveClassifications()
        }
        
        return classification
    }
    
    // MARK: - Inference Methods
    private func inferSourceType(from item: ArchiveOrgService.ArchiveItem) -> SourceType {
        let title = item.title.lowercased()
        let creator = (item.creator ?? "").lowercased()
        let description = (item.description ?? "").lowercased()
        
        if creator.contains("librivox") || title.contains("librivox") {
            return .librivox
        } else if creator.contains("university") || title.contains("university") {
            return .universityArchive
        } else if creator.contains("museum") || title.contains("museum") {
            return .museum
        } else if creator.contains("library") && !creator.contains("librivox") {
            return .library
        } else if description.contains("public domain") {
            return .publicDomain
        } else if description.contains("community") || creator.contains("community") {
            return .community
        }
        
        return .classicSource
    }
    
    private func inferContentType(from item: ArchiveOrgService.ArchiveItem) -> ContentType {
        let title = item.title.lowercased()
        let description = (item.description ?? "").lowercased()
        
        if title.contains("dj set") || title.contains("mix") || description.contains("dj set") {
            return .djSet
        } else if title.contains("live") || title.contains("concert") {
            return .liveConcert
        } else if title.contains("lecture") || title.contains("talk") {
            return .lecture
        } else if title.contains("audiobook") || description.contains("audiobook") {
            return .audiobook
        } else if title.contains("podcast") {
            return .podcast
        } else if title.contains("documentary") {
            return .documentary
        } else if title.contains("tutorial") || title.contains("how to") {
            return .tutorial
        }
        
        return .studioRecording
    }
    
    private func inferMusicGenre(from item: ArchiveOrgService.ArchiveItem) -> MusicGenre {
        let combined = "\(item.title) \(item.description ?? "") \(item.creator ?? "")".lowercased()
        
        if combined.contains("trance") || combined.contains("psychedelic") {
            return .trance
        } else if combined.contains("jazz") {
            return .jazz
        } else if combined.contains("lo-fi") || combined.contains("lofi") || combined.contains("chill") {
            return .lofi
        } else if combined.contains("ambient") {
            return .ambient
        } else if combined.contains("classical") || combined.contains("orchestra") || combined.contains("symphony") {
            return .classical
        } else if combined.contains("electronic") || combined.contains("techno") || combined.contains("house") {
            return .electronic
        } else if combined.contains("rock") {
            return .rock
        } else if combined.contains("folk") {
            return .folk
        } else if combined.contains("experimental") || combined.contains("avant") {
            return .experimental
        } else if combined.contains("world") || combined.contains("ethnic") {
            return .world
        }
        
        return .classical // Default
    }
    
    private func inferAudiobookGenre(from item: ArchiveOrgService.ArchiveItem) -> AudiobookGenre {
        let combined = "\(item.title) \(item.description ?? "") \(item.creator ?? "")".lowercased()
        
        if combined.contains("philosophy") || combined.contains("stoic") || combined.contains("plato") {
            return .philosophy
        } else if combined.contains("history") || combined.contains("historical") {
            return .history
        } else if combined.contains("science") || combined.contains("physics") || combined.contains("biology") {
            return .science
        } else if combined.contains("poetry") || combined.contains("poems") {
            return .poetry
        } else if combined.contains("self-help") || combined.contains("self help") || combined.contains("improvement") {
            return .selfHelp
        } else if combined.contains("biography") || combined.contains("autobiography") || combined.contains("memoir") {
            return .biography
        } else if combined.contains("mystery") || combined.contains("detective") || combined.contains("crime") {
            return .mystery
        } else if combined.contains("classic") || item.creator?.contains("Shakespeare") == true {
            return .classics
        } else if combined.contains("non-fiction") || combined.contains("nonfiction") {
            return .nonFiction
        }
        
        return .fiction // Default
    }
    
    private func inferVideoGenre(from item: ArchiveOrgService.ArchiveItem) -> VideoGenre {
        let combined = "\(item.title) \(item.description ?? "") \(item.creator ?? "")".lowercased()
        
        if combined.contains("educational") || combined.contains("tutorial") || combined.contains("learn") {
            return .educational
        } else if combined.contains("documentary") {
            return .documentary
        } else if combined.contains("tv") || combined.contains("television") || combined.contains("series") {
            return .classicTV
        } else if combined.contains("animation") || combined.contains("cartoon") || combined.contains("animated") {
            return .animation
        } else if combined.contains("lecture") || combined.contains("presentation") {
            return .lectures
        } else if combined.contains("public access") || combined.contains("community") {
            return .publicAccess
        } else if combined.contains("art") || combined.contains("experimental") {
            return .artFilms
        } else if combined.contains("historical") || combined.contains("history") {
            return .historical
        }
        
        return .classicTV // Default
    }
    
    private func inferArtStyle(from item: ArchiveOrgService.ArchiveItem) -> ArtStyle {
        let combined = "\(item.title) \(item.description ?? "") \(item.creator ?? "")".lowercased()
        
        if combined.contains("impressionism") || combined.contains("impressionist") {
            return .impressionism
        } else if combined.contains("modern") || combined.contains("contemporary") {
            return .modernArt
        } else if combined.contains("classical") || combined.contains("renaissance") {
            return .classical
        } else if combined.contains("photo") || combined.contains("photograph") {
            return .photography
        } else if combined.contains("digital") || combined.contains("computer") {
            return .digital
        } else if combined.contains("sketch") || combined.contains("drawing") {
            return .sketches
        } else if combined.contains("painting") || combined.contains("oil") || combined.contains("watercolor") {
            return .paintings
        } else if combined.contains("sculpture") || combined.contains("statue") {
            return .sculptures
        }
        
        return .paintings // Default
    }
    
    private func inferRadioGenre(from item: ArchiveOrgService.ArchiveItem) -> RadioGenre {
        let combined = "\(item.title) \(item.description ?? "") \(item.creator ?? "")".lowercased()
        
        if combined.contains("old time radio") || combined.contains("otr") || Int(item.date?.prefix(4) ?? "9999") ?? 9999 < 1960 {
            return .oldTimeRadio
        } else if combined.contains("talk") || combined.contains("interview") {
            return .talkShows
        } else if combined.contains("drama") || combined.contains("theater") {
            return .drama
        } else if combined.contains("comedy") || combined.contains("humor") {
            return .comedy
        } else if combined.contains("news") || combined.contains("report") {
            return .news
        } else if combined.contains("educational") || combined.contains("lecture") {
            return .educational
        } else if combined.contains("music") {
            return .music
        }
        
        return .oldTimeRadio // Default
    }
    
    // MARK: - Persistence
    private func saveClassifications() {
        // Convert to storage format
        var storageDict: [String: ContentClassificationStorage] = [:]
        for (key, classification) in classifications {
            let storage = ContentClassificationStorage(
                itemId: classification.itemId,
                musicGenre: classification.musicGenre?.rawValue,
                audiobookGenre: classification.audiobookGenre?.rawValue,
                videoGenre: classification.videoGenre?.rawValue,
                artStyle: classification.artStyle?.rawValue,
                radioGenre: classification.radioGenre?.rawValue,
                contentType: classification.contentType?.rawValue,
                sourceType: classification.sourceType?.rawValue,
                customTags: classification.customTags,
                inferredAt: classification.inferredAt
            )
            storageDict[key] = storage
        }
        
        if let encoded = try? JSONEncoder().encode(storageDict) {
            UserDefaults.standard.set(encoded, forKey: classificationsKey)
        }
    }
    
    private func loadClassifications() {
        if let data = UserDefaults.standard.data(forKey: classificationsKey),
           let decoded = try? JSONDecoder().decode([String: ContentClassificationStorage].self, from: data) {
            // Convert from storage format
            var classificationsDict: [String: ContentClassification] = [:]
            for (key, storage) in decoded {
                let classification = ContentClassification(
                    itemId: storage.itemId,
                    musicGenre: storage.musicGenre.flatMap { MusicGenre(rawValue: $0) },
                    audiobookGenre: storage.audiobookGenre.flatMap { AudiobookGenre(rawValue: $0) },
                    videoGenre: storage.videoGenre.flatMap { VideoGenre(rawValue: $0) },
                    artStyle: storage.artStyle.flatMap { ArtStyle(rawValue: $0) },
                    radioGenre: storage.radioGenre.flatMap { RadioGenre(rawValue: $0) },
                    contentType: storage.contentType.flatMap { ContentType(rawValue: $0) },
                    sourceType: storage.sourceType.flatMap { SourceType(rawValue: $0) },
                    customTags: storage.customTags,
                    inferredAt: storage.inferredAt
                )
                classificationsDict[key] = classification
            }
            classifications = classificationsDict
        }
    }
    
    // MARK: - Filtering
    func itemsForGenre<T: RawRepresentable>(genre: T, in items: [ArchiveOrgService.ArchiveItem], mediaType: String) -> [ArchiveOrgService.ArchiveItem] where T.RawValue == String {
        return items.filter { item in
            let classification = classifyItem(item, mediaType: mediaType)
            return classification.genre(for: mediaType) == genre.rawValue
        }
    }
    
    func itemsForSource(source: SourceType, in items: [ArchiveOrgService.ArchiveItem], mediaType: String) -> [ArchiveOrgService.ArchiveItem] {
        return items.filter { item in
            let classification = classifyItem(item, mediaType: mediaType)
            return classification.sourceType == source
        }
    }
    
    func itemsForContentType(type: ContentType, in items: [ArchiveOrgService.ArchiveItem], mediaType: String) -> [ArchiveOrgService.ArchiveItem] {
        return items.filter { item in
            let classification = classifyItem(item, mediaType: mediaType)
            return classification.contentType == type
        }
    }
}