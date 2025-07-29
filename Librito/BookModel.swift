//
//  BookModel.swift
//  Librito
//
//  Book and media model for library system
//

import SwiftUI
import Foundation
import PDFKit

// MARK: - Book Model
struct Book: Identifiable, Codable {
    var id = UUID()
    var title: String
    var author: String
    var fileName: String
    var fileType: FileType
    var coverImageData: Data?
    var dateAdded: Date
    var lastOpened: Date?
    var currentPage: Int = 0
    var totalPages: Int = 0
    var progress: Double = 0.0
    var notes: [BookNote] = []
    var isFavorite: Bool = false
    var mode: String // Which mode it belongs to
    var tags: [String] = []
    var fileData: Data?
    var filePath: String?
    
    enum FileType: String, Codable {
        case pdf = "pdf"
        case epub = "epub"
        case mobi = "mobi"
        case txt = "txt"
        case mp3 = "mp3"
        case m4a = "m4a"
        case ogg = "ogg"
        case flac = "flac"
        case mp4 = "mp4"
        case mov = "mov"
        case jpg = "jpg"
        case png = "png"
        
        var icon: String {
            switch self {
            case .pdf: return "doc.fill"
            case .epub, .mobi: return "book.fill"
            case .txt: return "doc.text.fill"
            case .mp3, .m4a, .ogg, .flac: return "music.note"
            case .mp4, .mov: return "play.rectangle.fill"
            case .jpg, .png: return "photo.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .pdf: return .red
            case .epub, .mobi: return .blue
            case .txt: return .gray
            case .mp3, .m4a, .ogg, .flac: return .purple
            case .mp4, .mov: return .orange
            case .jpg, .png: return .green
            }
        }
    }
    
    var progressPercentage: Int {
        Int(progress * 100)
    }
    
    var coverImage: Image? {
        if let data = coverImageData, let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        return nil
    }
}

// MARK: - Book Note
struct BookNote: Identifiable, Codable {
    var id = UUID()
    var text: String
    var page: Int
    var dateCreated: Date
    var color: String = "yellow" // Highlight color
}

// MARK: - Book Manager
class BookManager: ObservableObject {
    static let shared = BookManager()
    
    @Published var books: [Book] = []
    @Published var currentlyReading: Book?
    
    private let booksKey = "libritoBooks"
    private let documentsDirectory: URL
    
    init() {
        // Get documents directory for file storage
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        loadBooks()
        // Clean up any broken books on startup
        cleanupBrokenBooks()
    }
    
    // MARK: - Book Management
    func addBook(title: String, author: String, fileData: Data, fileName: String, mode: String, tags: [String] = []) -> Book? {
        // Determine file type
        let fileType = determineFileType(from: fileName)
        
        // Save file to documents directory
        let bookId = UUID().uuidString
        let fileURL = documentsDirectory.appendingPathComponent("\(bookId)_\(fileName)")
        
        do {
            try fileData.write(to: fileURL)
            
            // Extract cover and page count
            let (coverData, pageCount) = extractBookMetadata(from: fileData, fileType: fileType)
            
            let book = Book(
                title: title,
                author: author,
                fileName: fileName,
                fileType: fileType,
                coverImageData: coverData,
                dateAdded: Date(),
                totalPages: pageCount,
                mode: mode,
                tags: tags,
                filePath: fileURL.path
            )
            
            books.append(book)
            saveBooks()
            
            return book
        } catch {
            print("Error saving book file: \(error)")
            return nil
        }
    }
    
    func deleteBook(_ book: Book) {
        // Delete file if exists
        if let filePath = book.filePath {
            let fileURL = URL(fileURLWithPath: filePath)
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        books.removeAll { $0.id == book.id }
        saveBooks()
    }
    
    func cleanupBrokenBooks() {
        let brokenBooks = books.filter { book in
            // Remove books with no file path
            guard let filePath = book.filePath else { 
                print("Book '\(book.title)' has no file path - will remove")
                return true 
            }
            
            // Remove books with empty or invalid file paths
            if filePath.isEmpty || filePath == "nil" {
                print("Book '\(book.title)' has invalid file path: '\(filePath)' - will remove")
                return true
            }
            
            // Remove books where file doesn't exist
            if !FileManager.default.fileExists(atPath: filePath) {
                print("Book '\(book.title)' file doesn't exist at: '\(filePath)' - will remove")
                return true
            }
            
            // Remove books with 0 total pages and 0 progress (likely corrupted)
            // BUT: Don't remove audio/video/image files which naturally have 0 pages
            let mediaTypes: [Book.FileType] = [.mp3, .m4a, .ogg, .flac, .mp4, .mov, .jpg, .png]
            if book.totalPages == 0 && book.progress == 0 && book.currentPage == 0 && !mediaTypes.contains(book.fileType) {
                print("Book '\(book.title)' appears corrupted (0 pages, 0 progress) - will remove")
                return true
            }
            
            // Check if file has valid content (not empty or too small)
            do {
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: filePath)
                if let fileSize = fileAttributes[.size] as? Int64 {
                    // Remove files that are suspiciously small (< 1KB for PDFs)
                    if book.fileType == .pdf && fileSize < 1024 {
                        print("Book '\(book.title)' has suspiciously small PDF file (\(fileSize) bytes) - will remove")
                        return true
                    }
                    // Remove completely empty files
                    if fileSize == 0 {
                        print("Book '\(book.title)' has empty file - will remove")
                        return true
                    }
                }
            } catch {
                print("Book '\(book.title)' file attributes error: \(error) - will remove")
                return true
            }
            
            // Try to validate PDF files can be opened
            if book.fileType == .pdf {
                guard let pdfDocument = PDFDocument(url: URL(fileURLWithPath: filePath)),
                      pdfDocument.pageCount > 0 else {
                    print("Book '\(book.title)' PDF cannot be opened or has no pages - will remove")
                    return true
                }
            }
            
            return false
        }
        
        print("Found \(brokenBooks.count) broken books to clean up")
        for brokenBook in brokenBooks {
            print("Removing broken book: \(brokenBook.title)")
            books.removeAll { $0.id == brokenBook.id }
        }
        
        if !brokenBooks.isEmpty {
            saveBooks()
            print("Cleaned up \(brokenBooks.count) broken books")
        }
    }
    
    func updateProgress(for book: Book, page: Int) {
        guard let index = books.firstIndex(where: { $0.id == book.id }) else { return }
        
        books[index].currentPage = page
        books[index].progress = Double(page) / Double(max(1, book.totalPages))
        books[index].lastOpened = Date()
        
        saveBooks()
    }
    
    func toggleFavorite(for book: Book) {
        guard let index = books.firstIndex(where: { $0.id == book.id }) else { return }
        books[index].isFavorite.toggle()
        saveBooks()
    }
    
    func addNote(to book: Book, text: String, page: Int) {
        guard let index = books.firstIndex(where: { $0.id == book.id }) else { return }
        
        let note = BookNote(text: text, page: page, dateCreated: Date())
        books[index].notes.append(note)
        saveBooks()
    }
    
    func updateBookPageCount(for book: Book, pageCount: Int) {
        guard let index = books.firstIndex(where: { $0.id == book.id }) else { return }
        books[index].totalPages = pageCount
        saveBooks()
    }
    
    // MARK: - Book Filtering
    func booksCurrentlyReading() -> [Book] {
        books.filter { $0.progress > 0 && $0.progress < 1 }
    }
    
    func favorites() -> [Book] {
        books.filter { $0.isFavorite }
    }
    
    func recentBooks() -> [Book] {
        books.sorted { ($0.lastOpened ?? $0.dateAdded) > ($1.lastOpened ?? $1.dateAdded) }
    }
    
    // MARK: - Helper Methods
    private func determineFileType(from fileName: String) -> Book.FileType {
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return .pdf
        case "epub": return .epub
        case "mobi": return .mobi
        case "txt": return .txt
        case "mp3": return .mp3
        case "m4a": return .m4a
        case "ogg": return .ogg
        case "flac": return .flac
        case "mp4": return .mp4
        case "mov": return .mov
        case "jpg", "jpeg": return .jpg
        case "png": return .png
        default: return .pdf
        }
    }
    
    private func extractBookMetadata(from data: Data, fileType: Book.FileType) -> (coverData: Data?, pageCount: Int) {
        switch fileType {
        case .pdf:
            return extractPDFMetadata(from: data)
        case .epub, .mobi:
            // For now, return placeholder data
            return (nil, 100)
        case .txt:
            // Estimate pages based on text length
            let text = String(data: data, encoding: .utf8) ?? ""
            let estimatedPages = max(1, text.count / 3000) // ~3000 chars per page
            return (nil, estimatedPages)
        case .mp3, .m4a, .ogg, .flac, .mp4, .mov, .jpg, .png:
            // For media files, no pages
            return (nil, 0)
        }
    }
    
    private func extractPDFMetadata(from data: Data) -> (coverData: Data?, pageCount: Int) {
        guard let document = PDFDocument(data: data) else {
            return (nil, 0)
        }
        
        let pageCount = document.pageCount
        
        // Extract first page as cover
        var coverData: Data? = nil
        if let firstPage = document.page(at: 0) {
            let bounds = firstPage.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: bounds.size)
            let image = renderer.image { context in
                UIColor.white.setFill()
                context.fill(bounds)
                context.cgContext.translateBy(x: 0, y: bounds.height)
                context.cgContext.scaleBy(x: 1.0, y: -1.0)
                firstPage.draw(with: .mediaBox, to: context.cgContext)
            }
            coverData = image.jpegData(compressionQuality: 0.7)
        }
        
        return (coverData, pageCount)
    }
    
    // MARK: - Persistence
    private func saveBooks() {
        if let encoded = try? JSONEncoder().encode(books) {
            UserDefaults.standard.set(encoded, forKey: booksKey)
        }
    }
    
    private func loadBooks() {
        if let data = UserDefaults.standard.data(forKey: booksKey),
           let decoded = try? JSONDecoder().decode([Book].self, from: data) {
            books = decoded
        }
    }
}

// MARK: - Book Card View
struct BookCard: View {
    let book: Book
    @ObservedObject var bookManager: BookManager
    @State private var showingReader = false
    @State private var showingNoteSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Cover and Info
            HStack(spacing: 16) {
                // Book Cover
                ZStack {
                    if let coverImage = book.coverImage {
                        coverImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(book.fileType.color.opacity(0.2))
                            .overlay(
                                Image(systemName: book.fileType.icon)
                                    .font(.system(size: 39))
                                    .foregroundColor(book.fileType.color)
                            )
                    }
                }
                .frame(width: 80, height: 120)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                
                // Book Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(book.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                        .lineLimit(2)
                    
                    Text(book.author)
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    // Progress Bar
                    if book.totalPages > 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\(book.progressPercentage)% complete")
                                    .font(.system(size: 15))
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Text("Page \(book.currentPage)/\(book.totalPages)")
                                    .font(.system(size: 15))
                                    .foregroundColor(.gray)
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 8)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(book.fileType.color)
                                        .frame(width: geometry.size.width * book.progress, height: 8)
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        // Only show Open button for non-inline file types
                        if ![Book.FileType.pdf, .mp3, .m4a, .ogg, .flac].contains(book.fileType) {
                            Button(action: {
                                showingReader = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "book.fill")
                                        .font(.system(size: 15))
                                    Text("Open")
                                        .font(.system(size: 15, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(book.fileType.color)
                                .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        Button(action: {
                            showingNoteSheet = true
                        }) {
                            Image(systemName: "note.text.badge.plus")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                                .padding(6)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            bookManager.toggleFavorite(for: book)
                        }) {
                            Image(systemName: book.isFavorite ? "star.fill" : "star")
                                .font(.system(size: 18))
                                .foregroundColor(book.isFavorite ? .yellow : .gray)
                                .padding(6)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            bookManager.deleteBook(book)
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 18))
                                .foregroundColor(.red)
                                .padding(6)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showingReader) {
            BookReaderView(book: book, bookManager: bookManager)
        }
        .sheet(isPresented: $showingNoteSheet) {
            AddBookNoteView(book: book, bookManager: bookManager)
        }
    }
}

// MARK: - Book Reader View (Placeholder)
struct BookReaderView: View {
    let book: Book
    @ObservedObject var bookManager: BookManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if book.fileType == .pdf, let filePath = book.filePath {
                    SafePDFReaderView(filePath: filePath, book: book, bookManager: bookManager)
                } else if book.fileType == .pdf {
                    VStack(spacing: 20) {
                        Text("⚠️ Cannot Open PDF")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Debug Information:")
                                .font(.headline)
                            Text("File path: \(book.filePath ?? "nil")")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("File type: \(book.fileType.rawValue)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("Total pages: \(book.totalPages)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        
                        Button("Delete This Book") {
                            bookManager.deleteBook(book)
                            dismiss()
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(8)
                    }
                    .padding()
                } else if [Book.FileType.mp3, .m4a, .ogg, .flac].contains(book.fileType), let filePath = book.filePath {
                    AudioPlayerView(filePath: filePath, book: book, bookManager: bookManager)
                } else {
                    VStack(spacing: 20) {
                        Text("📚 Reader Coming Soon")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Reader for \(book.fileType.rawValue) files is not yet available")
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
            .navigationTitle(book.title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Done") { dismiss() }
            )
        }
    }
}

// MARK: - Safe PDF Reader View with Loading States
struct SafePDFReaderView: View {
    let filePath: String
    let book: Book
    @ObservedObject var bookManager: BookManager
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var document: PDFDocument?
    
    var body: some View {
        VStack {
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading PDF...")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = loadError {
                VStack(spacing: 20) {
                    Text("⚠️ Failed to Load PDF")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text(error)
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button("Delete This Book") {
                        bookManager.deleteBook(book)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(8)
                }
                .padding()
            } else {
                PDFReaderView(filePath: filePath, book: book, bookManager: bookManager)
            }
        }
        .onAppear {
            loadPDFSafely()
        }
    }
    
    private func loadPDFSafely() {
        DispatchQueue.global(qos: .userInitiated).async {
            // Check if file exists
            guard FileManager.default.fileExists(atPath: filePath) else {
                DispatchQueue.main.async {
                    self.loadError = "PDF file not found at path:\n\(filePath)"
                    self.isLoading = false
                }
                return
            }
            
            // Check file size before attempting to load
            do {
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: filePath)
                if let fileSize = fileAttributes[.size] as? Int64 {
                    if fileSize == 0 {
                        DispatchQueue.main.async {
                            self.loadError = "PDF file is empty (0 bytes)."
                            self.isLoading = false
                        }
                        return
                    }
                    if fileSize < 1024 { // Less than 1KB
                        DispatchQueue.main.async {
                            self.loadError = "PDF file is too small (\(fileSize) bytes) and may be corrupted."
                            self.isLoading = false
                        }
                        return
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.loadError = "Cannot read file information: \(error.localizedDescription)"
                    self.isLoading = false
                }
                return
            }
            
            // Try to load document with timeout
            let fileURL = URL(fileURLWithPath: filePath)
            var pdfDocument: PDFDocument?
            
            // Use a semaphore for timeout
            let semaphore = DispatchSemaphore(value: 0)
            let timeoutInterval: TimeInterval = 10 // 10 second timeout
            
            DispatchQueue.global().async {
                pdfDocument = PDFDocument(url: fileURL)
                semaphore.signal()
            }
            
            let result = semaphore.wait(timeout: .now() + timeoutInterval)
            
            if result == .timedOut {
                DispatchQueue.main.async {
                    self.loadError = "PDF loading timed out. The file may be corrupted or too large."
                    self.isLoading = false
                }
                return
            }
            
            guard let document = pdfDocument else {
                DispatchQueue.main.async {
                    self.loadError = "Unable to read PDF file. The file may be corrupted or in an unsupported format."
                    self.isLoading = false
                }
                return
            }
            
            // Check if document has pages
            guard document.pageCount > 0 else {
                DispatchQueue.main.async {
                    self.loadError = "PDF file contains no pages."
                    self.isLoading = false
                }
                return
            }
            
            // Validate first page can be rendered
            guard let firstPage = document.page(at: 0) else {
                DispatchQueue.main.async {
                    self.loadError = "PDF pages cannot be accessed."
                    self.isLoading = false
                }
                return
            }
            
            // Try to get page bounds to ensure it's valid
            let bounds = firstPage.bounds(for: .mediaBox)
            if bounds.width <= 0 || bounds.height <= 0 {
                DispatchQueue.main.async {
                    self.loadError = "PDF pages have invalid dimensions."
                    self.isLoading = false
                }
                return
            }
            
            // Success
            DispatchQueue.main.async {
                self.document = document
                self.isLoading = false
                
                // Update total pages if needed
                if self.book.totalPages != document.pageCount {
                    self.bookManager.updateBookPageCount(for: self.book, pageCount: document.pageCount)
                }
            }
        }
    }
}

// MARK: - PDF Reader View
struct PDFReaderView: UIViewRepresentable {
    let filePath: String
    let book: Book
    @ObservedObject var bookManager: BookManager
    @AppStorage("pdfContinuousScroll") private var continuousScroll = true
    @AppStorage("pdfPageFlipping") private var pageFlipping = false
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        
        // Configure display mode based on user preference
        if pageFlipping {
            pdfView.displayMode = .singlePage
            pdfView.usePageViewController(true, withViewOptions: nil)
        } else if continuousScroll {
            pdfView.displayMode = .singlePageContinuous
            pdfView.displayDirection = .vertical
        } else {
            pdfView.displayMode = .singlePage
            pdfView.displayDirection = .vertical
        }
        
        // Enable gestures
        pdfView.minScaleFactor = 0.5
        pdfView.maxScaleFactor = 5.0
        pdfView.autoScales = true
        
        // Add delegate
        pdfView.delegate = context.coordinator
        
        // Add safety checks and async loading
        DispatchQueue.global(qos: .userInitiated).async {
            // Check if file exists first
            guard FileManager.default.fileExists(atPath: filePath) else {
                print("PDF file does not exist at path: \(filePath)")
                return
            }
            
            // Try to create document
            guard let document = PDFDocument(url: URL(fileURLWithPath: filePath)) else {
                print("Failed to create PDFDocument from path: \(filePath)")
                return
            }
            
            // Update UI on main thread
            DispatchQueue.main.async {
                pdfView.document = document
                
                // Go to saved page safely
                let targetPage = min(book.currentPage, document.pageCount - 1)
                if targetPage >= 0, let page = document.page(at: targetPage) {
                    pdfView.go(to: page)
                }
            }
        }
        
        return pdfView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PDFViewDelegate {
        let parent: PDFReaderView
        
        init(_ parent: PDFReaderView) {
            self.parent = parent
        }
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // Update current page when view updates - with safety checks
        guard let currentPage = uiView.currentPage,
              let document = uiView.document else { return }
        
        let pageIndex = document.index(for: currentPage)
        if pageIndex >= 0 && pageIndex < document.pageCount {
            bookManager.updateProgress(for: book, page: pageIndex)
        }
    }
}

// MARK: - Add Book Note View
struct AddBookNoteView: View {
    let book: Book
    @ObservedObject var bookManager: BookManager
    @Environment(\.dismiss) var dismiss
    @State private var noteText = ""
    @State private var pageNumber = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Note") {
                    TextEditor(text: $noteText)
                        .frame(minHeight: 100)
                }
                
                Section("Page") {
                    TextField("Page number", text: $pageNumber)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Add Note")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    if !noteText.isEmpty {
                        let page = Int(pageNumber) ?? book.currentPage
                        bookManager.addNote(to: book, text: noteText, page: page)
                        dismiss()
                    }
                }
                .disabled(noteText.isEmpty)
            )
        }
    }
}