import Foundation
import AVFoundation
import MicrosoftCognitiveServicesSpeech

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

class AzureSpeechManager: ObservableObject {
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var conversationLog: [ConversationEntry] = []
    @Published var error: AzureError?
    
    // Azure Speech Service credentials
    private let subscriptionKey = "3vGIugLP8MhpI2LCewNbHk6xqulW1YH60vh4MGDMC1qHgMqZKNo5JQQJ99BCAC1i4TkXJ3w3AAAYACOGf3CI"
    private let region = "centralus"
    
    // Speech recognition
    private var speechConfig: SPXSpeechConfiguration?
    private var audioConfig: SPXAudioConfiguration?
    private var transcriber: SPXConversationTranscriber?
    
    // Speaker mapping
    private var speakerMap: [String: Speaker] = [:]
    
    // Debug flag to print detailed information
    private let debug = true
    
    init() {
        setupSpeechConfig()
    }
    
    private func setupSpeechConfig() {
        do {
            // Create speech configuration with subscription key and region
            speechConfig = try SPXSpeechConfiguration(subscription: subscriptionKey, region: region)
            
            // Set recognition language
            speechConfig?.speechRecognitionLanguage = "en-US"
            
            // Enable diarization through direct property setting
            speechConfig?.setPropertyTo("true", byName: "SPEECH-EnableDiarization")
            speechConfig?.setPropertyTo("2", byName: "SPEECH-DiarizationMinimumSpeakerCount")
            speechConfig?.setPropertyTo("3", byName: "SPEECH-DiarizationMaximumSpeakerCount")
            
            if debug {
                print("Speech configuration created successfully with diarization enabled")
            }
        } catch {
            self.error = .configurationFailed
            if debug {
                print("Failed to create speech configuration: \(error.localizedDescription)")
            }
        }
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        do {
            // Create audio configuration for microphone
            audioConfig = SPXAudioConfiguration()
            
            guard let speechConfig = speechConfig, let audioConfig = audioConfig else {
                self.error = .configurationFailed
                return
            }
            
            // Create conversation transcriber
            let transcriber = try SPXConversationTranscriber(speechConfiguration: speechConfig, audioConfiguration: audioConfig)
            
            // Set up event handlers
            transcriber.addTranscribingEventHandler { [weak self] _, event in
                guard let self = self else { return }
                
                if let result = event.result, let text = result.text, !text.isEmpty {
                    if self.debug {
                        print("Transcribing: \(text)")
                        if let speakerId = result.speakerId {
                            print("Speaker ID: \(speakerId)")
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.transcribedText = text
                    }
                }
            }
            
            transcriber.addTranscribedEventHandler { [weak self] _, event in
                guard let self = self else { return }
                
                if let result = event.result, let text = result.text, !text.isEmpty {
                    if self.debug {
                        print("Transcribed: \(text)")
                        if let speakerId = result.speakerId {
                            print("Speaker ID: \(speakerId)")
                        }
                    }
                    
                    // Determine speaker based on speakerId
                    var speaker: Speaker = .unknown
                    
                    if let speakerId = result.speakerId, !speakerId.isEmpty {
                        // Check if we've seen this speaker before
                        if let mappedSpeaker = self.speakerMap[speakerId] {
                            speaker = mappedSpeaker
                        } else {
                            // First time seeing this speaker, assign a role
                            // First speaker we encounter is the user, second is other
                            let newSpeaker: Speaker = self.speakerMap.isEmpty ? .user : .other
                            self.speakerMap[speakerId] = newSpeaker
                            speaker = newSpeaker
                            
                            if self.debug {
                                print("Mapped new speaker ID \(speakerId) to \(newSpeaker.rawValue)")
                            }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        let entry = ConversationEntry(
                            text: text,
                            speaker: speaker,
                            timestamp: Date()
                        )
                        self.conversationLog.append(entry)
                        self.transcribedText = ""
                    }
                }
            }
            
            transcriber.addCanceledEventHandler { [weak self] _, event in
                guard let self = self else { return }
                
                if self.debug {
                    print("Transcription canceled: \(event.errorDetails ?? "Unknown error")")
                }
                
                DispatchQueue.main.async {
                    let errorDetails = event.errorDetails ?? "Unknown error"
                    self.error = .recognitionFailed(errorDetails)
                    self.stopRecording()
                }
            }
            
            // Start transcribing
            if debug {
                print("Starting transcription")
            }
            
            try transcriber.startTranscribingAsync { [weak self] success, error in
                guard let self = self else { return }
                
                if success {
                    if self.debug {
                        print("Transcription started successfully")
                    }
                } else {
                    if self.debug {
                        print("Failed to start transcription: \(error?.localizedDescription ?? "Unknown error")")
                    }
                    
                    DispatchQueue.main.async {
                        self.error = .recognitionFailed(error?.localizedDescription ?? "Unknown error")
                        self.isRecording = false
                    }
                }
            }
            
            self.transcriber = transcriber
            isRecording = true
            
        } catch {
            self.error = .recognitionFailed(error.localizedDescription)
            if debug {
                print("Error starting recording: \(error.localizedDescription)")
            }
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        do {
            if let transcriber = transcriber {
                if debug {
                    print("Stopping transcription")
                }
                
                try transcriber.stopTranscribingAsync { [weak self] success, error in
                    guard let self = self else { return }
                    
                    if success {
                        if self.debug {
                            print("Transcription stopped successfully")
                        }
                    } else {
                        if self.debug {
                            print("Error stopping transcription: \(error?.localizedDescription ?? "Unknown error")")
                        }
                    }
                }
                self.transcriber = nil
            }
            
            isRecording = false
        } catch {
            self.error = .recognitionFailed(error.localizedDescription)
            if debug {
                print("Error stopping recording: \(error.localizedDescription)")
            }
        }
    }
    
    func clearConversation() {
        conversationLog = []
        transcribedText = ""
        speakerMap = [:]
    }
}

