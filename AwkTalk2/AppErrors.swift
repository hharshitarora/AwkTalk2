import Foundation

// Audio-related errors
enum AudioError: Error, Identifiable {
    case permissionDenied
    case recordingFailed(String)
    case transcriptionFailed
    
    var id: String {
        switch self {
        case .permissionDenied: return "permissionDenied"
        case .recordingFailed: return "recordingFailed"
        case .transcriptionFailed: return "transcriptionFailed"
        }
    }
    
    var message: String {
        switch self {
        case .permissionDenied:
            return "Microphone access is required for recording. Please enable it in Settings."
        case .recordingFailed(let message):
            return "Failed to start recording: \(message)"
        case .transcriptionFailed:
            return "Failed to transcribe audio. Please try again."
        }
    }
}

// Azure Speech Service errors
enum AzureError: Error, Identifiable {
    case configurationFailed
    case recognitionFailed(String)
    case noSubscriptionKey
    
    var id: String {
        switch self {
        case .configurationFailed: return "configurationFailed"
        case .recognitionFailed: return "recognitionFailed"
        case .noSubscriptionKey: return "noSubscriptionKey"
        }
    }
    
    var message: String {
        switch self {
        case .configurationFailed:
            return "Failed to configure Azure Speech Service"
        case .recognitionFailed(let message):
            return "Recognition failed: \(message)"
        case .noSubscriptionKey:
            return "Azure Speech Service subscription key is missing"
        }
    }
} 