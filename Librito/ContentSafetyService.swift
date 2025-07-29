//
//  ContentSafetyService.swift
//  Librito
//
//  Service for ensuring legal compliance with Archive.org content
//

import Foundation

// MARK: - Content Safety Service
class ContentSafetyService: ObservableObject {
    static let shared = ContentSafetyService()
    
    // MARK: - Safe Public Domain Collections
    private let safePublicDomainCollections: Set<String> = [
        "librivoxaudio",
        "ucberkeley", 
        "uiuc",
        "spokenweb",
        "smithsonian",
        "prelinger",
        "oldtimeradio",
        "folklife",
        "ephemera",
        "gutenberg",
        "classiclit",
        "metropolitanmuseumofart-gallery",
        "artsandculture",
        "classic_tv",
        "opensource_movies" // Only for pre-1923 content
    ]
    
    // MARK: - Restricted Collections (Never Allow Premium Features)
    private let restrictedCollections: Set<String> = [
        "opensource_audio",
        "netlabels",
        "community_audio",
        "etree" // Live music recordings - often copyrighted
    ]
    
    // MARK: - Copyright Keywords (Indicate Potential Rights Issues)
    private let copyrightWarningKeywords: [String] = [
        "all rights reserved",
        "no derivative works",
        "no commercial use",
        "copyright",
        "©",
        "(c)",
        "rights reserved",
        "not public domain"
    ]
    
    // MARK: - Public Domain Year Threshold
    private let publicDomainYearThreshold = 1923
    
    init() {}
    
    // MARK: - Main Safety Check
    func isSafeForPremiumFeatures(_ item: ArchiveOrgService.ArchiveItem) -> Bool {
        // Check if item is from a restricted collection
        if isFromRestrictedCollection(item) {
            return false
        }
        
        // Check if item is from a safe public domain collection
        if isFromSafeCollection(item) {
            return true
        }
        
        // Check if item is pre-1923 (clearly public domain)
        if isPrePublicDomainThreshold(item) {
            return true
        }
        
        // Check for explicit copyright warnings
        if hasRightsWarnings(item) {
            return false
        }
        
        // Default to false for safety
        return false
    }
    
    // MARK: - Content Classification
    func getContentSafetyStatus(_ item: ArchiveOrgService.ArchiveItem) -> ContentSafetyStatus {
        if isSafeForPremiumFeatures(item) {
            return .safePublicDomain
        } else if isFromRestrictedCollection(item) || hasRightsWarnings(item) {
            return .restrictedRights
        } else {
            return .greyArea
        }
    }
    
    // MARK: - Helper Methods
    private func isFromSafeCollection(_ item: ArchiveOrgService.ArchiveItem) -> Bool {
        // Extract collection from identifier or description
        let identifier = item.identifier.lowercased()
        let description = (item.description ?? "").lowercased()
        let title = item.title.lowercased()
        
        // Check if any safe collection is mentioned
        return safePublicDomainCollections.contains { collection in
            identifier.contains(collection) || 
            description.contains(collection) ||
            title.contains(collection)
        }
    }
    
    private func isFromRestrictedCollection(_ item: ArchiveOrgService.ArchiveItem) -> Bool {
        let identifier = item.identifier.lowercased()
        let description = (item.description ?? "").lowercased()
        
        return restrictedCollections.contains { collection in
            identifier.contains(collection) || description.contains(collection)
        }
    }
    
    private func isPrePublicDomainThreshold(_ item: ArchiveOrgService.ArchiveItem) -> Bool {
        guard let dateString = item.date else { return false }
        
        // Extract year from various date formats
        let yearRegex = try! NSRegularExpression(pattern: "\\b(18|19)\\d{2}\\b")
        let range = NSRange(location: 0, length: dateString.count)
        
        if let match = yearRegex.firstMatch(in: dateString, range: range) {
            let yearString = String(dateString[Range(match.range, in: dateString)!])
            if let year = Int(yearString) {
                return year < publicDomainYearThreshold
            }
        }
        
        return false
    }
    
    private func hasRightsWarnings(_ item: ArchiveOrgService.ArchiveItem) -> Bool {
        let searchText = "\(item.title) \(item.description ?? "") \(item.creator ?? "")".lowercased()
        
        return copyrightWarningKeywords.contains { keyword in
            searchText.contains(keyword.lowercased())
        }
    }
    
    // MARK: - User-Facing Messages
    func getSafetyMessage(for status: ContentSafetyStatus) -> String {
        switch status {
        case .safePublicDomain:
            return "✅ Public Domain - Premium features available"
        case .greyArea:
            return "⚠️ Uncertain copyright status - Basic streaming only"
        case .restrictedRights:
            return "🚫 Rights restricted - Basic streaming only"
        }
    }
    
    func getSafetyIcon(for status: ContentSafetyStatus) -> String {
        switch status {
        case .safePublicDomain:
            return "checkmark.shield.fill"
        case .greyArea:
            return "exclamationmark.triangle.fill"
        case .restrictedRights:
            return "xmark.shield.fill"
        }
    }
    
    // MARK: - Legal Disclaimer
    static let legalDisclaimer = """
    Librito provides access to materials in the public domain via Archive.org.
    All included content is either:
    • Created before 1923
    • Explicitly labeled as Public Domain  
    • From collections known to be free for public use (e.g. LibriVox)
    
    Librito charges for enhanced tools and presentation — not for the content itself.
    
    Premium features (offline download, enhanced audio, playlists) are only available 
    for verified public domain content to ensure legal compliance.
    """
}

// MARK: - Content Safety Status
enum ContentSafetyStatus {
    case safePublicDomain    // Safe for all premium features
    case greyArea           // Uncertain status - basic access only
    case restrictedRights   // Known rights issues - basic access only
}

// MARK: - Premium Feature Gate
extension ContentSafetyService {
    
    func canDownload(_ item: ArchiveOrgService.ArchiveItem) -> Bool {
        return isSafeForPremiumFeatures(item)
    }
    
    func canAddToPlaylist(_ item: ArchiveOrgService.ArchiveItem) -> Bool {
        return isSafeForPremiumFeatures(item)
    }
    
    func canUseEnhancedAudio(_ item: ArchiveOrgService.ArchiveItem) -> Bool {
        return isSafeForPremiumFeatures(item)
    }
    
    func canUseAIFeatures(_ item: ArchiveOrgService.ArchiveItem) -> Bool {
        return isSafeForPremiumFeatures(item)
    }
}