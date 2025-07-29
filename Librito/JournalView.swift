//
//  JournalView.swift
//  Librito
//
//  Main view for the Journal feature
//

import SwiftUI

struct JournalView: View {
    @StateObject private var journalManager: JournalManager = JournalManager.shared
    @StateObject private var premiumManager: PremiumManager = PremiumManager.shared
    @State private var selectedDocument: JournalDocument?
    @State private var selectedFolder: JournalFolder?
    @State private var searchText = ""
    @State private var showingNewDocument = false
    @State private var showingNewFolder = false
    @State private var showingSidebar = true
    @State private var showingPremiumUpgrade = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar with documents list
            if showingSidebar {
                JournalSidebar(
                    selectedDocument: $selectedDocument,
                    selectedFolder: $selectedFolder,
                    searchText: $searchText,
                    showingNewDocument: $showingNewDocument,
                    showingNewFolder: $showingNewFolder
                )
                .frame(width: 300)
                .background(Color.gray.opacity(0.05))
                
                Divider()
            }
            
            // Main editor area
            if let document = selectedDocument {
                JournalEditor(
                    document: binding(for: document),
                    showingSidebar: $showingSidebar
                )
            } else {
                // Welcome view when no document is selected
                JournalWelcomeView(
                    showingNewDocument: $showingNewDocument
                )
            }
        }
        .sheet(isPresented: $showingNewDocument) {
            NewDocumentSheet { title, paperStyle in
                // Check premium limit before creating
                if journalManager.documents.count >= premiumManager.hasFeature.maxJournalDocuments && !premiumManager.isPremium {
                    showingPremiumUpgrade = true
                } else {
                    let newDoc = journalManager.createDocument(title: title, paperStyle: paperStyle)
                    selectedDocument = newDoc
                }
            }
        }
        .sheet(isPresented: $showingNewFolder) {
            NewFolderSheet { name, emoji in
                _ = journalManager.createFolder(name: name, emoji: emoji)
            }
        }
        .sheet(isPresented: $showingPremiumUpgrade) {
            PremiumUpgradeView()
        }
    }
}

// MARK: - Journal Sidebar
struct JournalSidebar: View {
    @StateObject private var journalManager: JournalManager = JournalManager.shared
    @StateObject private var premiumManager: PremiumManager = PremiumManager.shared
    @Binding var selectedDocument: JournalDocument?
    @Binding var selectedFolder: JournalFolder?
    @Binding var searchText: String
    @Binding var showingNewDocument: Bool
    @Binding var showingNewFolder: Bool
    @State private var showingPremiumUpgrade = false
    
    var filteredDocuments: [JournalDocument] {
        if searchText.isEmpty {
            if let folder = selectedFolder {
                return journalManager.documents(in: folder)
            } else {
                return journalManager.documents
            }
        } else {
            return journalManager.searchDocuments(query: searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Journal")
                    .font(.system(size: 24, weight: .bold))
                
                Spacer()
                
                Button(action: {
                    // Check premium limit
                    if journalManager.documents.count >= premiumManager.hasFeature.maxJournalDocuments && !premiumManager.isPremium {
                        showingPremiumUpgrade = true
                    } else {
                        showingNewDocument = true
                    }
                }) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search documents...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white)
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Pinned documents
                    if !journalManager.pinnedDocuments.isEmpty {
                        Text("Pinned")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        
                        ForEach(journalManager.pinnedDocuments) { document in
                            DocumentRow(
                                document: document,
                                isSelected: selectedDocument?.id == document.id,
                                onTap: { selectedDocument = document }
                            )
                        }
                    }
                    
                    // Folders
                    if !journalManager.folders.isEmpty {
                        HStack {
                            Text("Folders")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Button(action: { showingNewFolder = true }) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        
                        ForEach(journalManager.folders) { folder in
                            JournalFolderRow(
                                folder: folder,
                                isSelected: selectedFolder?.id == folder.id,
                                onTap: { selectedFolder = folder }
                            )
                        }
                    }
                    
                    // Recent documents with count indicator
                    HStack {
                        Text("Recent")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        if !premiumManager.isPremium {
                            Text("\(journalManager.documents.count)/\(premiumManager.hasFeature.maxJournalDocuments)")
                                .font(.system(size: 12))
                                .foregroundColor(journalManager.documents.count >= premiumManager.hasFeature.maxJournalDocuments ? .red : .gray)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    
                    ForEach(filteredDocuments.sorted { $0.modifiedDate > $1.modifiedDate }) { document in
                        if !document.isPinned {
                            DocumentRow(
                                document: document,
                                isSelected: selectedDocument?.id == document.id,
                                onTap: { selectedDocument = document }
                            )
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingPremiumUpgrade) {
            PremiumUpgradeView()
        }
    }
}

// MARK: - Document Row
struct DocumentRow: View {
    let document: JournalDocument
    let isSelected: Bool
    let onTap: () -> Void
    @StateObject private var journalManager = JournalManager.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                if let emoji = document.emoji {
                    Text(emoji)
                        .font(.system(size: 18))
                } else {
                    Image(systemName: "doc.text")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(document.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isSelected ? .white : .black)
                        .lineLimit(1)
                    
                    Text(document.modifiedDate.formatted())
                        .font(.system(size: 12))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .gray)
                }
                
                Spacer()
                
                if document.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 12))
                        .foregroundColor(isSelected ? .white : .orange)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(action: { journalManager.togglePin(document) }) {
                Label(document.isPinned ? "Unpin" : "Pin", systemImage: document.isPinned ? "pin.slash" : "pin")
            }
            
            Button(action: { _ = journalManager.duplicateDocument(document) }) {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            
            Divider()
            
            Button(role: .destructive, action: { journalManager.deleteDocument(document) }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Folder Row
struct JournalFolderRow: View {
    let folder: JournalFolder
    let isSelected: Bool
    let onTap: () -> Void
    @StateObject private var journalManager = JournalManager.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                if let emoji = folder.emoji {
                    Text(emoji)
                        .font(.system(size: 18))
                } else {
                    Image(systemName: "folder")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                
                Text(folder.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : .black)
                
                Spacer()
                
                Text("\(journalManager.documents(in: folder).count)")
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(role: .destructive, action: { journalManager.deleteFolder(folder) }) {
                Label("Delete Folder", systemImage: "trash")
            }
        }
    }
}

// MARK: - Welcome View
struct JournalWelcomeView: View {
    @StateObject private var journalManager: JournalManager = JournalManager.shared
    @StateObject private var premiumManager: PremiumManager = PremiumManager.shared
    @Binding var showingNewDocument: Bool
    @State private var showingPremiumUpgrade = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("📝")
                .font(.system(size: 60))
            
            Text("Welcome to Journal")
                .font(.system(size: 28, weight: .bold))
            
            Text("Create beautiful documents with customizable paper styles")
                .font(.system(size: 18))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                // Check premium limit
                if journalManager.documents.count >= premiumManager.hasFeature.maxJournalDocuments && !premiumManager.isPremium {
                    showingPremiumUpgrade = true
                } else {
                    showingNewDocument = true
                }
            }) {
                HStack {
                    Image(systemName: "square.and.pencil")
                    Text("Create New Document")
                }
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.02))
        .sheet(isPresented: $showingPremiumUpgrade) {
            PremiumUpgradeView()
        }
    }
}

// MARK: - New Document Sheet
struct NewDocumentSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var selectedStyle = PaperStyle.beige
    let onCreate: (String, PaperStyle) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Document Title", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 18))
                
                VStack(alignment: .leading) {
                    Text("Paper Style")
                        .font(.system(size: 16, weight: .medium))
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(PaperStyle.allCases, id: \.self) { style in
                            Button(action: { selectedStyle = style }) {
                                VStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(style.backgroundColor)
                                        .frame(height: 60)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(selectedStyle == style ? Color.blue : Color.clear, lineWidth: 2)
                                        )
                                    
                                    Text(style.displayName)
                                        .font(.system(size: 12))
                                        .foregroundColor(.black)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("New Document")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Create") {
                    onCreate(title.isEmpty ? "Untitled" : title, selectedStyle)
                    dismiss()
                }
                .disabled(false)
            )
        }
    }
}

// MARK: - New Folder Sheet
struct NewFolderSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var selectedEmoji = ""
    let onCreate: (String, String?) -> Void
    
    let emojis = ["📁", "📂", "🗂️", "📋", "📑", "🗄️", "💼", "🎯", "⭐", "🔖", "📌", "💡"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Folder Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 18))
                
                VStack(alignment: .leading) {
                    Text("Choose an emoji (optional)")
                        .font(.system(size: 16, weight: .medium))
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(emojis, id: \.self) { emoji in
                            Button(action: { selectedEmoji = emoji }) {
                                Text(emoji)
                                    .font(.system(size: 24))
                                    .frame(width: 44, height: 44)
                                    .background(selectedEmoji == emoji ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("New Folder")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Create") {
                    onCreate(name, selectedEmoji.isEmpty ? nil : selectedEmoji)
                    dismiss()
                }
                .disabled(name.isEmpty)
            )
        }
    }
}

// MARK: - Helper to create binding for document
extension JournalView {
    func binding(for document: JournalDocument) -> Binding<JournalDocument> {
        Binding<JournalDocument>(
            get: { document },
            set: { newDocument in
                journalManager.updateDocument(newDocument)
                selectedDocument = newDocument
            }
        )
    }
}

#Preview {
    JournalView()
}