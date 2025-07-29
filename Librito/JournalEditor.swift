//
//  JournalEditor.swift
//  Librito
//
//  Document editor for the Journal feature
//

import SwiftUI

struct JournalEditor: View {
    @Binding var document: JournalDocument
    @Binding var showingSidebar: Bool
    @StateObject private var journalManager = JournalManager.shared
    @State private var isEditing = false
    @State private var showingExportMenu = false
    @State private var showingPaperStylePicker = false
    @State private var showingEmojiPicker = false
    @State private var showingTagEditor = false
    @State private var exportResult: ExportResult?
    @FocusState private var isFocused: Bool
    
    struct ExportResult: Identifiable {
        let id = UUID()
        let message: String
        let success: Bool
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Paper background
                document.paperStyle.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Editor toolbar
                    editorToolbar
                        .background(Color.white.opacity(0.95))
                    
                    Divider()
                    
                    // Document content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Document header
                            documentHeader
                                .padding(.horizontal, 40)
                                .padding(.top, 30)
                            
                            // Document body
                            TextEditor(text: $document.content)
                                .scrollContentBackground(.hidden)
                                .font(.system(size: 16))
                                .foregroundColor(.black)
                                .focused($isFocused)
                                .frame(minHeight: geometry.size.height - 200)
                                .padding(.horizontal, 40)
                                .padding(.bottom, 40)
                                .onChange(of: document.content) { oldValue, newValue in
                                    document.modifiedDate = Date()
                                }
                        }
                    }
                }
            }
        }
        .alert(item: $exportResult) { result in
            Alert(
                title: Text(result.success ? "Export Successful" : "Export Failed"),
                message: Text(result.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            isFocused = true
        }
    }
    
    // MARK: - Editor Toolbar
    var editorToolbar: some View {
        HStack(spacing: 16) {
            // Toggle sidebar
            Button(action: { showingSidebar.toggle() }) {
                Image(systemName: showingSidebar ? "sidebar.left" : "sidebar.left.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.black)
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider()
                .frame(height: 20)
            
            // Paper style
            Button(action: { showingPaperStylePicker = true }) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(document.paperStyle.backgroundColor)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    Text("Paper")
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .popover(isPresented: $showingPaperStylePicker) {
                PaperStylePicker(selectedStyle: $document.paperStyle)
                    .frame(width: 300, height: 200)
            }
            
            // Tags
            Button(action: { showingTagEditor = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "tag")
                        .font(.system(size: 16))
                    Text(document.tags.isEmpty ? "Add Tags" : "\(document.tags.count) Tags")
                        .font(.system(size: 14))
                }
                .foregroundColor(.black)
            }
            .buttonStyle(PlainButtonStyle())
            .popover(isPresented: $showingTagEditor) {
                TagEditor(tags: $document.tags)
                    .frame(width: 300, height: 400)
            }
            
            Spacer()
            
            // Last modified
            Text("Modified \(document.modifiedDate.formatted(.relative(presentation: .named)))")
                .font(.system(size: 12))
                .foregroundColor(.gray)
            
            // Export
            Button(action: { showingExportMenu = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                    Text("Export")
                        .font(.system(size: 14))
                }
                .foregroundColor(.black)
            }
            .buttonStyle(PlainButtonStyle())
            .popover(isPresented: $showingExportMenu) {
                ExportMenu(document: document, exportResult: $exportResult)
                    .frame(width: 200, height: 250)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    // MARK: - Document Header
    var documentHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                // Emoji picker
                Button(action: { showingEmojiPicker = true }) {
                    if let emoji = document.emoji {
                        Text(emoji)
                            .font(.system(size: 32))
                    } else {
                        Image(systemName: "face.smiling")
                            .font(.system(size: 28))
                            .foregroundColor(.gray)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .popover(isPresented: $showingEmojiPicker) {
                    EmojiPicker(selectedEmoji: $document.emoji)
                        .frame(width: 400, height: 300)
                }
                
                // Title
                TextField("Untitled", text: $document.title)
                    .font(.system(size: 32, weight: .bold))
                    .textFieldStyle(PlainTextFieldStyle())
                    .onChange(of: document.title) { oldValue, newValue in
                        document.modifiedDate = Date()
                    }
            }
            
            // Tags display
            if !document.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(document.tags, id: \.self) { tag in
                            TagChip(tag: tag, onDelete: {
                                document.tags.removeAll { $0 == tag }
                            })
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Paper Style Picker
struct PaperStylePicker: View {
    @Binding var selectedStyle: PaperStyle
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Choose Paper Style")
                .font(.system(size: 16, weight: .semibold))
                .padding(.top, 16)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(PaperStyle.allCases, id: \.self) { style in
                    Button(action: {
                        selectedStyle = style
                        dismiss()
                    }) {
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(style.backgroundColor)
                                .frame(height: 60)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedStyle == style ? Color.black : Color.gray.opacity(0.3), lineWidth: selectedStyle == style ? 2 : 1)
                                )
                            
                            Text(style.displayName)
                                .font(.system(size: 12))
                                .foregroundColor(.black)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            
            Spacer()
        }
    }
}

// MARK: - Tag Editor
struct TagEditor: View {
    @Binding var tags: [String]
    @State private var newTag = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Tags")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                Button("Done") { dismiss() }
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Add new tag
            HStack {
                TextField("Add a tag...", text: $newTag)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        addTag()
                    }
                
                Button(action: addTag) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(newTag.isEmpty)
            }
            .padding(.horizontal, 16)
            
            // Existing tags
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        HStack {
                            Text(tag)
                                .font(.system(size: 14))
                            
                            Spacer()
                            
                            Button(action: {
                                tags.removeAll { $0 == tag }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16)
            }
            
            Spacer()
        }
    }
    
    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !tags.contains(trimmed) {
            tags.append(trimmed)
            newTag = ""
        }
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let tag: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.system(size: 12))
                .foregroundColor(.black)
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Emoji Picker
struct EmojiPicker: View {
    @Binding var selectedEmoji: String?
    @Environment(\.dismiss) var dismiss
    
    let emojis = [
        "📝", "✏️", "🖊️", "🖋️", "📄", "📃", "📑", "🗒️",
        "📓", "📔", "📕", "📗", "📘", "📙", "📚", "📖",
        "🔖", "🏷️", "💭", "💡", "🌟", "⭐", "✨", "🎯",
        "🎨", "🌈", "🌸", "🌺", "🌻", "🌷", "🌹", "🌿",
        "🍃", "🌱", "🌳", "🌴", "🌵", "🍀", "☘️", "🌾",
        "☀️", "🌤️", "⛅", "☁️", "🌧️", "⛈️", "🌩️", "❄️",
        "💖", "💝", "💗", "💓", "💕", "💞", "💘", "❤️"
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Choose an Emoji")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                Button("Remove") {
                    selectedEmoji = nil
                    dismiss()
                }
                .font(.system(size: 14))
                .foregroundColor(.red)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(emojis, id: \.self) { emoji in
                    Button(action: {
                        selectedEmoji = emoji
                        dismiss()
                    }) {
                        Text(emoji)
                            .font(.system(size: 28))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            
            Spacer()
        }
    }
}

// MARK: - Export Menu
struct ExportMenu: View {
    let document: JournalDocument
    @Binding var exportResult: JournalEditor.ExportResult?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Export Document")
                .font(.system(size: 16, weight: .semibold))
                .padding(.vertical, 16)
            
            Divider()
            
            VStack(spacing: 0) {
                ExportOption(title: "PDF Document", icon: "doc.fill", action: {
                    exportAsPDF()
                })
                
                ExportOption(title: "Word Document", icon: "doc.richtext", action: {
                    exportAsDocx()
                })
                
                ExportOption(title: "Plain Text", icon: "doc.text", action: {
                    exportAsTxt()
                })
                
                ExportOption(title: "Markdown", icon: "doc.badge.gearshape", action: {
                    exportAsMarkdown()
                })
            }
            
            Spacer()
        }
    }
    
    private func exportAsPDF() {
        // TODO: Implement PDF export
        exportResult = JournalEditor.ExportResult(
            message: "PDF export will be implemented soon",
            success: false
        )
        dismiss()
    }
    
    private func exportAsDocx() {
        // TODO: Implement DOCX export
        exportResult = JournalEditor.ExportResult(
            message: "Word document export will be implemented soon",
            success: false
        )
        dismiss()
    }
    
    private func exportAsTxt() {
        let content = """
        \(document.title)
        
        \(document.content)
        
        ---
        Created: \(document.createdDate.formatted())
        Modified: \(document.modifiedDate.formatted())
        Tags: \(document.tags.joined(separator: ", "))
        """
        
        saveToFile(content: content, filename: "\(document.title).txt")
    }
    
    private func exportAsMarkdown() {
        let content = """
        # \(document.title)
        
        \(document.content)
        
        ---
        
        **Created:** \(document.createdDate.formatted())  
        **Modified:** \(document.modifiedDate.formatted())  
        **Tags:** \(document.tags.joined(separator: ", "))
        """
        
        saveToFile(content: content, filename: "\(document.title).md")
    }
    
    private func saveToFile(content: String, filename: String) {
        #if os(macOS)
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = filename
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
                exportResult = JournalEditor.ExportResult(
                    message: "Document exported successfully",
                    success: true
                )
            } catch {
                exportResult = JournalEditor.ExportResult(
                    message: "Failed to export: \(error.localizedDescription)",
                    success: false
                )
            }
        }
        #else
        // iOS implementation
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            exportResult = JournalEditor.ExportResult(
                message: "Document saved to Files app",
                success: true
            )
        } catch {
            exportResult = JournalEditor.ExportResult(
                message: "Failed to export: \(error.localizedDescription)",
                success: false
            )
        }
        #endif
        
        dismiss()
    }
}

// MARK: - Export Option
struct ExportOption: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color.gray.opacity(0.05))
    }
}

#Preview {
    JournalEditor(
        document: .constant(JournalDocument(title: "Sample Document", content: "This is a sample document content.", paperStyle: .blushPink)),
        showingSidebar: .constant(true)
    )
}