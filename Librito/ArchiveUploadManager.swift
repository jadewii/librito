//
//  ArchiveUploadManager.swift
//  Librito
//
//  Manages uploads to Archive.org with proper authentication and metadata
//

import Foundation
import SwiftUI
import CryptoKit

// MARK: - Archive Upload Manager
@MainActor
class ArchiveUploadManager: ObservableObject {
    static let shared = ArchiveUploadManager()
    
    @Published var isAuthenticated = false
    @Published var uploadProgress: Double = 0
    @Published var isUploading = false
    @Published var uploadError: String?
    
    // User's Archive.org credentials (stored in Keychain in production)
    private var accessKey: String?
    private var secretKey: String?
    
    private init() {
        loadCredentials()
    }
    
    // MARK: - Authentication
    func authenticate(email: String, password: String) async throws {
        // In production: Use Archive.org's auth API to get S3 credentials
        // For now, we'll simulate the authentication flow
        
        // Archive.org uses S3-compatible API with user-specific keys
        // Users get these from https://archive.org/account/s3.php
        
        // This would make an API call to verify credentials
        // and retrieve the S3 access/secret keys
        
        self.isAuthenticated = true
    }
    
    func setS3Credentials(accessKey: String, secretKey: String) {
        self.accessKey = accessKey
        self.secretKey = secretKey
        saveCredentials()
        isAuthenticated = true
    }
    
    // MARK: - Upload Functions
    func uploadMusicTrack(
        fileURL: URL,
        title: String,
        artist: String,
        album: String? = nil,
        year: String? = nil,
        genre: String? = nil,
        description: String? = nil,
        isOriginalContent: Bool,
        license: CreativeCommonsLicense,
        privacy: UploadPrivacy = .public
    ) async throws -> String {
        
        guard isAuthenticated else {
            throw UploadError.notAuthenticated
        }
        
        guard isOriginalContent || license != .allRightsReserved else {
            throw UploadError.invalidLicense
        }
        
        // Generate unique identifier for the item
        let identifier = generateIdentifier(title: title, artist: artist)
        
        // Prepare metadata
        let metadata = prepareMetadata(
            title: title,
            artist: artist,
            album: album,
            year: year,
            genre: genre,
            description: description,
            license: license,
            privacy: privacy
        )
        
        // Upload to Archive.org
        return try await performUpload(
            fileURL: fileURL,
            identifier: identifier,
            metadata: metadata
        )
    }
    
    // MARK: - Private Methods
    private func generateIdentifier(title: String, artist: String) -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let clean = { (str: String) -> String in
            str.lowercased()
                .replacingOccurrences(of: " ", with: "-")
                .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
        }
        return "librito-\(clean(artist))-\(clean(title))-\(timestamp)"
    }
    
    private func prepareMetadata(
        title: String,
        artist: String,
        album: String?,
        year: String?,
        genre: String?,
        description: String?,
        license: CreativeCommonsLicense,
        privacy: UploadPrivacy
    ) -> [String: String] {
        var metadata: [String: String] = [
            "title": title,
            "creator": artist,
            "mediatype": "audio",
            "collection": privacy == .public ? "opensource_audio" : "opensource_audio",
            "uploader": "LIBRITO App",
            "licenseurl": license.url
        ]
        
        // Set access restrictions based on privacy
        switch privacy {
        case .private:
            metadata["access-restricted"] = "true"
            metadata["access-restricted-item"] = "true"
        case .unlisted:
            metadata["noindex"] = "true"
            metadata["hidden"] = "true"
        case .public:
            break // Default is public
        }
        
        if let album = album { metadata["album"] = album }
        if let year = year { metadata["year"] = year }
        if let genre = genre { metadata["subject"] = genre }
        if let description = description { 
            metadata["description"] = description + "\n\nUploaded via LIBRITO App"
        } else {
            metadata["description"] = "Uploaded via LIBRITO App"
        }
        
        return metadata
    }
    
    private func performUpload(
        fileURL: URL,
        identifier: String,
        metadata: [String: String]
    ) async throws -> String {
        
        // Archive.org S3 endpoint
        let endpoint = "https://s3.us.archive.org"
        let bucket = identifier
        
        // Create the item first with metadata
        let createURL = URL(string: "\(endpoint)/\(bucket)")!
        var createRequest = URLRequest(url: createURL)
        createRequest.httpMethod = "PUT"
        
        // Add authentication headers (S3 style)
        // In production: Implement proper S3 signature
        if let accessKey = accessKey {
            createRequest.setValue("LOW \(accessKey):\(secretKey ?? "")", forHTTPHeaderField: "Authorization")
        }
        
        // Add metadata headers
        for (key, value) in metadata {
            createRequest.setValue(value, forHTTPHeaderField: "x-archive-meta-\(key)")
        }
        
        // Upload the file
        let fileData = try Data(contentsOf: fileURL)
        let fileName = fileURL.lastPathComponent
        let uploadURL = URL(string: "\(endpoint)/\(bucket)/\(fileName)")!
        
        var uploadRequest = URLRequest(url: uploadURL)
        uploadRequest.httpMethod = "PUT"
        uploadRequest.httpBody = fileData
        
        // Add authentication
        if let accessKey = accessKey {
            uploadRequest.setValue("LOW \(accessKey):\(secretKey ?? "")", forHTTPHeaderField: "Authorization")
        }
        
        // Simulate upload progress
        self.isUploading = true
        self.uploadProgress = 0
        
        // In production: Use URLSession with delegate for progress
        let (_, response) = try await URLSession.shared.data(for: uploadRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw UploadError.uploadFailed
        }
        
        self.isUploading = false
        self.uploadProgress = 1.0
        
        // Return the Archive.org URL
        return "https://archive.org/details/\(identifier)"
    }
    
    // MARK: - Credential Management
    private func saveCredentials() {
        // In production: Save to Keychain
        UserDefaults.standard.set(accessKey, forKey: "archive_access_key")
        UserDefaults.standard.set(secretKey, forKey: "archive_secret_key")
    }
    
    private func loadCredentials() {
        // In production: Load from Keychain
        accessKey = UserDefaults.standard.string(forKey: "archive_access_key")
        secretKey = UserDefaults.standard.string(forKey: "archive_secret_key")
        isAuthenticated = accessKey != nil && secretKey != nil
    }
    
    func logout() {
        accessKey = nil
        secretKey = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "archive_access_key")
        UserDefaults.standard.removeObject(forKey: "archive_secret_key")
    }
}

// MARK: - Upload Privacy
enum UploadPrivacy: String, CaseIterable {
    case `public` = "public"
    case unlisted = "unlisted"
    case `private` = "private"
    
    var displayName: String {
        switch self {
        case .public: return "Public"
        case .unlisted: return "Unlisted"
        case .private: return "Private"
        }
    }
    
    var description: String {
        switch self {
        case .public: return "Anyone can find and play your music"
        case .unlisted: return "Only people with the link can access"
        case .private: return "Only you can access (requires login)"
        }
    }
    
    var icon: String {
        switch self {
        case .public: return "globe"
        case .unlisted: return "link"
        case .private: return "lock.fill"
        }
    }
}

// MARK: - Upload Errors
enum UploadError: LocalizedError {
    case notAuthenticated
    case invalidLicense
    case uploadFailed
    case invalidFile
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please authenticate with Archive.org first"
        case .invalidLicense:
            return "You must own the content or select a Creative Commons license"
        case .uploadFailed:
            return "Upload failed. Please try again."
        case .invalidFile:
            return "Invalid file format"
        }
    }
}

// MARK: - Creative Commons Licenses
enum CreativeCommonsLicense: String, CaseIterable {
    case cc0 = "CC0"
    case ccBy = "CC BY"
    case ccBySa = "CC BY-SA"
    case ccByNc = "CC BY-NC"
    case ccByNcSa = "CC BY-NC-SA"
    case ccByNd = "CC BY-ND"
    case ccByNcNd = "CC BY-NC-ND"
    case allRightsReserved = "All Rights Reserved"
    
    var displayName: String {
        switch self {
        case .cc0: return "Public Domain (CC0)"
        case .ccBy: return "Attribution (CC BY)"
        case .ccBySa: return "Attribution-ShareAlike (CC BY-SA)"
        case .ccByNc: return "Attribution-NonCommercial (CC BY-NC)"
        case .ccByNcSa: return "Attribution-NonCommercial-ShareAlike (CC BY-NC-SA)"
        case .ccByNd: return "Attribution-NoDerivatives (CC BY-ND)"
        case .ccByNcNd: return "Attribution-NonCommercial-NoDerivatives (CC BY-NC-ND)"
        case .allRightsReserved: return "All Rights Reserved (No Upload)"
        }
    }
    
    var url: String {
        switch self {
        case .cc0: return "https://creativecommons.org/publicdomain/zero/1.0/"
        case .ccBy: return "https://creativecommons.org/licenses/by/4.0/"
        case .ccBySa: return "https://creativecommons.org/licenses/by-sa/4.0/"
        case .ccByNc: return "https://creativecommons.org/licenses/by-nc/4.0/"
        case .ccByNcSa: return "https://creativecommons.org/licenses/by-nc-sa/4.0/"
        case .ccByNd: return "https://creativecommons.org/licenses/by-nd/4.0/"
        case .ccByNcNd: return "https://creativecommons.org/licenses/by-nc-nd/4.0/"
        case .allRightsReserved: return ""
        }
    }
    
    var description: String {
        switch self {
        case .cc0: return "Free to use for any purpose"
        case .ccBy: return "Free to use with attribution"
        case .ccBySa: return "Free to use with attribution, derivatives must share alike"
        case .ccByNc: return "Free for non-commercial use with attribution"
        case .ccByNcSa: return "Free for non-commercial use with attribution, share alike"
        case .ccByNd: return "Free to use with attribution, no derivatives"
        case .ccByNcNd: return "Free for non-commercial use with attribution, no derivatives"
        case .allRightsReserved: return "Cannot be uploaded to Archive.org"
        }
    }
}

// MARK: - Archive Upload View
struct ArchiveUploadView: View {
    @StateObject private var uploadManager = ArchiveUploadManager.shared
    @State private var showingFilePicker = false
    @State private var selectedFile: URL?
    @State private var title = ""
    @State private var artist = ""
    @State private var album = ""
    @State private var year = ""
    @State private var genre = ""
    @State private var description = ""
    @State private var isOriginalContent = false
    @State private var selectedLicense = CreativeCommonsLicense.ccBy
    @State private var selectedPrivacy = UploadPrivacy.public
    @State private var showingAuthSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Upload to Archive.org")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("Share your music with the world through Archive.org")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                
                if !uploadManager.isAuthenticated {
                    // Authentication required
                    VStack(spacing: 16) {
                        Image(systemName: "building.columns")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Connect your Archive.org account")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Text("You'll need your S3-like API keys from Archive.org")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Button(action: { showingAuthSheet = true }) {
                            Text("Connect Account")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.black)
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                } else {
                    // Upload form
                    VStack(alignment: .leading, spacing: 20) {
                        // File selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Audio File")
                                .font(.system(size: 16, weight: .medium))
                            
                            Button(action: { showingFilePicker = true }) {
                                HStack {
                                    Image(systemName: "music.note")
                                        .foregroundColor(.gray)
                                    Text(selectedFile?.lastPathComponent ?? "Choose file...")
                                        .foregroundColor(selectedFile != nil ? .black : .gray)
                                    Spacer()
                                }
                                .padding()
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Metadata fields
                        VStack(alignment: .leading, spacing: 16) {
                            TextField("Title *", text: $title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Artist *", text: $artist)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Album", text: $album)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            HStack(spacing: 16) {
                                TextField("Year", text: $year)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                TextField("Genre", text: $genre)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Description")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                TextEditor(text: $description)
                                    .frame(height: 100)
                                    .padding(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                        
                        // Privacy settings
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Privacy Settings")
                                .font(.system(size: 18, weight: .semibold))
                            
                            ForEach(UploadPrivacy.allCases, id: \.self) { privacy in
                                Button(action: { selectedPrivacy = privacy }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: privacy.icon)
                                            .font(.system(size: 20))
                                            .foregroundColor(selectedPrivacy == privacy ? .white : .gray)
                                            .frame(width: 24)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(privacy.displayName)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(selectedPrivacy == privacy ? .white : .black)
                                            
                                            Text(privacy.description)
                                                .font(.system(size: 12))
                                                .foregroundColor(selectedPrivacy == privacy ? .white.opacity(0.8) : .gray)
                                        }
                                        
                                        Spacer()
                                        
                                        if selectedPrivacy == privacy {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .padding(12)
                                    .background(selectedPrivacy == privacy ? Color.black : Color.gray.opacity(0.05))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.bottom, 8)
                        
                        // Copyright section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Copyright & License")
                                .font(.system(size: 18, weight: .semibold))
                            
                            Toggle(isOn: $isOriginalContent) {
                                Text("This is my original content")
                                    .font(.system(size: 16))
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("License")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                
                                Picker("License", selection: $selectedLicense) {
                                    ForEach(CreativeCommonsLicense.allCases, id: \.self) { license in
                                        if license != .allRightsReserved {
                                            Text(license.displayName).tag(license)
                                        }
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(8)
                                
                                Text(selectedLicense.description)
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(8)
                        
                        // Upload button
                        Button(action: uploadTrack) {
                            HStack {
                                if uploadManager.isUploading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.up.circle.fill")
                                    Text("Upload to Archive.org")
                                }
                            }
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(canUpload ? Color.black : Color.gray)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(!canUpload || uploadManager.isUploading)
                        
                        if uploadManager.uploadProgress > 0 && uploadManager.uploadProgress < 1 {
                            ProgressView(value: uploadManager.uploadProgress)
                                .progressViewStyle(LinearProgressViewStyle(tint: .black))
                        }
                        
                        if let error = uploadManager.uploadError {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingAuthSheet) {
            ArchiveAuthView()
        }
    }
    
    private var canUpload: Bool {
        selectedFile != nil &&
        !title.isEmpty &&
        !artist.isEmpty &&
        isOriginalContent &&
        selectedLicense != .allRightsReserved
    }
    
    private func uploadTrack() {
        guard let fileURL = selectedFile else { return }
        
        Task {
            do {
                let archiveURL = try await uploadManager.uploadMusicTrack(
                    fileURL: fileURL,
                    title: title,
                    artist: artist,
                    album: album.isEmpty ? nil : album,
                    year: year.isEmpty ? nil : year,
                    genre: genre.isEmpty ? nil : genre,
                    description: description.isEmpty ? nil : description,
                    isOriginalContent: isOriginalContent,
                    license: selectedLicense,
                    privacy: selectedPrivacy
                )
                
                print("Successfully uploaded to: \(archiveURL)")
                // Reset form
                resetForm()
            } catch {
                uploadManager.uploadError = error.localizedDescription
            }
        }
    }
    
    private func resetForm() {
        selectedFile = nil
        title = ""
        artist = ""
        album = ""
        year = ""
        genre = ""
        description = ""
        isOriginalContent = false
        selectedLicense = .ccBy
        selectedPrivacy = .public
    }
}

// MARK: - Archive Auth View
struct ArchiveAuthView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var uploadManager = ArchiveUploadManager.shared
    @State private var accessKey = ""
    @State private var secretKey = ""
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Connect Archive.org Account")
                        .font(.system(size: 24, weight: .bold))
                    
                    Text("Enter your S3-like API keys from Archive.org")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("How to get your keys:")
                        .font(.system(size: 14, weight: .medium))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Log in to Archive.org", systemImage: "1.circle.fill")
                        Label("Go to archive.org/account/s3.php", systemImage: "2.circle.fill")
                        Label("Copy your Access and Secret keys", systemImage: "3.circle.fill")
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
                
                VStack(spacing: 16) {
                    SecureField("Access Key", text: $accessKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    SecureField("Secret Key", text: $secretKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Spacer()
                
                Button(action: authenticate) {
                    Text("Connect")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(!accessKey.isEmpty && !secretKey.isEmpty ? Color.black : Color.gray)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(accessKey.isEmpty || secretKey.isEmpty)
            }
            .padding()
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
            )
        }
    }
    
    private func authenticate() {
        uploadManager.setS3Credentials(accessKey: accessKey, secretKey: secretKey)
        dismiss()
    }
}

#Preview {
    ArchiveUploadView()
}