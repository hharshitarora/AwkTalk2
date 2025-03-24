import Foundation
import AVFoundation
import Speech
import Combine

enum AudioError: Error, Identifiable {
    case permissionRequired
    case recordingFailed(String)
    case recognitionFailed(String)
    
    var id: String {
        switch self {
        case .permissionRequired: return "permissionRequired"
        case .recordingFailed: return "recordingFailed"
        case .recognitionFailed: return "recognitionFailed"
        }
    }
    
    var message: String {
        switch self {
        case .permissionRequired:
            return "Microphone and speech recognition permissions are required"
        case .recordingFailed(let message):
            return "Recording failed: \(message)"
        case .recognitionFailed(let message):
            return "Speech recognition failed: \(message)"
        }
    }
}

class AudioManager: ObservableObject {
    @Published var isRecording = false
    @Published var isAuthorized = false
    @Published var transcribedText = ""
    @Published var error: AudioError?
    @Published var conversationLog: [ConversationEntry] = []
    
    // Set isProfileCreated to true by default to skip the profile creation screen
    @Published private(set) var isProfileCreated = true
    
    private var azureSpeechManager = AzureSpeechManager()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        checkPermissions()
        
        // Set up observers for Azure Speech Manager
        azureSpeechManager.$isRecording.assign(to: &$isRecording)
        azureSpeechManager.$transcribedText.assign(to: &$transcribedText)
        azureSpeechManager.$conversationLog.assign(to: &$conversationLog)
        
        // Handle Azure errors
        azureSpeechManager.$error.sink { [weak self] azureError in
            guard let self = self, let azureError = azureError else { return }
            
            switch azureError {
            case .configurationFailed:
                self.error = .recordingFailed("Azure configuration failed")
            case .recognitionFailed(let message):
                self.error = .recognitionFailed(message)
            case .noSubscriptionKey:
                self.error = .recordingFailed("Azure subscription key is missing")
            }
        }.store(in: &cancellables)
    }
    
    func checkPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if status == .authorized {
                    // Use the appropriate API based on iOS version
                    if #available(iOS 17.0, *) {
                        AVAudioApplication.requestRecordPermission { [weak self] granted in
                            guard let self = self else { return }
                            DispatchQueue.main.async {
                                self.isAuthorized = granted
                                if !granted {
                                    self.error = .permissionRequired
                                }
                            }
                        }
                    } else {
                        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                            guard let self = self else { return }
                            DispatchQueue.main.async {
                                self.isAuthorized = granted
                                if !granted {
                                    self.error = .permissionRequired
                                }
                            }
                        }
                    }
                } else {
                    self.isAuthorized = false
                    self.error = .permissionRequired
                }
            }
        }
    }
    
    func requestPermission() {
        checkPermissions()
    }
    
    func startRecording() {
        guard isAuthorized && !isRecording else { return }
        azureSpeechManager.startRecording()
    }
    
    func stopRecording() {
        guard isRecording else { return }
        azureSpeechManager.stopRecording()
    }
    
    // Keep this method for compatibility, but it doesn't do anything now
    func resetProfile() {
        // No-op
    }
    
    func clearConversation() {
        conversationLog = []
        transcribedText = ""
        
        // Also clear the Azure speech manager's conversation log
        azureSpeechManager.clearConversation()
    }
}

struct ConversationEntry: Identifiable {
    let id = UUID()
    let text: String
    let speaker: Speaker
    let timestamp: Date
} 