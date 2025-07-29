//
//  MyCollectionGridView.swift
//  Librito
//
//  Beautiful grid view for My Collection with playlists/collections
//

import SwiftUI

struct MyCollectionGridView: View {
    @ObservedObject var bookManager: BookManager
    @State private var selectedCollection: BookCollection? = nil
    @State private var showingCreateCollection = false
    @State private var showingAddToCollection = false
    @State private var selectedBooks: Set<UUID> = []
    @State private var isSelectionMode = false
    @State private var searchText = ""
    @State private var showingDocumentPicker = false
    
    // Collections stored in UserDefaults for now
    @State private var collections: [BookCollection] = []
    
    let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 200), spacing: 20)
    ]
    
    var filteredBooks: [Book] {
        let books = selectedCollection?.bookIDs.compactMap { id in
            bookManager.books.first { $0.id == id }
        } ?? bookManager.books
        
        if searchText.isEmpty {
            return books
        } else {
            return books.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.author.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Collections bar
            collectionsBar
            
            // Search bar
            if !isSelectionMode {
                searchBar
            }
            
            // Selection toolbar
            if isSelectionMode {
                selectionToolbar
            }
            
            // Content
            if filteredBooks.isEmpty && selectedCollection == nil {
                emptyStateView
            } else {
                gridContent
            }
        }
        .background(Color(UIColor.systemBackground))
        .onAppear {
            loadCollections()
        }
        .sheet(isPresented: $showingCreateCollection) {
            CreateCollectionView(
                collections: $collections,
                selectedBooks: Array(selectedBooks),
                bookManager: bookManager
            )
        }
        .sheet(isPresented: $showingDocumentPicker) {
            LibritoDocumentPicker(bookManager: bookManager)
        }
    }
    
    private var headerView: some View {
        HStack {
            if selectedCollection != nil {
                Button(action: {
                    selectedCollection = nil
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                        Text("Collections")
                            .font(.system(size: 20, weight: .medium))
                    }
                    .foregroundColor(.primary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Text(selectedCollection?.name ?? "MY COLLECTION")
                .font(.system(size: 28, weight: .heavy))
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: 16) {
                // Selection mode toggle
                Button(action: {
                    withAnimation {
                        isSelectionMode.toggle()
                        if !isSelectionMode {
                            selectedBooks.removeAll()
                        }
                    }
                }) {
                    Image(systemName: isSelectionMode ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.system(size: 24))
                        .foregroundColor(isSelectionMode ? .blue : .primary)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Add content
                Button(action: {
                    showingDocumentPicker = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.primary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
    
    private var collectionsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All items
                CollectionChip(
                    name: "All",
                    icon: "books.vertical.fill",
                    isSelected: selectedCollection == nil,
                    action: {
                        selectedCollection = nil
                    }
                )
                
                // User collections
                ForEach(collections) { collection in
                    CollectionChip(
                        name: collection.name,
                        icon: collection.icon,
                        isSelected: selectedCollection?.id == collection.id,
                        count: collection.bookIDs.count,
                        action: {
                            selectedCollection = collection
                        }
                    )
                    .contextMenu {
                        Button(action: {
                            deleteCollection(collection)
                        }) {
                            Label("Delete Collection", systemImage: "trash")
                        }
                    }
                }
                
                // Create new collection
                Button(action: {
                    if isSelectionMode && !selectedBooks.isEmpty {
                        showingCreateCollection = true
                    } else {
                        // Show alert to select books first
                        isSelectionMode = true
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .medium))
                        Text("New Collection")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(20)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 16)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search your collection...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
    
    private var selectionToolbar: some View {
        HStack {
            Text("\(selectedBooks.count) selected")
                .font(.system(size: 16, weight: .medium))
            
            Spacer()
            
            Button(action: {
                selectedBooks = Set(filteredBooks.map { $0.id })
            }) {
                Text("Select All")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            Button(action: {
                showingCreateCollection = true
            }) {
                Text("Create Collection")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(20)
            }
            .disabled(selectedBooks.isEmpty)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.05))
    }
    
    private var gridContent: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(filteredBooks) { book in
                    BookGridItem(
                        book: book,
                        isSelected: selectedBooks.contains(book.id),
                        isSelectionMode: isSelectionMode,
                        bookManager: bookManager,
                        onTap: {
                            if isSelectionMode {
                                toggleSelection(for: book)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "books.vertical")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("Your Collection is Empty")
                    .font(.system(size: 24, weight: .semibold))
                
                Text("Add books, audiobooks, and more to get started")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                showingDocumentPicker = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("Add Your First Item")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
    }
    
    private func toggleSelection(for book: Book) {
        if selectedBooks.contains(book.id) {
            selectedBooks.remove(book.id)
        } else {
            selectedBooks.insert(book.id)
        }
    }
    
    private func loadCollections() {
        if let data = UserDefaults.standard.data(forKey: "book_collections"),
           let decoded = try? JSONDecoder().decode([BookCollection].self, from: data) {
            collections = decoded
        } else {
            // Create default collections
            collections = [
                BookCollection(name: "Dr. Seuss", icon: "book.closed.fill", bookIDs: []),
                BookCollection(name: "Philosophy", icon: "brain", bookIDs: []),
                BookCollection(name: "Favorites", icon: "star.fill", bookIDs: [])
            ]
            saveCollections()
        }
    }
    
    private func saveCollections() {
        if let encoded = try? JSONEncoder().encode(collections) {
            UserDefaults.standard.set(encoded, forKey: "book_collections")
        }
    }
    
    private func deleteCollection(_ collection: BookCollection) {
        collections.removeAll { $0.id == collection.id }
        saveCollections()
        if selectedCollection?.id == collection.id {
            selectedCollection = nil
        }
    }
}

// MARK: - Book Grid Item
struct BookGridItem: View {
    let book: Book
    let isSelected: Bool
    let isSelectionMode: Bool
    @ObservedObject var bookManager: BookManager
    let onTap: () -> Void
    @State private var showingReader = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Cover/Thumbnail
            ZStack(alignment: .topTrailing) {
                if let coverImage = book.coverImage {
                    coverImage
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 240)
                        .clipped()
                } else {
                    // Placeholder based on file type
                    ZStack {
                        Rectangle()
                            .fill(book.fileType.color.opacity(0.1))
                        
                        VStack(spacing: 8) {
                            Image(systemName: book.fileType.icon)
                                .font(.system(size: 48))
                                .foregroundColor(book.fileType.color)
                            
                            Text(book.fileType.rawValue.uppercased())
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(book.fileType.color.opacity(0.8))
                        }
                    }
                    .frame(height: 240)
                }
                
                // Selection checkbox
                if isSelectionMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .blue : .white)
                        .background(Circle().fill(Color.black.opacity(0.3)))
                        .padding(8)
                }
                
                // Play button for media
                if [Book.FileType.mp3, .m4a, .ogg, .flac].contains(book.fileType) && !isSelectionMode {
                    Button(action: {
                        // Play audio
                    }) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding(8)
                }
            }
            .background(Color.gray.opacity(0.1))
            
            // Info section
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                Text(book.author)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .foregroundColor(.secondary)
                
                if book.progress > 0 {
                    ProgressView(value: book.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: book.fileType.color))
                        .scaleEffect(x: 1, y: 0.5)
                        .padding(.top, 4)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.secondarySystemBackground))
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onTapGesture {
            if isSelectionMode {
                onTap()
            } else {
                showingReader = true
            }
        }
        .sheet(isPresented: $showingReader) {
            BookReaderView(book: book, bookManager: bookManager)
        }
    }
}

// MARK: - Collection Chip
struct CollectionChip: View {
    let name: String
    let icon: String
    let isSelected: Bool
    var count: Int? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                
                Text(name)
                    .font(.system(size: 14, weight: .medium))
                
                if let count = count {
                    Text("(\(count))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Create Collection View
struct CreateCollectionView: View {
    @Binding var collections: [BookCollection]
    let selectedBooks: [UUID]
    @ObservedObject var bookManager: BookManager
    @Environment(\.dismiss) var dismiss
    
    @State private var collectionName = ""
    @State private var selectedIcon = "folder.fill"
    
    let availableIcons = [
        "folder.fill", "star.fill", "heart.fill", "bookmark.fill",
        "book.closed.fill", "music.note", "headphones", "brain",
        "graduationcap.fill", "leaf.fill", "flame.fill", "moon.fill"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Collection Name")
                        .font(.system(size: 16, weight: .medium))
                    
                    TextField("Enter collection name", text: $collectionName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Icon selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose an Icon")
                        .font(.system(size: 16, weight: .medium))
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 16) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button(action: {
                                selectedIcon = icon
                            }) {
                                Image(systemName: icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(selectedIcon == icon ? .white : .primary)
                                    .frame(width: 60, height: 60)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedIcon == icon ? Color.blue : Color.gray.opacity(0.1))
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // Selected books preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(selectedBooks.count) items selected")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(selectedBooks, id: \.self) { bookID in
                                if let book = bookManager.books.first(where: { $0.id == bookID }) {
                                    Text(book.title)
                                        .font(.system(size: 12))
                                        .lineLimit(1)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(16)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createCollection()
                    }
                    .disabled(collectionName.isEmpty)
                }
            }
        }
    }
    
    private func createCollection() {
        let newCollection = BookCollection(
            name: collectionName,
            icon: selectedIcon,
            bookIDs: selectedBooks
        )
        
        collections.append(newCollection)
        
        // Save to UserDefaults
        if let encoded = try? JSONEncoder().encode(collections) {
            UserDefaults.standard.set(encoded, forKey: "book_collections")
        }
        
        dismiss()
    }
}

// MARK: - Book Collection Model
struct BookCollection: Identifiable, Codable {
    let id = UUID()
    var name: String
    var icon: String
    var bookIDs: [UUID]
    var createdDate = Date()
}

#Preview {
    MyCollectionGridView(bookManager: BookManager())
}