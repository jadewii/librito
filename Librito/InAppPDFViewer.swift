//
//  InAppPDFViewer.swift
//  Librito
//
//  In-app PDF viewer with navigation, zoom, and reading progress
//

import SwiftUI
import PDFKit
import UIKit

struct InAppPDFViewer: View {
    let item: ArchiveOrgService.ArchiveItem
    let pdfURL: URL
    @Environment(\.dismiss) var dismiss
    @StateObject private var readingProgress = ReadingProgressManager.shared
    @State private var currentPage: Int = 1
    @State private var totalPages: Int = 0
    @State private var showingControls = true
    @State private var pdfView: PDFView?
    @State private var isLoading = true
    @State private var showingPageJumper = false
    @State private var targetPage = ""
    @State private var showingBookmarks = false
    @State private var zoomScale: CGFloat = 1.0
    
    var body: some View {
        NavigationView {
            ZStack {
                // PDF Viewer
                PDFViewRepresentable(
                    url: pdfURL,
                    currentPage: $currentPage,
                    totalPages: $totalPages,
                    pdfView: $pdfView,
                    isLoading: $isLoading,
                    onPageChanged: { page in
                        currentPage = page
                        saveReadingProgress()
                    }
                )
                .ignoresSafeArea(edges: .bottom)
                
                // Loading overlay
                if isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading PDF...")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white.opacity(0.9))
                }
                
                // Top controls
                if showingControls {
                    VStack {
                        HStack {
                            Button("Close") {
                                saveReadingProgress()
                                dismiss()
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                            
                            Spacer()
                            
                            Text(item.title)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Menu {
                                Button("Jump to Page") {
                                    showingPageJumper = true
                                }
                                
                                Button("Bookmarks") {
                                    showingBookmarks = true
                                }
                                
                                Button("Add to Library") {
                                    PlaylistService.shared.addToLibrary(item)
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.95))
                        .shadow(radius: 2)
                        
                        Spacer()
                    }
                }
                
                // Bottom controls
                if showingControls && !isLoading {
                    VStack {
                        Spacer()
                        
                        HStack {
                            // Previous page
                            Button(action: previousPage) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 20))
                                    .foregroundColor(currentPage > 1 ? .blue : .gray)
                            }
                            .disabled(currentPage <= 1)
                            
                            Spacer()
                            
                            // Page indicator
                            Button(action: {
                                showingPageJumper = true
                            }) {
                                Text("\(currentPage) of \(totalPages)")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .shadow(radius: 2)
                            }
                            
                            Spacer()
                            
                            // Next page
                            Button(action: nextPage) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 20))
                                    .foregroundColor(currentPage < totalPages ? .blue : .gray)
                            }
                            .disabled(currentPage >= totalPages)
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarHidden(true)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingControls.toggle()
                }
            }
            .onAppear {
                loadReadingProgress()
            }
            .sheet(isPresented: $showingPageJumper) {
                PageJumperView(
                    targetPage: $targetPage,
                    totalPages: totalPages,
                    onJump: { page in
                        jumpToPage(page)
                    }
                )
            }
            .sheet(isPresented: $showingBookmarks) {
                BookmarksView(
                    item: item,
                    currentPage: currentPage,
                    onJumpToPage: { page in
                        jumpToPage(page)
                    }
                )
            }
        }
    }
    
    private func previousPage() {
        guard let pdfView = pdfView else { return }
        pdfView.goToPreviousPage(nil)
    }
    
    private func nextPage() {
        guard let pdfView = pdfView else { return }
        pdfView.goToNextPage(nil)
    }
    
    private func jumpToPage(_ page: Int) {
        guard let pdfView = pdfView,
              let document = pdfView.document,
              page >= 1 && page <= totalPages else { return }
        
        let targetPage = document.page(at: page - 1)
        pdfView.go(to: targetPage!)
        currentPage = page
        saveReadingProgress()
    }
    
    private func loadReadingProgress() {
        if let progress = readingProgress.getProgress(for: item.id) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                jumpToPage(progress.currentPage)
            }
        }
    }
    
    private func saveReadingProgress() {
        readingProgress.updateProgress(
            for: item.id,
            currentPage: currentPage,
            totalPages: totalPages,
            title: item.title
        )
    }
}

// MARK: - PDFView Representable
struct PDFViewRepresentable: UIViewRepresentable {
    let url: URL
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    @Binding var pdfView: PDFView?
    @Binding var isLoading: Bool
    let onPageChanged: (Int) -> Void
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        
        pdfView.displayMode = .singlePageContinuous
        pdfView.autoScales = true
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(true, withViewOptions: nil)
        
        // Set up notifications
        NotificationCenter.default.addObserver(
            forName: .PDFViewPageChanged,
            object: pdfView,
            queue: .main
        ) { _ in
            if let currentPDFPage = pdfView.currentPage,
               let document = pdfView.document {
                let pageIndex = document.index(for: currentPDFPage)
                DispatchQueue.main.async {
                    self.currentPage = pageIndex + 1
                    self.onPageChanged(pageIndex + 1)
                }
            }
        }
        
        self.pdfView = pdfView
        loadPDF(into: pdfView)
        
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // Update handled by notifications
    }
    
    private func loadPDF(into pdfView: PDFView) {
        DispatchQueue.global(qos: .userInitiated).async {
            if let document = PDFDocument(url: url) {
                DispatchQueue.main.async {
                    pdfView.document = document
                    self.totalPages = document.pageCount
                    self.isLoading = false
                    
                    // Scale to fit width
                    pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Page Jumper View
struct PageJumperView: View {
    @Binding var targetPage: String
    let totalPages: Int
    let onJump: (Int) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Jump to Page")
                    .font(.system(size: 24, weight: .bold))
                
                VStack(alignment: .leading) {
                    Text("Page Number (1-\(totalPages))")
                        .font(.system(size: 16, weight: .medium))
                    
                    TextField("Enter page number", text: $targetPage)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
                
                Button("Jump") {
                    if let page = Int(targetPage), page >= 1 && page <= totalPages {
                        onJump(page)
                        dismiss()
                    }
                }
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(targetPage.isEmpty || Int(targetPage) == nil ? Color.gray : Color.blue)
                .cornerRadius(8)
                .disabled(targetPage.isEmpty || Int(targetPage) == nil)
                
                Spacer()
            }
            .padding(24)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    dismiss()
                }
            )
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Bookmarks View
struct BookmarksView: View {
    let item: ArchiveOrgService.ArchiveItem
    let currentPage: Int
    let onJumpToPage: (Int) -> Void
    @Environment(\.dismiss) var dismiss
    @StateObject private var bookmarkManager = BookmarkManager.shared
    
    var body: some View {
        NavigationView {
            VStack {
                if bookmarkManager.getBookmarks(for: item.id).isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("No Bookmarks")
                            .font(.system(size: 20, weight: .medium))
                        
                        Text("Add bookmarks by using the menu")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        
                        Button("Bookmark Current Page") {
                            bookmarkManager.addBookmark(
                                for: item.id,
                                page: currentPage,
                                title: "Page \(currentPage)"
                            )
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(bookmarkManager.getBookmarks(for: item.id)) { bookmark in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(bookmark.title)
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Page \(bookmark.page)")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Button("Go") {
                                    onJumpToPage(bookmark.page)
                                    dismiss()
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.blue)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let bookmarks = bookmarkManager.getBookmarks(for: item.id)
                                bookmarkManager.removeBookmark(bookmarks[index])
                            }
                        }
                    }
                }
            }
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Add") {
                    bookmarkManager.addBookmark(
                        for: item.id,
                        page: currentPage,
                        title: "Page \(currentPage)"
                    )
                },
                trailing: Button("Done") {
                    dismiss()
                }
            )
        }
    }
}

// MARK: - Reading Progress Manager
class ReadingProgressManager: ObservableObject {
    static let shared = ReadingProgressManager()
    
    @Published private var progressData: [String: ReadingProgress] = [:]
    private let userDefaults = UserDefaults.standard
    private let progressKey = "librito_reading_progress"
    
    init() {
        loadProgress()
    }
    
    func updateProgress(for itemId: String, currentPage: Int, totalPages: Int, title: String) {
        let progress = ReadingProgress(
            itemId: itemId,
            title: title,
            currentPage: currentPage,
            totalPages: totalPages,
            lastRead: Date(),
            percentComplete: Double(currentPage) / Double(totalPages)
        )
        
        progressData[itemId] = progress
        saveProgress()
    }
    
    func getProgress(for itemId: String) -> ReadingProgress? {
        return progressData[itemId]
    }
    
    func getAllProgress() -> [ReadingProgress] {
        return Array(progressData.values).sorted { $0.lastRead > $1.lastRead }
    }
    
    private func loadProgress() {
        if let data = userDefaults.data(forKey: progressKey),
           let decoded = try? JSONDecoder().decode([String: ReadingProgress].self, from: data) {
            progressData = decoded
        }
    }
    
    private func saveProgress() {
        if let encoded = try? JSONEncoder().encode(progressData) {
            userDefaults.set(encoded, forKey: progressKey)
        }
    }
}

struct ReadingProgress: Codable, Identifiable {
    var id: UUID = UUID()
    let itemId: String
    let title: String
    let currentPage: Int
    let totalPages: Int
    let lastRead: Date
    let percentComplete: Double
}

// MARK: - Bookmark Manager
class BookmarkManager: ObservableObject {
    static let shared = BookmarkManager()
    
    @Published private var bookmarks: [String: [Bookmark]] = [:]
    private let userDefaults = UserDefaults.standard
    private let bookmarksKey = "librito_bookmarks"
    
    init() {
        loadBookmarks()
    }
    
    func addBookmark(for itemId: String, page: Int, title: String) {
        let bookmark = Bookmark(itemId: itemId, page: page, title: title, dateAdded: Date())
        
        if bookmarks[itemId] == nil {
            bookmarks[itemId] = []
        }
        
        bookmarks[itemId]?.append(bookmark)
        saveBookmarks()
    }
    
    func removeBookmark(_ bookmark: Bookmark) {
        bookmarks[bookmark.itemId]?.removeAll { $0.id == bookmark.id }
        saveBookmarks()
    }
    
    func getBookmarks(for itemId: String) -> [Bookmark] {
        return bookmarks[itemId] ?? []
    }
    
    private func loadBookmarks() {
        if let data = userDefaults.data(forKey: bookmarksKey),
           let decoded = try? JSONDecoder().decode([String: [Bookmark]].self, from: data) {
            bookmarks = decoded
        }
    }
    
    private func saveBookmarks() {
        if let encoded = try? JSONEncoder().encode(bookmarks) {
            userDefaults.set(encoded, forKey: bookmarksKey)
        }
    }
}

struct Bookmark: Codable, Identifiable {
    var id: UUID = UUID()
    let itemId: String
    let page: Int
    let title: String
    let dateAdded: Date
}

#Preview {
    InAppPDFViewer(
        item: ArchiveOrgService.ArchiveItem(
            id: "test",
            title: "Sample PDF",
            creator: "Test Author",
            date: "2023",
            description: "A test PDF",
            mediatype: "texts",
            identifier: "test"
        ),
        pdfURL: URL(string: "https://example.com/sample.pdf")!
    )
}