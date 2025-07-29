//
//  ContentModerationService.swift
//  Librito
//
//  Service for filtering out NSFW and explicit content from Archive.org results
//

import Foundation

class ContentModerationService: ObservableObject {
    static let shared = ContentModerationService()
    
    // MARK: - NSFW/Explicit Content Keywords
    private let explicitKeywords: Set<String> = [
        // Explicit sexual terms
        "porn", "xxx", "sex", "erotic", "nsfw", "nude", "fetish", "boobs", "cum",
        "hentai", "blowjob", "masturbation", "anal", "threesome", "orgy", "incest",
        "bdsm", "camgirl", "amateur", "gay porn", "lesbian", "onlyfans", "shemale",
        
        // Additional adult content keywords
        "pornography", "explicit", "adult", "18+", "mature", "sexual", "intimate",
        "naked", "topless", "lingerie", "bikini model", "strip", "seduction",
        "orgasm", "climax", "foreplay", "kinky", "sensual", "provocative",
        
        // Platform-specific terms
        "xhamster", "pornhub", "redtube", "youporn", "xvideos", "chaturbate",
        
        // Euphemisms and slang
        "naughty", "dirty", "hot girls", "sexy", "milf", "dilf", "daddy",
        "barely legal", "teen sex", "college girls", "hookup", "booty call",
        
        // LGBTQ+ explicit terms (keeping respectful general terms)
        "gay sex", "lesbian sex", "trans sex", "queer sex",
        
        // Adult industry terms
        "escort", "prostitute", "call girl", "sugar baby", "webcam",
        "live cam", "chat room", "dating app", "hookup app"
    ]
    
    // MARK: - Problematic Collections
    private let adultCollections: Set<String> = [
        "adult",
        "erotica", 
        "explicit",
        "mature",
        "nsfw",
        "pornography",
        "sexeducation", // Could contain explicit material
        "dating",
        "relationships" // Often contains adult content
    ]
    
    init() {}
    
    // MARK: - Main Filtering Function
    func filterExplicitContent(_ items: [ArchiveOrgService.ArchiveItem]) -> [ArchiveOrgService.ArchiveItem] {
        return items.filter { item in
            !containsExplicitContent(item)
        }
    }
    
    // MARK: - Content Analysis
    private func containsExplicitContent(_ item: ArchiveOrgService.ArchiveItem) -> Bool {
        // Combine all text fields for analysis
        let searchableText = [
            item.title,
            item.description ?? "",
            item.creator ?? "",
            item.identifier
        ].joined(separator: " ").lowercased()
        
        // Check for explicit keywords
        if containsExplicitKeywords(searchableText) {
            return true
        }
        
        // Check collection name
        if isFromAdultCollection(item) {
            return true
        }
        
        // Check for suspicious patterns
        if containsSuspiciousPatterns(searchableText) {
            return true
        }
        
        return false
    }
    
    // MARK: - Keyword Detection
    private func containsExplicitKeywords(_ text: String) -> Bool {
        let words = text.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .map { $0.lowercased() }
        
        // Check individual words
        for word in words {
            if explicitKeywords.contains(word) {
                return true
            }
        }
        
        // Check for multi-word phrases
        let fullText = text.lowercased()
        for keyword in explicitKeywords {
            if keyword.contains(" ") && fullText.contains(keyword) {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Collection Analysis
    private func isFromAdultCollection(_ item: ArchiveOrgService.ArchiveItem) -> Bool {
        let identifier = item.identifier.lowercased()
        
        return adultCollections.contains { collection in
            identifier.contains(collection)
        }
    }
    
    // MARK: - Pattern Detection
    private func containsSuspiciousPatterns(_ text: String) -> Bool {
        // Pattern 1: Multiple X's (xxx, xxxx)
        if text.range(of: "x{3,}", options: .regularExpression) != nil {
            return true
        }
        
        // Pattern 2: Numbers suggesting age + explicit context
        let ageExplicitPattern = "\\b(18|19|20|21)\\b.*(hot|sexy|young|teen)"
        if text.range(of: ageExplicitPattern, options: .regularExpression) != nil {
            return true
        }
        
        // Pattern 3: Repeated adult-adjacent words
        let suspiciousWords = ["hot", "sexy", "wild", "naughty", "steamy"]
        var suspiciousCount = 0
        for word in suspiciousWords {
            if text.contains(word) {
                suspiciousCount += 1
            }
        }
        if suspiciousCount >= 2 {
            return true
        }
        
        // Pattern 4: Dating/hookup patterns
        let datingPattern = "\\b(meet|chat|date|hookup)\\b.*(single|available|tonight)"
        if text.range(of: datingPattern, options: .regularExpression) != nil {
            return true
        }
        
        return false
    }
    
    // MARK: - Content Rating
    func getContentRating(_ item: ArchiveOrgService.ArchiveItem) -> ContentRating {
        if containsExplicitContent(item) {
            return .explicit
        }
        
        // Check for potentially mature content
        let text = "\(item.title) \(item.description ?? "")".lowercased()
        let matureKeywords = ["violence", "drug", "alcohol", "mature themes", "adult themes"]
        
        for keyword in matureKeywords {
            if text.contains(keyword) {
                return .mature
            }
        }
        
        return .familyFriendly
    }
    
    // MARK: - Statistics
    func getFilteringStats(original: [ArchiveOrgService.ArchiveItem], filtered: [ArchiveOrgService.ArchiveItem]) -> ContentFilteringStats {
        let originalCount = original.count
        let filteredCount = filtered.count
        let removedCount = originalCount - filteredCount
        let removalRate = originalCount > 0 ? Double(removedCount) / Double(originalCount) : 0.0
        
        return ContentFilteringStats(
            originalCount: originalCount,
            filteredCount: filteredCount,
            removedCount: removedCount,
            removalRate: removalRate
        )
    }
}

// MARK: - Supporting Types
enum ContentRating {
    case familyFriendly
    case mature
    case explicit
    
    var displayName: String {
        switch self {
        case .familyFriendly: return "Family Friendly"
        case .mature: return "Mature"
        case .explicit: return "Explicit"
        }
    }
    
    var color: String {
        switch self {
        case .familyFriendly: return "green"
        case .mature: return "orange" 
        case .explicit: return "red"
        }
    }
}

struct ContentFilteringStats {
    let originalCount: Int
    let filteredCount: Int
    let removedCount: Int
    let removalRate: Double
    
    var removalPercentage: String {
        return String(format: "%.1f%%", removalRate * 100)
    }
}