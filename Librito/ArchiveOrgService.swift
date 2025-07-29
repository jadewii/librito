//
//  ArchiveOrgService.swift
//  Todomai-iOS
//
//  Service for integrating with Archive.org API
//

import Foundation
import Combine
import SwiftUI

class ArchiveOrgService: ObservableObject {
    static let shared = ArchiveOrgService()
    
    @Published var searchResults: [ArchiveItem] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentPage = 0
    @Published var hasMorePages = true
    @Published var isLoadingMore = false
    
    private var cancellables = Set<AnyCancellable>()
    private let baseURL = "https://archive.org"
    private let itemsPerPage = 50
    private var lastSearchQuery = ""
    private var lastMediaType: String? = nil
    private var lastLibraryMediaType: MediaType? = nil
    
    struct ArchiveItem: Identifiable, Codable {
        let id: String
        let title: String
        let creator: String?
        let date: String?
        let description: String?
        let mediatype: String
        let identifier: String
        
        var downloadURL: String {
            "\(ArchiveOrgService.shared.baseURL)/download/\(identifier)"
        }
        
        var streamURL: String {
            "\(ArchiveOrgService.shared.baseURL)/stream/\(identifier)"
        }
        
        var thumbnailURL: String? {
            "\(ArchiveOrgService.shared.baseURL)/services/img/\(identifier)"
        }
        
        var itemType: ItemType {
            switch mediatype.lowercased() {
            case "texts": return .pdf
            case "audio": return .audiobook
            case "movies": return .video
            default: return .other
            }
        }
        
        enum ItemType {
            case pdf, audiobook, video, other
            
            var icon: String {
                switch self {
                case .pdf: return "doc.fill"
                case .audiobook: return "headphones"
                case .video: return "play.rectangle.fill"
                case .other: return "doc"
                }
            }
        }
    }
    
    func search(query: String, mediaType: String? = nil, libraryMediaType: MediaType? = nil, append: Bool = false) {
        // If appending (for endless scroll), set isLoadingMore, otherwise set isLoading
        if append {
            isLoadingMore = true
        } else {
            isLoading = true
            currentPage = 0
            hasMorePages = true
            searchResults = []
        }
        error = nil
        
        // Store search parameters for pagination
        lastSearchQuery = query
        lastMediaType = mediaType
        lastLibraryMediaType = libraryMediaType
        
        var searchQuery = ""
        
        // If query is empty, load curated content based on media type
        if query.isEmpty && libraryMediaType != nil {
            searchQuery = getCuratedQuery(for: libraryMediaType!)
        } else if !query.isEmpty {
            // User search with filters
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            searchQuery = "q=\(encodedQuery)"
            
            // Add mediatype
            if let mediaType = mediaType {
                searchQuery += "+AND+mediatype:\(mediaType)"
            }
            
            // Add filters based on library media type
            if let libraryMediaType = libraryMediaType {
                searchQuery += getMediaTypeFilters(for: libraryMediaType)
            }
        } else {
            return
        }
        
        // Add format filters based on library media type (not Archive media type)
        if let libraryMediaType = libraryMediaType {
            switch libraryMediaType {
            case .books:
                searchQuery += "+AND+(format:pdf+OR+format:epub+OR+format:text)"
            case .audiobooks, .music:
                searchQuery += "+AND+(format:mp3+OR+format:ogg+OR+format:flac+OR+format:wav)"
            case .radio:
                searchQuery += "+AND+(format:mp3+OR+format:ogg)"
            case .journal:
                // Journal is local only, no format filters needed
                break
            default:
                break
            }
        }
        
        // Exclude disability/restricted access books (but allow more content for discovery)
        searchQuery += "+AND+NOT+collection:printdisabled+AND+NOT+collection:inlibrary+AND+NOT+collection:americana"
        
        // Sort by downloads for quality content
        let urlString = "\(baseURL)/advancedsearch.php?\(searchQuery)&fl=identifier,title,creator,date,description,mediatype&rows=\(itemsPerPage)&page=\(currentPage + 1)&output=json&sort=downloads+desc"
        
        print("Archive.org search URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            error = "Invalid search URL"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map { data, _ in
                // Debug: Print raw response
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Archive.org raw response (first 500 chars): \(String(jsonString.prefix(500)))")
                }
                return data
            }
            .decode(type: SearchResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    self?.isLoadingMore = false
                    if case .failure(let error) = completion {
                        print("Archive.org search error: \(error)")
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] response in
                    print("Archive.org search response: \(response.response.docs.count) results")
                    let rawItems = response.response.docs.map { doc in
                        ArchiveItem(
                            id: doc.identifier,
                            title: doc.title ?? "Untitled",
                            creator: doc.creator?.stringValue,
                            date: doc.date,
                            description: doc.description?.stringValue,
                            mediatype: doc.mediatype,
                            identifier: doc.identifier
                        )
                    }
                    
                    // Filter out NSFW/explicit content (temporarily disabled until file is added to Xcode project)
                    let newItems = rawItems
                    // TODO: Re-enable content filtering once ContentModerationService is added to Xcode project
                    // let newItems = ContentModerationService.shared.filterExplicitContent(rawItems)
                    
                    if append {
                        // Append new items for endless scroll, avoiding duplicates
                        let existingIds = Set(self?.searchResults.map { $0.id } ?? [])
                        let uniqueNewItems = newItems.filter { !existingIds.contains($0.id) }
                        self?.searchResults.append(contentsOf: uniqueNewItems)
                    } else {
                        // Replace results for new search
                        self?.searchResults = newItems
                    }
                    
                    // Update pagination state
                    self?.hasMorePages = newItems.count >= (self?.itemsPerPage ?? 50)
                    if append {
                        self?.currentPage += 1
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func loadMore() {
        guard !isLoadingMore && hasMorePages else { return }
        search(query: lastSearchQuery, mediaType: lastMediaType, libraryMediaType: lastLibraryMediaType, append: true)
    }
    
    private func isStreamable(url: URL) -> Bool {
        let streamableExtensions = ["mp3", "ogg", "m4a", "flac", "wav", "m3u", "opus", "aac"]
        let pathExtension = url.pathExtension.lowercased()
        return streamableExtensions.contains(pathExtension)
    }
    
    func getStreamingURL(for item: ArchiveItem, completion: @escaping (URL?) -> Void) {
        // For streaming audio/video, we need to find the actual media file
        let metadataURL = URL(string: "\(baseURL)/metadata/\(item.identifier)")!
        print("\n=== STREAMING DEBUG ===")
        print("Item: \(item.title)")
        print("Identifier: \(item.identifier)")
        print("Media Type: \(item.mediatype)")
        print("Fetching metadata from: \(metadataURL)")
        
        URLSession.shared.dataTask(with: metadataURL) { data, _, error in
            if let error = error {
                print("Error fetching metadata for streaming: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("Metadata response keys: \(json.keys.sorted())")
                    
                    // Get files array from the metadata response
                    var files: [[String: Any]]?
                    
                    // Check if files is an array
                    if let filesArray = json["files"] as? [[String: Any]] {
                        files = filesArray
                    } else if let filesDict = json["files"] as? [String: [String: Any]] {
                        // Sometimes files come as a dictionary, convert to array
                        files = Array(filesDict.values)
                    }
                    
                    if let files = files {
                        // Find the best audio file for streaming
                        let streamFormats = ["mp3", "ogg", "m4a", "flac"]
                        print("Looking for streamable files among \(files.count) files")
                        
                        // Log first 10 files for better debugging
                        print("First 10 files in item:")
                        for (index, file) in files.prefix(10).enumerated() {
                            let name = file["name"] as? String ?? "unknown"
                            let format = file["format"] as? String ?? "unknown"
                            let source = file["source"] as? String ?? "unknown"
                            print("  \(index + 1). \(name) - Format: \(format) - Source: \(source)")
                        }
                        
                        // First try to find original files
                        for format in streamFormats {
                            if let file = files.first(where: { file in
                                let name = (file["name"] as? String ?? "").lowercased()
                                let fileFormat = (file["format"] as? String ?? "").lowercased()
                                let isOriginal = file["source"] as? String == "original"
                                // Prefer original files and skip derivatives
                                return isOriginal && (name.hasSuffix(".\(format)") || fileFormat.contains(format))
                            }), let fileName = file["name"] as? String {
                                let encodedFileName = fileName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? fileName
                                let streamURL = URL(string: "\(self.baseURL)/download/\(item.identifier)/\(encodedFileName)")
                                print("Found original file: \(fileName)")
                                print("Generated streaming URL: \(streamURL?.absoluteString ?? "nil")")
                                
                                // Validate the URL is streamable
                                if let url = streamURL, self.isStreamable(url: url) {
                                    completion(streamURL)
                                } else {
                                    print("URL is not streamable: \(streamURL?.absoluteString ?? "nil")")
                                    completion(nil)
                                }
                                return
                            }
                        }
                        
                        // If no original files found, try derivative files
                        print("No original audio files found, checking derivative files...")
                        for format in streamFormats {
                            if let file = files.first(where: { file in
                                let name = (file["name"] as? String ?? "").lowercased()
                                let fileFormat = (file["format"] as? String ?? "").lowercased()
                                // Look for any file with the right format, not just originals
                                return name.hasSuffix(".\(format)") || fileFormat.contains(format)
                            }), let fileName = file["name"] as? String {
                                let encodedFileName = fileName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? fileName
                                let streamURL = URL(string: "\(self.baseURL)/download/\(item.identifier)/\(encodedFileName)")
                                print("Found derivative file: \(fileName)")
                                print("Generated streaming URL: \(streamURL?.absoluteString ?? "nil")")
                                
                                // Validate the URL is streamable
                                if let url = streamURL, self.isStreamable(url: url) {
                                    completion(streamURL)
                                } else {
                                    print("URL is not streamable: \(streamURL?.absoluteString ?? "nil")")
                                    completion(nil)
                                }
                                return
                            }
                        }
                        
                        print("No streamable files found for item: \(item.identifier)")
                        print("Item title: \(item.title)")
                        print("Item media type: \(item.mediatype)")
                    } else {
                        print("No files found in metadata")
                        print("Available keys in response: \(json.keys.sorted())")
                        // Try to print the structure to understand what's there
                        if let filesValue = json["files"] {
                            print("Files value type: \(type(of: filesValue))")
                        }
                    }
                }
            } catch {
                print("Error parsing streaming metadata: \(error)")
            }
            
            completion(nil)
        }.resume()
    }
    
    func downloadItem(_ item: ArchiveItem, completion: @escaping (URL?) -> Void) {
        // Get list of files for the item
        let metadataURL = URL(string: "\(baseURL)/metadata/\(item.identifier)")!
        print("Fetching file metadata from: \(metadataURL)")
        
        URLSession.shared.dataTask(with: metadataURL) { data, _, error in
            if let error = error {
                print("Error fetching metadata: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data received from metadata API")
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("Metadata response keys: \(json.keys)")
                    
                    // Get files array from the metadata response
                    let files = json["files"] as? [[String: Any]]
                    print("Found \(files?.count ?? 0) files in metadata")
                    
                    if let files = files {
                        print("Found \(files.count) files")
                        
                        // Log all files for debugging
                        for (index, file) in files.enumerated() {
                            let format = file["format"] as? String ?? "unknown"
                            let name = file["name"] as? String ?? "unnamed"
                            print("File \(index): \(name) - Format: \(format)")
                        }
                        
                        // Find the best file to download - try multiple formats with priority order
                        var preferredFile: [String: Any]?
                        
                        // Priority order based on media type
                        let formatPriorities: [String]
                        switch item.mediatype.lowercased() {
                        case "audio":
                            formatPriorities = ["MP3", "mp3", "FLAC", "flac", "OGG", "ogg", "WAV", "wav"]
                        case "movies":
                            formatPriorities = ["MP4", "mp4", "AVI", "avi", "MOV", "mov", "MKV", "mkv"]
                        case "image":
                            formatPriorities = ["JPEG", "jpeg", "JPG", "jpg", "PNG", "png", "GIF", "gif", "TIFF", "tiff"]
                        default: // texts
                            formatPriorities = ["PDF", "pdf", "EPUB", "epub", "Text", "txt", "DjVu", "djvu"]
                        }
                        
                        for formatPriority in formatPriorities {
                            preferredFile = files.first { file in
                                let format = file["format"] as? String ?? ""
                                let name = file["name"] as? String ?? ""
                                
                                // Check format field
                                if format.lowercased().contains(formatPriority.lowercased()) {
                                    return true
                                }
                                
                                // Check file extension
                                if name.lowercased().hasSuffix(".\(formatPriority.lowercased())") {
                                    return true
                                }
                                
                                // Special cases for common naming patterns
                                if formatPriority.lowercased() == "pdf" {
                                    return name.contains("_text.pdf") || 
                                           name.contains("_bw.pdf") ||
                                           (name.contains(".pdf") && !name.contains("_meta"))
                                }
                                
                                if formatPriority.lowercased() == "txt" {
                                    return name.contains("_djvu.txt") || 
                                           name.contains("_text.txt")
                                }
                                
                                if formatPriority.lowercased() == "mp3" {
                                    return name.hasSuffix(".mp3") && !name.contains("_meta")
                                }
                                
                                if formatPriority.lowercased() == "mp4" {
                                    return name.hasSuffix(".mp4") && !name.contains("_meta")
                                }
                                
                                return false
                            }
                            
                            if preferredFile != nil {
                                print("Found file with format priority: \(formatPriority)")
                                break
                            }
                        }
                        
                        // Try preferred file first
                        if let file = preferredFile,
                           let fileName = file["name"] as? String {
                            let encodedFileName = fileName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? fileName
                            let downloadURL = URL(string: "\(self.baseURL)/download/\(item.identifier)/\(encodedFileName)")
                            print("Selected preferred file: \(fileName)")
                            print("Download URL: \(downloadURL?.absoluteString ?? "nil")")
                            completion(downloadURL)
                            return
                        }
                        
                        // Enhanced fallback: try any readable file with better filtering
                        let fallbackFile = files.first { file in
                            let format = file["format"] as? String ?? ""
                            let name = file["name"] as? String ?? ""
                            let size = file["size"] as? String ?? "0"
                            
                            // Skip obvious metadata and system files
                            if format.contains("Metadata") || 
                               format.contains("Log") ||
                               format.contains("Item") ||
                               name.contains("_files.xml") ||
                               name.contains("_meta.xml") ||
                               name.contains("_archive.torrent") ||
                               name.contains("__ia_thumb.jpg") ||
                               name.hasSuffix(".xml") ||
                               name.hasSuffix(".sqlite") ||
                               name.hasSuffix(".torrent") {
                                return false
                            }
                            
                            // Prefer files with substantial size based on media type
                            if let sizeInt = Int(size), sizeInt < 1000000 {
                                if item.mediatype == "texts" {
                                    // Skip very small files unless they're obviously text files
                                    if !name.hasSuffix(".txt") && !name.hasSuffix(".pdf") {
                                        return false
                                    }
                                } else if item.mediatype == "audio" {
                                    // Audio files should be reasonably sized (> 1MB)
                                    if !name.hasSuffix(".mp3") && !name.hasSuffix(".flac") && !name.hasSuffix(".ogg") {
                                        return false
                                    }
                                }
                            }
                            
                            // Accept common formats based on media type
                            let acceptableFormats: [String]
                            switch item.mediatype.lowercased() {
                            case "audio":
                                acceptableFormats = ["mp3", "flac", "ogg", "wav", "m4a"]
                            case "movies":
                                acceptableFormats = ["mp4", "avi", "mov", "mkv", "webm"]
                            case "image":
                                acceptableFormats = ["jpeg", "jpg", "png", "gif", "tiff", "bmp"]
                            default: // texts
                                acceptableFormats = ["pdf", "txt", "epub", "mobi", "djvu", "text", "html"]
                            }
                            let lowercaseFormat = format.lowercased()
                            let lowercaseName = name.lowercased()
                            
                            for acceptableFormat in acceptableFormats {
                                if lowercaseFormat.contains(acceptableFormat) || lowercaseName.hasSuffix(".\(acceptableFormat)") {
                                    return true
                                }
                            }
                            
                            return false
                        }
                        
                        if let file = fallbackFile,
                           let fileName = file["name"] as? String {
                            let encodedFileName = fileName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? fileName
                            let downloadURL = URL(string: "\(self.baseURL)/download/\(item.identifier)/\(encodedFileName)")
                            print("Selected fallback file: \(fileName)")
                            print("Download URL: \(downloadURL?.absoluteString ?? "nil")")
                            completion(downloadURL)
                            return
                        } else {
                            print("No downloadable file found - available formats:")
                            for file in files.prefix(5) {
                                print("  - \(file["name"] as? String ?? "unknown"): \(file["format"] as? String ?? "unknown")")
                            }
                        }
                    } else {
                        print("No files array found in metadata response")
                        print("Full response structure:")
                        if let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
                           let jsonString = String(data: jsonData, encoding: .utf8) {
                            print(String(jsonString.prefix(1000)))
                        }
                    }
                }
            } catch {
                print("Error parsing files: \(error)")
            }
            
            completion(nil)
        }.resume()
    }
    
    private struct SearchResponse: Codable {
        let response: ResponseData
        
        struct ResponseData: Codable {
            let docs: [Document]
        }
        
        struct Document: Codable {
            let identifier: String
            let title: String?
            let creator: StringOrArray?
            let date: String?
            let description: StringOrArray?
            let mediatype: String
        }
    }
    
    // Helper to handle fields that can be either String or [String]
    enum StringOrArray: Codable {
        case string(String)
        case array([String])
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let string = try? container.decode(String.self) {
                self = .string(string)
            } else if let array = try? container.decode([String].self) {
                self = .array(array)
            } else {
                throw DecodingError.typeMismatch(StringOrArray.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected String or [String]"))
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let string):
                try container.encode(string)
            case .array(let array):
                try container.encode(array)
            }
        }
        
        var stringValue: String {
            switch self {
            case .string(let s): return s
            case .array(let a): return a.joined(separator: ", ")
            }
        }
    }
    
    // MARK: - Curated Content Queries
    private func getCuratedQuery(for mediaType: MediaType) -> String {
        switch mediaType {
        case .music:
            return "q=(subject:classical+OR+subject:jazz+OR+subject:electronic+OR+subject:folk+OR+subject:ambient)+AND+mediatype:audio+AND+NOT+subject:audiobook+AND+NOT+collection:librivoxaudio"
            
        case .audiobooks:
            return "q=(subject:philosophy+OR+subject:stoicism+OR+subject:history+OR+subject:classics+OR+subject:fiction+OR+subject:science)+AND+mediatype:audio+AND+(collection:librivoxaudio+OR+subject:audiobook)"
            
        case .books:
            return "q=(subject:philosophy+OR+subject:stoicism+OR+subject:science+OR+subject:history+OR+subject:literature+OR+subject:classics)+AND+mediatype:texts"
            
        case .radio:
            return "q=(collection:oldtimeradio+OR+subject:\"old+time+radio\"+OR+subject:drama+OR+subject:comedy+OR+subject:talk)+AND+mediatype:audio"
        case .journal:
            return "" // Journal is local only, no archive.org query
        default:
            return ""
        }
    }
    
    private func getMediaTypeFilters(for mediaType: MediaType) -> String {
        switch mediaType {
        case .audiobooks:
            return "+AND+(collection:librivoxaudio+OR+subject:audiobook+OR+subject:\"audio+book\"+OR+collection:audio_bookspoetry)"
        case .music:
            return "+AND+NOT+collection:librivoxaudio+AND+NOT+subject:audiobook+AND+NOT+subject:\"audio+book\""
        case .books:
            return ""  // No additional filters needed, mediatype:texts is sufficient
        case .radio:
            return "+AND+(collection:oldtimeradio+OR+collection:radioprograms+OR+subject:\"old+time+radio\"+OR+subject:radio)"
        case .journal:
            return "" // Journal is local only, no archive.org filters
        default:
            return ""
        }
    }
}

// MARK: - Download Manager
class DownloadManager: NSObject, ObservableObject {
    static let shared = DownloadManager()
    
    @Published var activeDownloads: [String: DownloadTask] = [:]
    
    struct DownloadTask {
        let id: String
        let item: ArchiveOrgService.ArchiveItem
        var progress: Double = 0
        var isCompleted = false
        var localURL: URL?
    }
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    func download(_ item: ArchiveOrgService.ArchiveItem) {
        ArchiveOrgService.shared.downloadItem(item) { [weak self] url in
            guard let url = url else { return }
            
            DispatchQueue.main.async {
                let task = DownloadTask(id: item.id, item: item)
                self?.activeDownloads[item.id] = task
                
                let downloadTask = self?.session.downloadTask(with: url)
                downloadTask?.taskDescription = item.id
                downloadTask?.resume()
            }
        }
    }
}

extension DownloadManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let taskId = downloadTask.taskDescription,
              var task = activeDownloads[taskId] else { return }
        
        // Move file to documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsPath.appendingPathComponent("\(task.item.identifier).\(task.item.itemType == .pdf ? "pdf" : "mp3")")
        
        try? FileManager.default.removeItem(at: destinationURL)
        
        do {
            try FileManager.default.moveItem(at: location, to: destinationURL)
            
            DispatchQueue.main.async {
                task.localURL = destinationURL
                task.isCompleted = true
                task.progress = 1.0
                self.activeDownloads[taskId] = task
                
                // Add to library
                self.addToLibrary(task.item, localURL: destinationURL)
            }
        } catch {
            print("Error saving file: \(error)")
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let taskId = downloadTask.taskDescription,
              var task = activeDownloads[taskId] else { return }
        
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        
        DispatchQueue.main.async {
            task.progress = progress
            self.activeDownloads[taskId] = task
        }
    }
    
    private func addToLibrary(_ item: ArchiveOrgService.ArchiveItem, localURL: URL) {
        // Add to library - this would integrate with the Library system
        // For now, just save to UserDefaults or Core Data
        NotificationCenter.default.post(
            name: Notification.Name("LibraryItemAdded"),
            object: nil,
            userInfo: ["item": item, "url": localURL]
        )
    }
}