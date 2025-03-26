import Foundation
import AVFoundation
import Speech
import Combine

class AudioManager: ObservableObject {
    @Published var isRecording = false
    @Published var isAuthorized = false
    @Published var transcribedText = ""
    @Published var error: AudioError?
    @Published var conversationLog: [ConversationEntry] = []
    
    // Set isProfileCreated to true by default to skip the profile creation screen
    @Published private(set) var isProfileCreated = true
    
    // Add conversation analyzer
    @Published var conversationAnalysis: String = ""
    @Published var conversationSuggestions: [String] = []
    @Published var isAnalyzing: Bool = false
    @Published var modelLoadingStatus: String = ""
    
    // Lazy initialize the conversation analyzer
    private lazy var conversationAnalyzer = ConversationAnalyzer()
    
    // Lazy initialize the Azure speech manager
    private lazy var azureSpeechManager = AzureSpeechManager()
    
    private var cancellables = Set<AnyCancellable>()
    
    // Track when we last analyzed the conversation
    private var lastAnalyzedCount = 0
    private let minEntriesForAnalysis = 3
    private let analyzeEveryNEntries = 2
    
    @Published var conversationContext: String = ""
    
    init() {
        MemoryMetrics.shared.reportMemoryUsage(for: "AudioManager Init")
        checkPermissions()
    }
    
    // Call this method when you're ready to set up speech recognition
    func setupSpeechRecognition() {
        MemoryMetrics.shared.reportMemoryUsage(for: "Before Speech Setup")
        
        // Add error observation
        azureSpeechManager.$error
            .receive(on: RunLoop.main)
            .sink { [weak self] error in
                if let error = error {
                    print("Azure Speech Manager error: \(error.message)")
                    self?.error = .recordingFailed(error.message)
                }
            }
            .store(in: &cancellables)
        
        // Set up observers for Azure Speech Manager
        azureSpeechManager.$isRecording.assign(to: &$isRecording)
        azureSpeechManager.$transcribedText.assign(to: &$transcribedText)
        
        // Set up observers for conversation analyzer
        conversationAnalyzer.$isAnalyzing.assign(to: &$isAnalyzing)
        conversationAnalyzer.$modelLoadingStatus.assign(to: &$modelLoadingStatus)
        
        // Observe conversation log changes
        azureSpeechManager.$conversationLog
            .receive(on: RunLoop.main)
            .sink { [weak self] conversation in
                guard let self = self else { return }
                self.conversationLog = conversation
                
                // Check if we should analyze the conversation
                self.checkAndAnalyzeConversation(conversation)
            }
            .store(in: &cancellables)
        
        // Observe analysis results
        conversationAnalyzer.$analysis
            .receive(on: RunLoop.main)
            .sink { [weak self] analysis in
                guard let self = self, !analysis.isEmpty else { return }
                self.conversationAnalysis = analysis
            }
            .store(in: &cancellables)
        
        conversationAnalyzer.$suggestions
            .receive(on: RunLoop.main)
            .sink { [weak self] suggestions in
                guard let self = self else { return }
                self.conversationSuggestions = suggestions
            }
            .store(in: &cancellables)
        
        // Start loading the model in the background
        Task {
            await conversationAnalyzer.ensureModelLoaded()
        }
        
        // After setup
        MemoryMetrics.shared.reportMemoryUsage(for: "After Speech Setup")
    }
    
    private func checkAndAnalyzeConversation(_ conversation: [ConversationEntry]) {
        MemoryMetrics.shared.reportMemoryUsage(for: "Before Conversation Analysis")
        
        // Only analyze if:
        // 1. We have at least the minimum number of entries
        // 2. We have new entries since the last analysis
        // 3. The number of new entries is at least analyzeEveryNEntries
        // 4. We're not currently analyzing
        
        if conversation.count >= minEntriesForAnalysis && 
           conversation.count > lastAnalyzedCount &&
           (conversation.count - lastAnalyzedCount) >= analyzeEveryNEntries &&
           !isAnalyzing {
            
            // Update the last analyzed count
            lastAnalyzedCount = conversation.count
            
            // Create a limited context by taking only the last 10 entries
            // This prevents memory issues with very long conversations
            let limitedConversation = conversation.suffix(10)
            
            // Analyze the conversation with context
            Task {
                await conversationAnalyzer.analyzeConversation(Array(limitedConversation), context: conversationContext)
                MemoryMetrics.shared.reportMemoryUsage(for: "After Conversation Analysis")
            }
        }
    }
    
    func checkPermissions() {
        // Check microphone permissions directly
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            DispatchQueue.main.async {
                self.isAuthorized = true
            }
        case .denied:
            DispatchQueue.main.async {
                self.isAuthorized = false
                self.error = .permissionDenied
            }
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if !granted {
                        self?.error = .permissionDenied
                    }
                }
            }
        @unknown default:
            DispatchQueue.main.async {
                self.isAuthorized = false
                self.error = .permissionDenied
            }
        }
    }
    
    func startRecording() {
        azureSpeechManager.startRecording()
    }
    
    func stopRecording() {
        azureSpeechManager.stopRecording()
    }
    
    // Keep this method for compatibility, but it doesn't do anything now
    func resetProfile() {
        // No-op
    }
    
    func clearConversation() {
        MemoryMetrics.shared.reportMemoryUsage(for: "Before Clear Conversation")
        
        // Stop any ongoing analysis
        isAnalyzing = false
        
        // Reset the last analyzed count
        lastAnalyzedCount = 0
        
        // Clear conversation data
        conversationLog = []
        conversationAnalysis = ""
        conversationSuggestions = []
        
        // Clear transcribed text
        transcribedText = ""
        
        // Clear Azure Speech Manager conversation log
        azureSpeechManager.clearConversation()
        
        MemoryMetrics.shared.reportMemoryUsage(for: "After Clear Conversation")
    }
    
    func setConversationContext(_ context: String) {
        self.conversationContext = context
        
        // Reset conversation when setting new context
        clearConversation()
    }
    
    func preloadModel() {
        Task {
            await conversationAnalyzer.ensureModelLoaded()
        }
    }
}
