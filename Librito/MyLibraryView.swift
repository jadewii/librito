//
//  MyLibraryView.swift
//  Librito
//
//  Library view for browsing and managing books/PDFs
//

import SwiftUI
import UniformTypeIdentifiers

struct MyLibraryView: View {
    @ObservedObject var bookManager: BookManager
    @State private var selectedFilter: LibraryFilter = .all
    @State private var searchText = ""
    @State private var showingAddBook = false
    @State private var showingDocumentPicker = false
    @State private var showingArchiveSearch = false
    
    enum ActiveSheet: Identifiable {
        case documentPicker, archiveSearch
        
        var id: String {
            switch self {
            case .documentPicker: return "documentPicker"
            case .archiveSearch: return "archiveSearch"
            }
        }
    }
    @State private var activeSheet: ActiveSheet? = nil
    
    enum LibraryFilter: String, CaseIterable {
        case all = "All"
        case books = "Books"
        case audiobooks = "Audiobooks"
        case music = "Music"
        case videos = "Videos"
        
        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .books: return "book.fill"
            case .audiobooks: return "headphones"
            case .music: return "music.note"
            case .videos: return "play.rectangle.fill"
            }
        }
    }
    
    var filteredBooks: [Book] {
        var filtered: [Book] = []
        switch selectedFilter {
        case .all:
            filtered = bookManager.books
        case .books:
            filtered = bookManager.books.filter { $0.fileType == .pdf || $0.fileType == .epub || $0.fileType == .txt }
        case .audiobooks:
            filtered = bookManager.books.filter { 
                $0.fileName.lowercased().contains("audio") || 
                $0.fileName.lowercased().hasSuffix(".mp3") ||
                $0.fileName.lowercased().hasSuffix(".m4b")
            }
        case .music:
            filtered = bookManager.books.filter { 
                $0.fileName.lowercased().hasSuffix(".mp3") ||
                $0.fileName.lowercased().hasSuffix(".m4a") ||
                $0.fileName.lowercased().contains("music")
            }
        case .videos:
            filtered = bookManager.books.filter { 
                $0.fileName.lowercased().hasSuffix(".mp4") ||
                $0.fileName.lowercased().hasSuffix(".mov") ||
                $0.fileName.lowercased().contains("video")
            }
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
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    Text("MY COLLECTION")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            activeSheet = .archiveSearch
                        }) {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.black)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            activeSheet = .documentPicker
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.black)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            bookManager.cleanupBrokenBooks()
                        }) {
                            Image(systemName: "trash.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search books...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Filter Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(LibraryFilter.allCases, id: \.self) { filter in
                            FilterTab(
                                filter: filter,
                                isSelected: selectedFilter == filter,
                                color: .black,
                                action: { selectedFilter = filter }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .padding(.bottom, 20)
            
            // Books Grid
            if filteredBooks.isEmpty {
                EmptyLibraryView(
                    filter: selectedFilter,
                    modeColor: .black,
                    activeSheet: $activeSheet
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredBooks) { book in
                            BookCard(book: book, bookManager: bookManager)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .background(Color.white)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .documentPicker:
                DocumentPicker(bookManager: bookManager, currentMode: "library")
            case .archiveSearch:
                SimpleArchiveSearchView(
                    bookManager: bookManager, 
                    currentMode: "library",
                    mediaType: selectedFilter == .audiobooks ? "audio" : 
                              selectedFilter == .videos ? "movies" : 
                              selectedFilter == .music ? "audio" : nil
                )
            }
        }
    }
}

struct FilterTab: View {
    let filter: MyLibraryView.LibraryFilter
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: filter.icon)
                    .font(.system(size: 16))
                
                Text(filter.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .black)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color.gray.opacity(0.1))
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyLibraryView: View {
    let filter: MyLibraryView.LibraryFilter
    let modeColor: Color
    @Binding var activeSheet: MyLibraryView.ActiveSheet?
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: filter.icon)
                .font(.system(size: 60))
                .foregroundColor(modeColor.opacity(0.3))
            
            VStack(spacing: 8) {
                Text(getEmptyTitle())
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(getEmptyMessage())
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if filter == .all {
                VStack(spacing: 12) {
                    Button(action: {
                        activeSheet = .archiveSearch
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 18))
                            Text("Search Online")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(modeColor)
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        activeSheet = .documentPicker
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                            Text("Upload PDF/eBook")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(modeColor)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(modeColor, lineWidth: 2)
                        )
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Spacer()
        }
    }
    
    private func getEmptyTitle() -> String {
        switch filter {
        case .all:
            return "No Items Yet"
        case .books:
            return "No Books"
        case .audiobooks:
            return "No Audiobooks"
        case .music:
            return "No Music"
        case .videos:
            return "No Videos"
        }
    }
    
    private func getEmptyMessage() -> String {
        switch filter {
        case .all:
            return "Upload or search for content to start building your library"
        case .books:
            return "Search for books or upload PDFs and eBooks"
        case .audiobooks:
            return "Search for audiobooks to listen to"
        case .music:
            return "Search for music to add to your collection"
        case .videos:
            return "Search for educational videos"
        }
    }
}

// MARK: - Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    @ObservedObject var bookManager: BookManager
    let currentMode: String
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.pdf, .epub, .text, .data]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let fileData = try Data(contentsOf: url)
                let fileName = url.lastPathComponent
                
                // Extract title and author from filename
                let nameWithoutExtension = url.deletingPathExtension().lastPathComponent
                let components = nameWithoutExtension.components(separatedBy: " - ")
                
                let title = components.first ?? nameWithoutExtension
                let author = components.count > 1 ? components[1] : "Unknown Author"
                
                // Add book to manager
                _ = parent.bookManager.addBook(
                    title: title,
                    author: author,
                    fileData: fileData,
                    fileName: fileName,
                    mode: parent.currentMode
                )
                
                parent.dismiss()
            } catch {
                print("Error reading file: \(error)")
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}


struct MiniBookRow: View {
    let book: Book
    @ObservedObject var bookManager: BookManager
    @State private var showingReader = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Mini cover
            ZStack {
                if let coverImage = book.coverImage {
                    coverImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(book.fileType.color.opacity(0.2))
                        .overlay(
                            Image(systemName: book.fileType.icon)
                                .font(.system(size: 16))
                                .foregroundColor(book.fileType.color)
                        )
                }
            }
            .frame(width: 40, height: 60)
            .cornerRadius(4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                if book.progress > 0 {
                    HStack(spacing: 4) {
                        ProgressView(value: book.progress)
                            .progressViewStyle(LinearProgressViewStyle())
                            .scaleEffect(x: 1, y: 0.5)
                        
                        Text("\(book.progressPercentage)%")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                } else {
                    Text(book.author)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Button(action: {
                showingReader = true
            }) {
                Image(systemName: "book.fill")
                    .font(.system(size: 14))
                    .foregroundColor(book.fileType.color)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(8)
        .background(Color.white)
        .cornerRadius(8)
        .sheet(isPresented: $showingReader) {
            BookReaderView(book: book, bookManager: bookManager)
        }
    }
}

// MARK: - Simple Archive Search View
struct SimpleArchiveSearchView: View {
    @ObservedObject var bookManager: BookManager
    let currentMode: String
    var mediaType: String? = nil
    @Environment(\.dismiss) var dismiss
    @State private var searchQuery = ""
    @StateObject private var archiveService = ArchiveOrgService.shared
    @State private var hasSearched = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search for books...", text: $searchQuery)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onSubmit {
                            searchArchive()
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
                .padding(.horizontal)
                
                if archiveService.isLoading {
                    ProgressView("Searching Archive.org...")
                        .padding(.top, 50)
                    Spacer()
                } else if archiveService.searchResults.isEmpty && hasSearched && !searchQuery.isEmpty {
                    VStack(spacing: 20) {
                        Text("No results found")
                            .foregroundColor(.gray)
                            .padding(.top, 50)
                        
                        if let error = archiveService.error {
                            Text("Error: \(error)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    Spacer()
                } else if !archiveService.searchResults.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(archiveService.searchResults) { item in
                                MyLibraryArchiveItemRow(item: item, bookManager: bookManager, currentMode: currentMode)
                            }
                        }
                        .padding()
                    }
                } else {
                    VStack(spacing: 20) {
                        Text("Search Archive.org")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Find free educational books, textbooks, and study materials")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 40)
                        
                        // Quick search suggestions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Try searching for:")
                                .font(.headline)
                            
                            ForEach(["Marcus Aurelius Meditations", "Seneca Letters", "Epictetus Discourses", "Plato Republic", "Aristotle Ethics", "Stoic Philosophy"], id: \.self) { subject in
                                Button(action: {
                                    searchQuery = subject
                                    searchArchive()
                                }) {
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 14))
                                        Text(subject)
                                            .font(.system(size: 16))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                    }
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 30)
                    }
                    Spacer()
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func searchArchive() {
        guard !searchQuery.isEmpty else { return }
        hasSearched = true
        
        // Clear previous results
        archiveService.searchResults = []
        
        // Trigger the search with media type if specified
        archiveService.search(query: searchQuery, mediaType: mediaType)
    }
}

// MARK: - Archive Item Row
struct MyLibraryArchiveItemRow: View {
    let item: ArchiveOrgService.ArchiveItem
    @ObservedObject var bookManager: BookManager
    let currentMode: String
    @State private var isDownloading = false
    @State private var downloadComplete = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @Environment(\.dismiss) var dismiss
    @StateObject private var downloadManager = DownloadManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            AsyncImage(url: URL(string: "https://archive.org/services/img/\(item.identifier)")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Image(systemName: "book.fill")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 60, height: 80)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 16, weight: .medium))
                    .lineLimit(2)
                
                if let creator = item.creator {
                    Text(creator)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                HStack {
                    if let date = item.date {
                        Text(date)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    if downloadComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 24))
                    } else if isDownloading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Button(action: {
                            downloadBook()
                        }) {
                            Text("Download")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .cornerRadius(6)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .alert(downloadComplete ? "Download Complete" : "Download Failed", isPresented: $showingAlert) {
            Button("OK") { 
                if downloadComplete {
                    dismiss()
                }
                showingAlert = false
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func downloadBook() {
        print("Download button pressed for: \(item.title)")
        isDownloading = true
        
        // Use the downloadItem method with completion handler
        ArchiveOrgService.shared.downloadItem(item) { url in
            print("Download URL received: \(url?.absoluteString ?? "nil")")
            guard let downloadURL = url else {
                print("No download URL found")
                DispatchQueue.main.async {
                    self.isDownloading = false
                    self.alertMessage = "No downloadable file found for this item"
                    self.showingAlert = true
                }
                return
            }
            
            // Download the file
            print("Starting download from: \(downloadURL)")
            URLSession.shared.downloadTask(with: downloadURL) { tempURL, _, error in
                if let error = error {
                    print("Download error: \(error)")
                    DispatchQueue.main.async {
                        self.isDownloading = false
                    }
                    return
                }
                
                guard let tempURL = tempURL else {
                    print("No temp URL received")
                    DispatchQueue.main.async {
                        self.isDownloading = false
                    }
                    return
                }
                
                print("File downloaded to temp URL: \(tempURL)")
                
                do {
                    let fileData = try Data(contentsOf: tempURL)
                    print("File data loaded, size: \(fileData.count) bytes")
                    DispatchQueue.main.async {
                        let book = self.bookManager.addBook(
                            title: self.item.title,
                            author: self.item.creator ?? "Unknown Author",
                            fileData: fileData,
                            fileName: downloadURL.lastPathComponent,
                            mode: self.currentMode
                        )
                        print("Book added: \(book?.title ?? "Failed to add")")
                        self.isDownloading = false
                        self.downloadComplete = true
                        self.alertMessage = "'\(self.item.title)' has been added to your library"
                        self.showingAlert = true
                    }
                } catch {
                    print("Error reading file data: \(error)")
                    DispatchQueue.main.async {
                        self.isDownloading = false
                    }
                }
            }.resume()
        }
    }
}