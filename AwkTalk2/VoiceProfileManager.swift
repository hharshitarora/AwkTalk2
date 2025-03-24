import Foundation
import AVFoundation
import SoundAnalysis

enum Speaker: String, Identifiable {
    case user = "You"
    case other = "Other Person"
    case unknown = "Unknown"
    
    var id: String { self.rawValue }
}

class VoiceProfileManager: ObservableObject {
    @Published var isProfileCreated = false
    @Published var currentSpeaker: Speaker = .unknown
    
    private var userVoiceFeatures: [Float]?
    private var analyzer: SNAudioStreamAnalyzer?
    private var analysisQueue = DispatchQueue(label: "com.awkTalk.audioAnalysis")
    
    // Store a short sample of user's voice for comparison
    func createUserProfile(from audioBuffer: AVAudioPCMBuffer) {
        analysisQueue.async {
            // Extract voice features from the buffer
            let features = self.extractVoiceFeatures(from: audioBuffer)
            
            DispatchQueue.main.async {
                self.userVoiceFeatures = features
                self.isProfileCreated = true
            }
        }
    }
    
    // Compare incoming audio with user profile
    func identifySpeaker(in audioBuffer: AVAudioPCMBuffer) {
        guard let userFeatures = userVoiceFeatures else {
            DispatchQueue.main.async {
                self.currentSpeaker = .unknown
            }
            return
        }
        
        analysisQueue.async {
            let currentFeatures = self.extractVoiceFeatures(from: audioBuffer)
            let similarity = self.calculateSimilarity(between: userFeatures, and: currentFeatures)
            
            // If similarity is above threshold, it's the user
            let speaker = similarity > 0.7 ? Speaker.user : Speaker.other
            
            DispatchQueue.main.async {
                self.currentSpeaker = speaker
            }
        }
    }
    
    // Extract basic voice features (pitch, energy, etc.)
    private func extractVoiceFeatures(from buffer: AVAudioPCMBuffer) -> [Float] {
        // This is a simplified implementation
        // In a real app, you'd use more sophisticated feature extraction
        
        let frameLength = Int(buffer.frameLength)
        var features = [Float]()
        
        // Get audio data as array of samples
        let samples = Array(UnsafeBufferPointer(start: buffer.floatChannelData?[0], count: frameLength))
        
        // Calculate energy (volume)
        let energy = samples.map { $0 * $0 }.reduce(0, +) / Float(frameLength)
        features.append(energy)
        
        // Calculate zero-crossing rate (rough estimate of pitch)
        var zeroCrossings = 0
        for i in 1..<frameLength {
            if (samples[i] >= 0 && samples[i-1] < 0) || (samples[i] < 0 && samples[i-1] >= 0) {
                zeroCrossings += 1
            }
        }
        let zcr = Float(zeroCrossings) / Float(frameLength)
        features.append(zcr)
        
        // Add more features as needed
        
        return features
    }
    
    // Calculate similarity between feature vectors
    private func calculateSimilarity(between features1: [Float], and features2: [Float]) -> Float {
        // Simple Euclidean distance-based similarity
        var sumSquaredDiff: Float = 0
        
        for i in 0..<min(features1.count, features2.count) {
            let diff = features1[i] - features2[i]
            sumSquaredDiff += diff * diff
        }
        
        let distance = sqrt(sumSquaredDiff)
        // Convert distance to similarity (1 = identical, 0 = completely different)
        return max(0, 1 - distance)
    }
    
    // Reset the user profile
    func resetProfile() {
        userVoiceFeatures = nil
        isProfileCreated = false
    }
} 