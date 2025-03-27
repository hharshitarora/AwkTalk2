import Foundation
import AVFoundation
import MicrosoftCognitiveServicesSpeech
import Combine

class AzureSpeechManager: ObservableObject {
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var conversationLog: [ConversationEntry] = []
    @Published var error: AzureError?
    
    // NEVER commit actual keys to public repositories
    private let subscriptionKey: String = {
        // Load from environment variable or configuration file
        guard let key = ProcessInfo.processInfo.environment["AZURE_SPEECH_KEY"] ?? 
              Bundle.main.infoDictionary?["AzureSpeechKey"] as? String else {
            print("⚠️ Warning: Azure Speech Key not found in environment or configuration")
            return ""
        }
        return key
    }()
    
    private let region: String = {
        // Load from environment variable or configuration file
        guard let region = ProcessInfo.processInfo.environment["AZURE_SPEECH_REGION"] ?? 
              Bundle.main.infoDictionary?["AzureSpeechRegion"] as? String else {
            print("⚠️ Warning: Azure Speech Region not found in environment or configuration")
            return "centralus"
        }
        return region
    }()
    
    // Speech recognition
    private var speechConfig: SPXSpeechConfiguration?
    private var audioConfig: SPXAudioConfiguration?
    private var transcriber: SPXConversationTranscriber?
    
    // Speaker mapping
    private var speakerMap: [String: ConversationEntry.Speaker] = [:]
    
    // Debug flag to print detailed information
    private let debug = true  // Set to true for debugging
    
    // Lazy initialization
    private var isConfigured = false
    
    init() {
        // Don't set up speech config in init
    }
    
    func setupSpeechConfig() {
        guard !isConfigured else { return }
        
        do {
            // Use the subscription key directly
            speechConfig = try SPXSpeechConfiguration(subscription: subscriptionKey, region: region)
            
            // Set language
            speechConfig?.speechRecognitionLanguage = "en-US"
            
            isConfigured = true
            
        } catch {
            self.error = AzureError.configurationFailed
            if debug {
                print("Error setting up speech config: \(error.localizedDescription)")
            }
        }
    }
    
    func startRecording() {
        guard !isRecording else { 
            if debug { print("Already recording, ignoring start request") }
            return 
        }
        
        // Ensure we're configured
        if !isConfigured {
            if debug { print("Setting up speech config") }
            setupSpeechConfig()
        }
        
        guard isConfigured else {
            if debug { print("Speech config setup failed") }
            self.error = AzureError.configurationFailed
            return
        }
        
        do {
            if debug { print("Creating audio configuration") }
            // Create audio configuration for microphone
            audioConfig = SPXAudioConfiguration()
            
            guard let speechConfig = speechConfig, let audioConfig = audioConfig else {
                self.error = AzureError.configurationFailed
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
                    var speaker: ConversationEntry.Speaker = .unknown
                    
                    if let speakerId = result.speakerId, !speakerId.isEmpty {
                        // Check if we've seen this speaker before
                        if let mappedSpeaker = self.speakerMap[speakerId] {
                            speaker = mappedSpeaker
                        } else {
                            // First time seeing this speaker, assign a role
                            // First speaker we encounter is the user, second is other
                            let newSpeaker: ConversationEntry.Speaker = self.speakerMap.isEmpty ? .user : .other
                            self.speakerMap[speakerId] = newSpeaker
                            speaker = newSpeaker
                            
                            if self.debug {
                                print("Mapped new speaker ID \(speakerId) to \(newSpeaker.rawValue)")
                            }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        let entry = ConversationEntry(
                            timestamp: Date(),
                            text: text,
                            speaker: speaker
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
                    self.error = AzureError.recognitionFailed(errorDetails)
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
                        self.error = AzureError.recognitionFailed(error?.localizedDescription ?? "Unknown error")
                        self.isRecording = false
                    }
                }
            }
            
            self.transcriber = transcriber
            isRecording = true
            
        } catch {
            if debug { print("Error in startRecording: \(error)") }
            self.error = AzureError.recognitionFailed(error.localizedDescription)
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
            self.error = AzureError.recognitionFailed(error.localizedDescription)
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

