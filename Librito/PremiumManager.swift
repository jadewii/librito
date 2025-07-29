//
//  PremiumManager.swift
//  Librito
//
//  Manages premium features and subscriptions
//

import Foundation
import SwiftUI

@MainActor
class PremiumManager: ObservableObject {
    static let shared = PremiumManager()
    
    @Published var isPremium = false
    @Published var hasFeature = Features()
    
    struct Features {
        var canBroadcastNowPlaying = false
        var canUploadUnlimitedTracks = false
        var canAccessPremiumStations = false
        var canDownloadHighQuality = false
        var canRemoveAds = false
        var maxJournalDocuments: Int = 3
        var canExportDocuments = false
        var hasAdvancedSearch = false
        var hasSmartPlaylists = false
        var hasUnlimitedCollections = false
        var hasProfileThemes = false
        var maxOfflinePins: Int = 10
        var hasCrossfade = false
        var hasVariableSpeed = false
        var hasListeningHistory = false
    }
    
    private init() {
        loadPremiumStatus()
    }
    
    func loadPremiumStatus() {
        // In production: Check subscription status
        // For now, default to free tier
        isPremium = UserDefaults.standard.bool(forKey: "isPremium")
        updateFeatures()
    }
    
    func setPremiumStatus(_ premium: Bool) {
        isPremium = premium
        UserDefaults.standard.set(premium, forKey: "isPremium")
        updateFeatures()
    }
    
    private func updateFeatures() {
        hasFeature.canBroadcastNowPlaying = isPremium
        hasFeature.canUploadUnlimitedTracks = isPremium
        hasFeature.canAccessPremiumStations = isPremium
        hasFeature.canDownloadHighQuality = isPremium
        hasFeature.canRemoveAds = isPremium
        hasFeature.maxJournalDocuments = isPremium ? .max : 3
        hasFeature.canExportDocuments = isPremium
        hasFeature.hasAdvancedSearch = isPremium
        hasFeature.hasSmartPlaylists = isPremium
        hasFeature.hasUnlimitedCollections = isPremium
        hasFeature.hasProfileThemes = isPremium
        hasFeature.maxOfflinePins = isPremium ? .max : 10
        hasFeature.hasCrossfade = isPremium
        hasFeature.hasVariableSpeed = isPremium
        hasFeature.hasListeningHistory = isPremium
    }
}

// PremiumUpgradeView is defined in PremiumUpgradeView.swift