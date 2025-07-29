//
//  MyLibraryContentView.swift
//  Librito
//
//  Content view for personal media library
//

import SwiftUI
import UniformTypeIdentifiers

struct MyLibraryContentView: View {
    @ObservedObject var bookManager: BookManager
    @Binding var selectedMediaType: MediaType
    @State private var searchText = ""
    @State private var showingDocumentPicker = false
    @State private var selectedBook: Book? = nil
    @State private var showingAudioPlayer = false
    
    var filteredBooks: [Book] {
        var filtered: [Book] = []
        
        switch selectedMediaType {
        case .audiobooks:
            filtered = bookManager.books.filter { 
                $0.fileType == .mp3 || 
                $0.fileType == .m4a ||
                $0.fileType == .ogg ||
                $0.fileType == .flac ||
                $0.fileName.lowercased().contains("audio") ||
                $0.fileName.lowercased().hasSuffix(".m4b")
            }
        case .books:
            filtered = bookManager.books.filter { 
                $0.fileType == .pdf || $0.fileType == .epub || $0.fileType == .txt 
            }
        case .music:
            filtered = bookManager.books.filter { 
                $0.fileType == .mp3 || 
                $0.fileType == .m4a ||
                $0.fileType == .ogg ||
                $0.fileType == .flac ||
                $0.fileName.lowercased().contains("music")
            }
        case .radio:
            // Radio is streaming only, no local files
            filtered = []
        case .journal:
            // Journal is document-based, no local media files
            filtered = []
        default:
            filtered = bookManager.books
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.author.localizedCaseInsensitiveContains(searchText) ||
                $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return filtered
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header with search and upload
                VStack(spacing: 16) {
                HStack {
                    if selectedBook != nil {
                        Button(action: {
                            selectedBook = nil
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 23, weight: .medium))
                                Text("Back")
                                    .font(.system(size: 23, weight: .medium))
                            }
                            .foregroundColor(.black)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        HStack {
                            Text("MY COLLECTION")
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
                        }
                    }
                    
                    Spacer()
                    
                    if selectedBook == nil {
                        HStack(spacing: 16) {
                            Button(action: {
                                showingDocumentPicker = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.black)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                bookManager.cleanupBrokenBooks()
                            }) {
                                Image(systemName: "trash.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // Search Bar (only show when not playing audio)
                if selectedBook == nil {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search your library...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 20)
            
            // Content Grid
            if selectedMediaType == .radio {
                RadioContentView()
            } else if filteredBooks.isEmpty {
                EmptyMyLibraryView(mediaType: selectedMediaType, showingDocumentPicker: $showingDocumentPicker)
            } else {
                if let selectedBook = selectedBook {
                    // Show media viewer filling the content area
                    if [Book.FileType.mp3, .m4a, .ogg, .flac].contains(selectedBook.fileType),
                       let filePath = selectedBook.filePath {
                        AudioPlayerView(filePath: filePath, book: selectedBook, bookManager: bookManager)
                    } else if selectedBook.fileType == .pdf {
                        InlinePDFReaderView(book: selectedBook, bookManager: bookManager)
                    } else {
                        // For other file types, show them in the grid
                        BookGridView(filteredBooks: filteredBooks, selectedBook: $selectedBook, bookManager: bookManager)
                    }
                } else {
                    // Use the filtered grid for audiobooks tab
                    if selectedMediaType == .audiobooks {
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 180, maximum: 200), spacing: 20)
                            ], spacing: 20) {
                                ForEach(filteredBooks) { book in
                                    AudiobookGridItem(
                                        book: book,
                                        bookManager: bookManager,
                                        onTap: {
                                            selectedBook = book
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 40)
                        }
                    } else {
                        MyCollectionGridView(bookManager: bookManager)
                    }
                }
            }
        }
        .background(Color.white)
        }
        .sheet(isPresented: $showingDocumentPicker) {
            LibritoDocumentPicker(bookManager: bookManager)
        }
    }
}

// MARK: - Book Grid View
struct BookGridView: View {
    let filteredBooks: [Book]
    @Binding var selectedBook: Book?
    @ObservedObject var bookManager: BookManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredBooks) { book in
                    ZStack {
                        BookCard(book: book, bookManager: bookManager)
                        
                        // Invisible overlay for tap detection
                        if [Book.FileType.mp3, .m4a, .ogg, .flac, .pdf].contains(book.fileType) {
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    self.selectedBook = book
                                }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Empty State
struct EmptyMyLibraryView: View {
    let mediaType: MediaType
    @Binding var showingDocumentPicker: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text(mediaType.displayName)
                .font(.system(size: 48))
                .padding(.bottom, 8)
            
            VStack(spacing: 8) {
                Text("No \(mediaType.rawValue.capitalized) Yet")
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundColor(.black)
                
                Text("Upload your first \(mediaType.rawValue.lowercased()) file to get started")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: {
                showingDocumentPicker = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 23))
                    Text("Upload \(mediaType.rawValue.capitalized)")
                        .font(.system(size: 20, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.black)
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
    }
}

// MARK: - Document Picker for Uploads
struct LibritoDocumentPicker: UIViewControllerRepresentable {
    @ObservedObject var bookManager: BookManager
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.pdf, .epub, .text, .data, .audio, .movie, .image]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: LibritoDocumentPicker
        
        init(_ parent: LibritoDocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            for url in urls {
                guard url.startAccessingSecurityScopedResource() else { continue }
                defer { url.stopAccessingSecurityScopedResource() }
                
                do {
                    let fileData = try Data(contentsOf: url)
                    let fileName = url.lastPathComponent
                    
                    // Extract title and author from filename
                    let nameWithoutExtension = url.deletingPathExtension().lastPathComponent
                    let components = nameWithoutExtension.components(separatedBy: " - ")
                    
                    let title = components.first ?? nameWithoutExtension
                    let author = components.count > 1 ? components[1] : "Unknown Author"
                    
                    // Add to library with a generic mode
                    _ = parent.bookManager.addBook(
                        title: title,
                        author: author,
                        fileData: fileData,
                        fileName: fileName,
                        mode: "library" // Generic mode for Librito
                    )
                } catch {
                    print("Error reading file: \(error)")
                }
            }
            
            parent.dismiss()
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}

// MARK: - Radio Content (Placeholder)
struct RadioContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("📻")
                .font(.system(size: 48))
            
            Text("Radio Player")
                .font(.system(size: 25, weight: .semibold))
                .foregroundColor(.black)
            
            Text("Stream live radio from Archive.org")
                .font(.system(size: 18))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
    }
}

// MARK: - Audiobook Grid Item
struct AudiobookGridItem: View {
    let book: Book
    @ObservedObject var bookManager: BookManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Cover/Thumbnail with proper Archive.org support
                ZStack(alignment: .bottomTrailing) {
                    if let coverImage = book.coverImage {
                        coverImage
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 240)
                            .clipped()
                    } else if book.fileName.contains("archive.org") || book.tags.contains("archive.org") {
                        // Try to extract identifier from filename for Archive.org items
                        AsyncImage(url: extractArchiveOrgThumbnail(from: book)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            audiobookPlaceholder
                        }
                        .frame(height: 240)
                        .clipped()
                    } else {
                        audiobookPlaceholder
                            .frame(height: 240)
                    }
                    
                    // Audio indicator
                    Image(systemName: "headphones.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                        .background(Circle().fill(Color.black.opacity(0.7)))
                        .padding(8)
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
                        HStack(spacing: 4) {
                            ProgressView(value: book.progress)
                                .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                                .scaleEffect(x: 1, y: 0.5)
                            
                            Text("\(book.progressPercentage)%")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemBackground))
            }
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var audiobookPlaceholder: some View {
        ZStack {
            Rectangle()
                .fill(Color.purple.opacity(0.1))
            
            VStack(spacing: 8) {
                Image(systemName: "headphones")
                    .font(.system(size: 48))
                    .foregroundColor(.purple)
                
                Text("AUDIOBOOK")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.purple.opacity(0.8))
            }
        }
    }
    
    private func extractArchiveOrgThumbnail(from book: Book) -> URL? {
        // Try to extract Archive.org identifier from various sources
        if let identifier = book.tags.first(where: { $0.hasPrefix("archive:") })?.replacingOccurrences(of: "archive:", with: "") {
            return URL(string: "https://archive.org/services/img/\(identifier)")
        }
        
        // Try from filename patterns
        let filename = book.fileName
        if filename.contains("_") {
            let components = filename.components(separatedBy: "_")
            if let identifier = components.first {
                return URL(string: "https://archive.org/services/img/\(identifier)")
            }
        }
        
        return nil
    }
}

#Preview {
    MyLibraryContentView(
        bookManager: BookManager(),
        selectedMediaType: .constant(.books)
    )
}