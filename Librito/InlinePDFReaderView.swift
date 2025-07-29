//
//  InlinePDFReaderView.swift
//  Librito
//
//  Inline PDF reader for full-screen viewing
//

import SwiftUI
import PDFKit

struct InlinePDFReaderView: View {
    let book: Book
    @ObservedObject var bookManager: BookManager
    @State private var currentPageInt = 1
    @State private var totalPages = 1
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var showScrollSettings = false
    @State private var showThumbnails = true
    @AppStorage("pdfContinuousScroll") private var continuousScroll = true
    @AppStorage("pdfPageFlipping") private var pageFlipping = false
    
    // Computed property for slider
    private var currentPageDouble: Binding<Double> {
        Binding(
            get: { Double(currentPageInt) },
            set: { currentPageInt = Int($0.rounded()) }
        )
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.ignoresSafeArea()
                
                HStack(spacing: 0) {
                    // Main PDF View
                    VStack(spacing: 0) {
                        // PDF View
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
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.red)
                                Text("Error Loading PDF")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text(error)
                                    .font(.body)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if let filePath = book.filePath {
                            let url = URL(fileURLWithPath: filePath)
                            InlinePDFViewWrapper(
                                url: url,
                                currentPage: $currentPageInt,
                                totalPages: $totalPages,
                                continuousScroll: continuousScroll,
                                pageFlipping: pageFlipping
                            )
                            .background(Color.gray.opacity(0.1))
                        } else {
                            Text("Unable to load PDF")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    
                    // Bottom controls (only show when PDF is loaded)
                    if !isLoading && loadError == nil && totalPages > 0 {
                        HStack(spacing: 30) {
                        // Thumbnail toggle button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showThumbnails.toggle()
                            }
                        }) {
                            Image(systemName: showThumbnails ? "sidebar.right" : "sidebar.left")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Settings button
                        Button(action: {
                            showScrollSettings.toggle()
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            if currentPageInt > 1 {
                                currentPageInt -= 1
                                updateProgress()
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(currentPageInt > 1 ? .black : .gray)
                        }
                        .disabled(currentPageInt <= 1)
                        .buttonStyle(PlainButtonStyle())
                        
                        // Page slider (hide in continuous scroll mode)
                        if !continuousScroll {
                            VStack(spacing: 8) {
                                if totalPages > 1 {
                                    Slider(
                                        value: currentPageDouble,
                                        in: 1...Double(totalPages),
                                        step: 1
                                    )
                                    .accentColor(.black)
                                }
                                
                                Text("Page \(currentPageInt) of \(totalPages)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: geometry.size.width * 0.5)
                        } else {
                            // Show current page info in continuous mode
                            Text("Page \(currentPageInt) of \(totalPages)")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .frame(maxWidth: geometry.size.width * 0.5)
                        }
                        
                        Button(action: {
                            if currentPageInt < totalPages {
                                currentPageInt += 1
                                updateProgress()
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(currentPageInt < totalPages ? .black : .gray)
                        }
                        .disabled(currentPageInt >= totalPages)
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .background(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 5, y: -5)
                    }
                }
                
                // Thumbnail Sidebar
                if showThumbnails && !isLoading && loadError == nil && book.filePath != nil {
                    PDFThumbnailSidebar(
                        pdfURL: URL(fileURLWithPath: book.filePath!),
                        currentPage: $currentPageInt,
                        totalPages: totalPages
                    )
                    .frame(width: 150)
                    .background(Color.gray.opacity(0.05))
                    .transition(.move(edge: .trailing))
                }
            }
            }
        }
        .onAppear {
            loadPDF()
            // Set current page from book progress
            if book.totalPages > 0 && book.currentPage > 0 {
                currentPageInt = min(book.currentPage, book.totalPages)
            }
        }
        .sheet(isPresented: $showScrollSettings) {
            PDFScrollSettingsView()
        }
    }
    
    private func loadPDF() {
        isLoading = true
        loadError = nil
        
        guard let filePath = book.filePath else {
            loadError = "No file path available"
            isLoading = false
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let fileManager = FileManager.default
                guard fileManager.fileExists(atPath: filePath) else {
                    throw NSError(domain: "PDFError", code: 1, userInfo: [NSLocalizedDescriptionKey: "File not found at path: \(filePath)"])
                }
                
                let url = URL(fileURLWithPath: filePath)
                guard let document = PDFDocument(url: url) else {
                    throw NSError(domain: "PDFError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create PDF document"])
                }
                
                DispatchQueue.main.async {
                    self.totalPages = document.pageCount
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.loadError = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func updateProgress() {
        bookManager.updateProgress(for: book, page: currentPageInt)
    }
}

// PDF View Wrapper for Inline Reader
struct InlinePDFViewWrapper: UIViewRepresentable {
    let url: URL
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    let continuousScroll: Bool
    let pageFlipping: Bool
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        
        // Configure display mode based on settings
        if pageFlipping {
            pdfView.displayMode = .singlePage
            pdfView.usePageViewController(true, withViewOptions: nil)
        } else if continuousScroll {
            pdfView.displayMode = .singlePageContinuous
            pdfView.displayDirection = .vertical
        } else {
            pdfView.displayMode = .singlePage
            pdfView.displayDirection = .horizontal
        }
        
        // Set scale to fit width for better default view
        pdfView.autoScales = true
        pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit
        
        // Enable gestures
        pdfView.minScaleFactor = 0.5
        pdfView.maxScaleFactor = 5.0
        
        // Load PDF asynchronously to avoid freezing
        DispatchQueue.global(qos: .userInitiated).async {
            if let document = PDFDocument(url: url) {
                DispatchQueue.main.async {
                    pdfView.document = document
                    self.totalPages = document.pageCount
                    
                    // Set scale to fit width after document is loaded
                    pdfView.autoScales = false
                    pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit
                    
                    // Go to saved page
                    if self.currentPage > 0 && self.currentPage <= document.pageCount {
                        let pageIndex = self.currentPage - 1
                        if let page = document.page(at: pageIndex) {
                            pdfView.go(to: page)
                        }
                    }
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: pdfView
        )
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        if let document = pdfView.document,
           currentPage > 0 && currentPage <= document.pageCount {
            let pageIndex = currentPage - 1
            if let page = document.page(at: pageIndex) {
                pdfView.go(to: page)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: InlinePDFViewWrapper
        
        init(_ parent: InlinePDFViewWrapper) {
            self.parent = parent
        }
        
        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView else { return }
            guard let currentPage = pdfView.currentPage else { return }
            guard let document = pdfView.document else { return }
            
            let pageIndex = document.index(for: currentPage)
            parent.currentPage = pageIndex + 1
        }
    }
}

// MARK: - PDF Scroll Settings View
struct PDFScrollSettingsView: View {
    @AppStorage("pdfContinuousScroll") private var continuousScroll = true
    @AppStorage("pdfPageFlipping") private var pageFlipping = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Scrolling Style")) {
                    Toggle("Continuous Scroll", isOn: $continuousScroll)
                        .onChange(of: continuousScroll) { _, newValue in
                            if newValue && pageFlipping {
                                pageFlipping = false
                            }
                        }
                    
                    Toggle("Page Flipping Animation", isOn: $pageFlipping)
                        .onChange(of: pageFlipping) { _, newValue in
                            if newValue && continuousScroll {
                                continuousScroll = false
                            }
                        }
                }
                
                Section(footer: Text("Choose how you want to navigate through PDFs. Continuous scroll allows smooth vertical scrolling, while page flipping provides a book-like experience.")) {
                    EmptyView()
                }
            }
            .navigationTitle("PDF Display Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

// MARK: - PDF Thumbnail Sidebar
struct PDFThumbnailSidebar: View {
    let pdfURL: URL
    @Binding var currentPage: Int
    let totalPages: Int
    @State private var thumbnails: [Int: UIImage] = [:]
    @State private var pdfDocument: PDFDocument?
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(1...totalPages, id: \.self) { pageNumber in
                        PDFThumbnailView(
                            pageNumber: pageNumber,
                            isSelected: pageNumber == currentPage,
                            thumbnail: thumbnails[pageNumber]
                        )
                        .id(pageNumber)
                        .onTapGesture {
                            currentPage = pageNumber
                        }
                    }
                }
                .padding(.vertical, 10)
            }
            .onChange(of: currentPage) { _, newPage in
                withAnimation {
                    proxy.scrollTo(newPage, anchor: .center)
                }
            }
        }
        .onAppear {
            loadThumbnails()
        }
    }
    
    private func loadThumbnails() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let document = PDFDocument(url: pdfURL) else { return }
            self.pdfDocument = document
            
            // Load thumbnails in batches for performance
            for pageNumber in 1...min(10, totalPages) {
                loadThumbnail(for: pageNumber, document: document)
            }
            
            // Load remaining thumbnails with lower priority
            DispatchQueue.global(qos: .utility).async {
                for pageNumber in 11...totalPages {
                    loadThumbnail(for: pageNumber, document: document)
                }
            }
        }
    }
    
    private func loadThumbnail(for pageNumber: Int, document: PDFDocument) {
        guard pageNumber > 0 && pageNumber <= document.pageCount,
              let page = document.page(at: pageNumber - 1) else { return }
        
        let thumbnailSize = CGSize(width: 120, height: 160)
        let thumbnail = page.thumbnail(of: thumbnailSize, for: .mediaBox)
        
        DispatchQueue.main.async {
            self.thumbnails[pageNumber] = thumbnail
        }
    }
}

// MARK: - Individual Thumbnail View
struct PDFThumbnailView: View {
    let pageNumber: Int
    let isSelected: Bool
    let thumbnail: UIImage?
    
    var body: some View {
        VStack(spacing: 4) {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 160)
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 3 : 1)
                    )
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 120, height: 160)
                    .cornerRadius(4)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                    )
            }
            
            Text("Page \(pageNumber)")
                .font(.caption)
                .foregroundColor(isSelected ? .blue : .gray)
        }
        .padding(.horizontal, 10)
    }
}