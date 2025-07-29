//
//  OscilloscopeVisualizer.swift
//  Librito
//
//  Audio visualization component with oscilloscope waveform animation
//

import SwiftUI
import AVFoundation
import Accelerate

struct OscilloscopeVisualizer: View {
    let player: AVPlayer?
    let isPlaying: Bool
    @State private var waveformData: [Float] = Array(repeating: 0.0, count: 64)
    @State private var animationTimer: Timer?
    @State private var phase: Float = 0.0
    @StateObject private var audioAnalyzer = AudioAnalyzer()
    
    var body: some View {
        Canvas { context, size in
            drawOscilloscope(context: context, size: size)
        }
        .frame(height: 60)
        .onAppear {
            if isPlaying {
                startVisualization()
            }
        }
        .onDisappear {
            stopVisualization()
        }
        .onChange(of: isPlaying) { oldValue, newValue in
            if newValue {
                startVisualization()
            } else {
                stopVisualization()
            }
        }
        .onChange(of: player) { oldValue, newValue in
            audioAnalyzer.setPlayer(newValue)
        }
    }
    
    private func drawOscilloscope(context: GraphicsContext, size: CGSize) {
        let width = size.width
        let height = size.height
        let centerY = height / 2
        
        // Create path for waveform
        var path = Path()
        
        for i in 0..<waveformData.count {
            let x = (width / CGFloat(waveformData.count - 1)) * CGFloat(i)
            let amplitude = CGFloat(waveformData[i]) * (height * 0.4)
            let y = centerY + amplitude
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        // Draw the waveform with gradient
        let gradient = Gradient(colors: [
            Color.blue.opacity(0.8),
            Color.purple.opacity(0.6),
            Color.pink.opacity(0.4)
        ])
        
        context.stroke(
            path,
            with: .linearGradient(
                gradient,
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: size.width, y: 0)
            ),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
        )
        
        // Add center line
        let centerLine = Path { path in
            path.move(to: CGPoint(x: 0, y: centerY))
            path.addLine(to: CGPoint(x: width, y: centerY))
        }
        
        context.stroke(
            centerLine,
            with: .color(.gray.opacity(0.3)),
            style: StrokeStyle(lineWidth: 0.5)
        )
    }
    
    private func startVisualization() {
        guard isPlaying else { return }
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { _ in
            updateWaveform()
        }
    }
    
    private func stopVisualization() {
        animationTimer?.invalidate()
        animationTimer = nil
        
        // Fade out the waveform
        withAnimation(.easeOut(duration: 0.5)) {
            waveformData = Array(repeating: 0.0, count: waveformData.count)
        }
    }
    
    private func updateWaveform() {
        withAnimation(.easeInOut(duration: 0.1)) {
            if let realTimeData = audioAnalyzer.getRealtimeData() {
                waveformData = realTimeData
            } else {
                // Generate synthetic waveform when no real audio data
                generateSyntheticWaveform()
            }
        }
    }
    
    private func generateSyntheticWaveform() {
        phase += 0.2
        
        for i in 0..<waveformData.count {
            let frequency1 = sin(phase + Float(i) * 0.3) * 0.3
            let frequency2 = sin(phase * 1.5 + Float(i) * 0.1) * 0.2
            let frequency3 = sin(phase * 0.7 + Float(i) * 0.05) * 0.1
            
            waveformData[i] = frequency1 + frequency2 + frequency3
        }
    }
}

// MARK: - Audio Analyzer
class AudioAnalyzer: NSObject, ObservableObject {
    private var player: AVPlayer?
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var fftSetup: vDSP_DFT_Setup?
    private var realtimeBuffer: [Float] = []
    private let bufferSize = 1024
    
    override init() {
        super.init()
        setupAudioEngine()
    }
    
    func setPlayer(_ player: AVPlayer?) {
        self.player = player
        if player != nil {
            startAnalysis()
        } else {
            stopAnalysis()
        }
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }
    
    private func startAnalysis() {
        // For now, we'll use synthetic data since real-time audio analysis
        // from AVPlayer is complex and requires additional setup
        realtimeBuffer = Array(repeating: 0.0, count: 64)
    }
    
    private func stopAnalysis() {
        realtimeBuffer = Array(repeating: 0.0, count: 64)
    }
    
    func getRealtimeData() -> [Float]? {
        // Return nil to trigger synthetic waveform generation
        // In a full implementation, this would return real FFT data
        return nil
    }
}

#Preview {
    VStack {
        Text("Playing: Sample Track")
            .font(.headline)
        
        OscilloscopeVisualizer(player: nil, isPlaying: true)
            .background(Color.black.opacity(0.1))
            .cornerRadius(8)
    }
    .padding()
}