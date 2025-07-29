//
//  PremiumUpgradeView.swift
//  Librito
//
//  Premium upgrade promotional view
//

import SwiftUI
import StoreKit

struct PremiumUpgradeView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var premiumManager: PremiumManager = PremiumManager.shared
    @State private var selectedPlan = "monthly"
    @State private var isProcessingPurchase = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 30) {
                        // Header with app icon
                        VStack(spacing: 16) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 60))
                                .foregroundColor(.purple)
                                .padding()
                                .background(
                                    Circle()
                                        .fill(Color.purple.opacity(0.1))
                                        .frame(width: 100, height: 100)
                                )
                            
                            Text("Unlock LIBRITO Premium")
                                .font(.system(size: 32, weight: .bold))
                                .multilineTextAlignment(.center)
                            
                            Text("Experience the full power of your music library")
                                .font(.system(size: 18))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 30)
                        
                        // Features grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 20) {
                            FeatureCard(
                                icon: "infinity",
                                title: "Unlimited Library",
                                description: "No limits on your collection"
                            )
                            
                            FeatureCard(
                                icon: "wifi",
                                title: "Live Broadcast",
                                description: "Share what you're playing"
                            )
                            
                            FeatureCard(
                                icon: "person.3.fill",
                                title: "Music Rooms",
                                description: "Listen with friends"
                            )
                            
                            FeatureCard(
                                icon: "wand.and.stars",
                                title: "Smart Playlists",
                                description: "AI-powered recommendations"
                            )
                            
                            FeatureCard(
                                icon: "arrow.down.circle.fill",
                                title: "Unlimited Pins",
                                description: "Save offline without limits"
                            )
                            
                            FeatureCard(
                                icon: "paintpalette.fill",
                                title: "Profile Themes",
                                description: "Customize your experience"
                            )
                        }
                        .padding(.horizontal)
                        
                        // Pricing options
                        VStack(spacing: 16) {
                            Text("Choose Your Plan")
                                .font(.system(size: 24, weight: .semibold))
                            
                            HStack(spacing: 16) {
                                PricingOption(
                                    title: "Monthly",
                                    price: "$4.99",
                                    period: "per month",
                                    isSelected: selectedPlan == "monthly",
                                    action: { selectedPlan = "monthly" }
                                )
                                
                                PricingOption(
                                    title: "Yearly",
                                    price: "$39.99",
                                    period: "per year",
                                    savings: "Save 33%",
                                    isSelected: selectedPlan == "yearly",
                                    action: { selectedPlan = "yearly" }
                                )
                            }
                            .padding(.horizontal)
                        }
                        
                        // Purchase button
                        Button(action: processPurchase) {
                            HStack {
                                if isProcessingPurchase {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Start Free Trial")
                                        .font(.system(size: 20, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Color.purple, Color.pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                        .disabled(isProcessingPurchase)
                        
                        // Terms
                        VStack(spacing: 8) {
                            Text("7-day free trial, then \(selectedPlan == "monthly" ? "$4.99/month" : "$39.99/year")")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 16) {
                                Button("Privacy Policy") {
                                    // Open privacy policy
                                }
                                .font(.system(size: 12))
                                
                                Button("Terms of Service") {
                                    // Open terms
                                }
                                .font(.system(size: 12))
                                
                                Button("Restore Purchases") {
                                    restorePurchases()
                                }
                                .font(.system(size: 12))
                            }
                        }
                        .padding(.bottom, 30)
                    }
                }
                .frame(width: geometry.size.width)
            }
            .navigationBarItems(
                trailing: Button("Not Now") {
                    dismiss()
                }
            )
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func processPurchase() {
        isProcessingPurchase = true
        
        // TODO: Implement StoreKit purchase
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isProcessingPurchase = false
            
            // For demo: just enable premium
            premiumManager.setPremiumStatus(true)
            dismiss()
        }
    }
    
    private func restorePurchases() {
        // TODO: Implement StoreKit restore
    }
}

// MARK: - Feature Card
struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.purple)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Pricing Option
struct PricingOption: View {
    let title: String
    let price: String
    let period: String
    var savings: String? = nil
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if let savings = savings {
                    Text(savings)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .cornerRadius(12)
                }
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                
                Text(price)
                    .font(.system(size: 24, weight: .bold))
                
                Text(period)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.purple : Color(.systemGray4), lineWidth: isSelected ? 3 : 1)
            )
            .background(
                isSelected ? Color.purple.opacity(0.05) : Color.clear
            )
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PremiumUpgradeView()
}