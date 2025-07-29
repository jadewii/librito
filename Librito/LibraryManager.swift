//
//  LibraryManager.swift
//  Librito
//
//  Manages the user's local library of books and media
//

import Foundation
import SwiftUI

class LibraryManager: ObservableObject {
    static let shared = LibraryManager()
    
    @Published var items: [LibraryItem] = []
    @Published var isLoading = false
    
    private init() {
        loadLibrary()
    }
    
    // MARK: - LibraryItem Model
    struct LibraryItem: Identifiable, Codable {
        var id = UUID()
        var title: String
        var author: String?
        var identifier: String
        var mediaType: String
        var dateAdded: Date
        var lastOpened: Date?
        var progress: Double = 0
        var localFilePath: String?
        var coverImagePath: String?
        var metadata: [String: String] = [:]
        
        // Archive.org specific
        var archiveIdentifier: String?
        var archiveURL: String?
        
        // Computed properties
        var fileURL: String {
            archiveURL ?? localFilePath ?? ""
        }
        
        var type: String {
            mediaType
        }
    }
    
    // MARK: - Library Management
    func addItem(_ item: LibraryItem) {
        items.append(item)
        saveLibrary()
    }
    
    func removeItem(_ item: LibraryItem) {
        items.removeAll { $0.id == item.id }
        saveLibrary()
    }
    
    func updateItem(_ item: LibraryItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
            saveLibrary()
        }
    }
    
    func updateProgress(for itemId: UUID, progress: Double) {
        if let index = items.firstIndex(where: { $0.id == itemId }) {
            items[index].progress = progress
            items[index].lastOpened = Date()
            saveLibrary()
        }
    }
    
    // MARK: - Persistence
    private var libraryURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                     in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("library.json")
    }
    
    private func saveLibrary() {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: libraryURL)
        } catch {
            print("Failed to save library: \(error)")
        }
    }
    
    private func loadLibrary() {
        guard let data = try? Data(contentsOf: libraryURL),
              let decoded = try? JSONDecoder().decode([LibraryItem].self, from: data) else {
            items = []
            return
        }
        items = decoded
    }
    
    // MARK: - Search and Filter
    func search(query: String) -> [LibraryItem] {
        guard !query.isEmpty else { return items }
        
        let lowercased = query.lowercased()
        return items.filter { item in
            item.title.lowercased().contains(lowercased) ||
            (item.author?.lowercased().contains(lowercased) ?? false)
        }
    }
    
    func filterByMediaType(_ type: String) -> [LibraryItem] {
        items.filter { $0.mediaType == type }
    }
    
    func recentItems(limit: Int = 10) -> [LibraryItem] {
        items.sorted { item1, item2 in
            let date1 = item1.lastOpened ?? item1.dateAdded
            let date2 = item2.lastOpened ?? item2.dateAdded
            return date1 > date2
        }.prefix(limit).map { $0 }
    }
}