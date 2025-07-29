//
//  ContentSafetySettingsView.swift
//  Librito
//
//  Settings view for content safety and legal compliance
//

import SwiftUI

struct ContentSafetySettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 28))
                                .foregroundColor(.green)
                            Text("Content Safety")
                                .font(.system(size: 24, weight: .bold))
                        }
                        
                        Text("Legal compliance and content protection")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    
                    // Legal Disclaimer
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Legal Notice")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Text(ContentSafetyService.legalDisclaimer)
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                            .lineSpacing(4)
                            .padding(16)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    // Safety Indicators
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Content Safety Indicators")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)
                        
                        VStack(spacing: 12) {
                            SafetyIndicatorRow(
                                icon: "checkmark.shield.fill",
                                color: .green,
                                title: "Public Domain",
                                description: "Verified safe content. All premium features available."
                            )
                            
                            SafetyIndicatorRow(
                                icon: "exclamationmark.triangle.fill",
                                color: .orange,
                                title: "Uncertain Status",
                                description: "Copyright status unclear. Basic streaming only."
                            )
                            
                            SafetyIndicatorRow(
                                icon: "xmark.shield.fill",
                                color: .red,
                                title: "Rights Restricted",
                                description: "Known copyright restrictions. Basic streaming only."
                            )
                        }
                    }
                    
                    // Safe Collections
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Trusted Sources")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Text("Premium features are only available for content from these verified public domain sources:")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            SafeSourceChip(name: "LibriVox")
                            SafeSourceChip(name: "Project Gutenberg")
                            SafeSourceChip(name: "UC Berkeley")
                            SafeSourceChip(name: "Smithsonian")
                            SafeSourceChip(name: "Prelinger Archives")
                            SafeSourceChip(name: "Old Time Radio")
                            SafeSourceChip(name: "Folklife Center")
                            SafeSourceChip(name: "Pre-1923 Works")
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(24)
            }
            .navigationTitle("Content Safety")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

struct SafetyIndicatorRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct SafeSourceChip: View {
    let name: String
    
    var body: some View {
        Text(name)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.green)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.green.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
    }
}

#Preview {
    ContentSafetySettingsView()
}