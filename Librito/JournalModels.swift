//
//  JournalModels.swift
//  Librito
//
//  Data models for the Journal feature
//

import Foundation
import SwiftUI

// MARK: - Journal Document Model
struct JournalDocument: Identifiable, Codable {
    var id = UUID()
    var title: String
    var content: String
    var createdDate: Date
    var modifiedDate: Date
    var paperStyle: PaperStyle
    var tags: [String]
    var emoji: String?
    var isPinned: Bool
    var folderId: UUID?
    
    init(title: String = "Untitled", content: String = "", paperStyle: PaperStyle = .beige) {
        self.title = title
        self.content = content
        self.createdDate = Date()
        self.modifiedDate = Date()
        self.paperStyle = paperStyle
        self.tags = []
        self.isPinned = false
    }
}

// MARK: - Paper Style
enum PaperStyle: String, CaseIterable, Codable {
    case beige = "beige"
    case blushPink = "blushPink"
    case mintGreen = "mintGreen"
    case softLilac = "softLilac"
    case skyBlue = "skyBlue"
    case peach = "peach"
    
    var displayName: String {
        switch self {
        case .beige: return "Beige"
        case .blushPink: return "Blush Pink"
        case .mintGreen: return "Mint Green"
        case .softLilac: return "Soft Lilac"
        case .skyBlue: return "Sky Blue"
        case .peach: return "Peach"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .beige: return Color(red: 0.96, green: 0.94, blue: 0.89)
        case .blushPink: return Color(red: 0.99, green: 0.94, blue: 0.95)
        case .mintGreen: return Color(red: 0.93, green: 0.98, blue: 0.94)
        case .softLilac: return Color(red: 0.95, green: 0.93, blue: 0.98)
        case .skyBlue: return Color(red: 0.93, green: 0.97, blue: 0.99)
        case .peach: return Color(red: 0.99, green: 0.95, blue: 0.91)
        }
    }
}

// MARK: - Journal Folder
struct JournalFolder: Identifiable, Codable {
    var id = UUID()
    var name: String
    var emoji: String?
    var createdDate: Date
    
    init(name: String, emoji: String? = nil) {
        self.name = name
        self.emoji = emoji
        self.createdDate = Date()
    }
}

// MARK: - Journal Manager
class JournalManager: ObservableObject {
    static let shared = JournalManager()
    
    @Published var documents: [JournalDocument] = []
    @Published var folders: [JournalFolder] = []
    
    private let documentsKey = "librito_journal_documents"
    private let foldersKey = "librito_journal_folders"
    
    init() {
        loadDocuments()
        loadFolders()
    }
    
    // MARK: - Document Management
    func createDocument(title: String = "Untitled", paperStyle: PaperStyle = .beige) -> JournalDocument {
        let document = JournalDocument(title: title, paperStyle: paperStyle)
        documents.append(document)
        saveDocuments()
        return document
    }
    
    func updateDocument(_ document: JournalDocument) {
        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            documents[index] = document
            documents[index].modifiedDate = Date()
            saveDocuments()
        }
    }
    
    func deleteDocument(_ document: JournalDocument) {
        documents.removeAll { $0.id == document.id }
        saveDocuments()
    }
    
    func duplicateDocument(_ document: JournalDocument) -> JournalDocument {
        var newDocument = document
        newDocument.id = UUID()
        newDocument.title = "\(document.title) (Copy)"
        newDocument.createdDate = Date()
        newDocument.modifiedDate = Date()
        documents.append(newDocument)
        saveDocuments()
        return newDocument
    }
    
    func togglePin(_ document: JournalDocument) {
        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            documents[index].isPinned.toggle()
            saveDocuments()
        }
    }
    
    // MARK: - Folder Management
    func createFolder(name: String, emoji: String? = nil) -> JournalFolder {
        let folder = JournalFolder(name: name, emoji: emoji)
        folders.append(folder)
        saveFolders()
        return folder
    }
    
    func deleteFolder(_ folder: JournalFolder) {
        // Move all documents from this folder to root
        for index in documents.indices {
            if documents[index].folderId == folder.id {
                documents[index].folderId = nil
            }
        }
        folders.removeAll { $0.id == folder.id }
        saveFolders()
        saveDocuments()
    }
    
    // MARK: - Filtering
    func documents(in folder: JournalFolder?) -> [JournalDocument] {
        if let folder = folder {
            return documents.filter { $0.folderId == folder.id }
        } else {
            return documents.filter { $0.folderId == nil }
        }
    }
    
    var pinnedDocuments: [JournalDocument] {
        documents.filter { $0.isPinned }.sorted { $0.modifiedDate > $1.modifiedDate }
    }
    
    var recentDocuments: [JournalDocument] {
        documents.sorted { $0.modifiedDate > $1.modifiedDate }.prefix(5).map { $0 }
    }
    
    // MARK: - Search
    func searchDocuments(query: String) -> [JournalDocument] {
        guard !query.isEmpty else { return documents }
        let lowercased = query.lowercased()
        return documents.filter { document in
            document.title.lowercased().contains(lowercased) ||
            document.content.lowercased().contains(lowercased) ||
            document.tags.contains { $0.lowercased().contains(lowercased) }
        }
    }
    
    // MARK: - Persistence
    private func saveDocuments() {
        if let encoded = try? JSONEncoder().encode(documents) {
            UserDefaults.standard.set(encoded, forKey: documentsKey)
        }
    }
    
    private func loadDocuments() {
        if let data = UserDefaults.standard.data(forKey: documentsKey),
           let decoded = try? JSONDecoder().decode([JournalDocument].self, from: data) {
            documents = decoded
        }
    }
    
    private func saveFolders() {
        if let encoded = try? JSONEncoder().encode(folders) {
            UserDefaults.standard.set(encoded, forKey: foldersKey)
        }
    }
    
    private func loadFolders() {
        if let data = UserDefaults.standard.data(forKey: foldersKey),
           let decoded = try? JSONDecoder().decode([JournalFolder].self, from: data) {
            folders = decoded
        }
    }
}