//
//  SimpleStationDetailView.swift
//  Librito
//
//  Simple station detail view to avoid compiler issues
//

import SwiftUI

struct SimpleStationDetailView: View {
    let station: MusicStation
    @ObservedObject var downloadManager: StationDownloadManager
    let onClose: () -> Void
    @State private var shouldShowPlayer = false
    
    var downloadState: StationDownloadState {
        downloadManager.downloadStates[station.id] ?? .notDownloaded
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerView
            
            // Station Info
            stationInfoView
            
            // Action Buttons
            actionButtonsView
            
            Spacer()
        }
        .padding()
        .background(station.color.ignoresSafeArea())
        .fullScreenCover(isPresented: $shouldShowPlayer) {
            playerView
        }
    }
    
    private var headerView: some View {
        HStack {
            Button("CLOSE") {
                onClose()
            }
            .foregroundColor(.white)
            .font(.headline)
            
            Spacer()
            
            if case .downloaded = downloadState {
                Button("DELETE") {
                    downloadManager.deleteDownload(station)
                }
                .foregroundColor(.white.opacity(0.7))
                .font(.headline)
            }
        }
    }
    
    private var stationInfoView: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note")
                .font(.system(size: 80, weight: .heavy))
                .foregroundColor(.white)
                .frame(width: 160, height: 160)
                .background(Color.white.opacity(0.2))
                .overlay(
                    Rectangle()
                        .stroke(Color.white, lineWidth: 4)
                )
            
            Text(station.name)
                .font(.system(size: 28, weight: .heavy))
                .foregroundColor(.white)
            
            Text(station.description)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
    }
    
    private var actionButtonsView: some View {
        VStack(spacing: 16) {
            switch downloadState {
            case .notDownloaded:
                Button("DOWNLOAD") {
                    downloadManager.downloadStation(station)
                }
                .foregroundColor(.white)
                .font(.headline)
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(8)
                
            case .downloading(let progress):
                VStack {
                    Text("DOWNLOADING...")
                        .foregroundColor(.white)
                        .font(.headline)
                    
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .scaleEffect(y: 2)
                }
                .padding()
                
            case .downloaded:
                Button("PLAY") {
                    shouldShowPlayer = true
                }
                .foregroundColor(.white)
                .font(.headline)
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(8)
                
            case .failed:
                Button("RETRY") {
                    downloadManager.downloadStation(station)
                }
                .foregroundColor(.white)
                .font(.headline)
                .padding()
                .background(Color.red.opacity(0.3))
                .cornerRadius(8)
            }
        }
    }
    
    private var playerView: some View {
        VStack {
            Text("Playing: \(station.name)")
                .font(.title)
                .padding()
            
            Button("Close") {
                shouldShowPlayer = false
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.9))
    }
}