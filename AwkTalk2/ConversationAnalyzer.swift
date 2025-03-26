import Foundation
import SwiftUI

class ConversationAnalyzer: ObservableObject {
    @Published var analysis: String = ""
    @Published var suggestions: [String] = []
    @Published var isAnalyzing: Bool = false
    @Published var error: Error?
    @Published var modelLoadingStatus: String = "Not loaded"
    @Published var isModelLoaded: Bool = false
    
    private let mlxModel = MLXModel()
    private var modelLoadTask: Task<Void, Never>?
    
    init() {
        // Don't load the model immediately on init
        // We'll load it when needed or in the background after a delay
    }
    
    func ensureModelLoaded() async {
        // Only load if not already loaded or loading
        if !isModelLoaded && modelLoadTask == nil {
            modelLoadTask = Task {
                await loadModel()
            }
        }
        
        // Wait for existing load task if there is one
        if let task = modelLoadTask {
            await task.value
        }
    }
    
    private func loadModel() async {
        MemoryMetrics.shared.reportMemoryUsage(for: "Before Model Load")
        
        do {
            DispatchQueue.main.async {
                self.isAnalyzing = true
                self.modelLoadingStatus = "Loading model..."
            }
            
            // Load the model
            try await mlxModel.loadModel()
            
            DispatchQueue.main.async {
                self.isAnalyzing = false
                self.isModelLoaded = true
                self.modelLoadingStatus = "Model loaded successfully"
            }
            
            MemoryMetrics.shared.reportMemoryUsage(for: "After Model Load")
        } catch {
            DispatchQueue.main.async {
                self.error = error
                self.isAnalyzing = false
                self.modelLoadingStatus = "Error loading model: \(error.localizedDescription)"
                print("Error loading model: \(error)")
            }
        }
        
        modelLoadTask = nil
    }
    
    func analyzeConversation(_ conversation: [ConversationEntry], context: String = "") async {
        print("Analysis triggered with \(conversation.count) messages")
        
        guard !conversation.isEmpty else { return }
        
        await ensureModelLoaded()
        
        DispatchQueue.main.async {
            self.isAnalyzing = true
        }
        
        do {
            // Increase timeout to 30 seconds for larger conversations
            let result = try await withTimeout(seconds: 30) {
                try await self.generateAnalysisForConversation(conversation, context: context)
            }
            
            print("Analysis completed: \(result.0)")
            print("Suggestions: \(result.1)")
            
            DispatchQueue.main.async {
                self.analysis = result.0
                self.suggestions = result.1
                self.isAnalyzing = false
            }
        } catch let error as TimeoutError {
            print("Analysis timed out after 30 seconds")
            DispatchQueue.main.async {
                self.error = error
                self.isAnalyzing = false
                // Set a default message when timing out
                self.analysis = "Analysis is taking longer than expected. Please try again with a shorter conversation."
                self.suggestions = []
            }
        } catch {
            print("Analysis error: \(error)")
            DispatchQueue.main.async {
                self.error = error
                self.isAnalyzing = false
                // Set error message
                self.analysis = "An error occurred during analysis. Please try again."
                self.suggestions = []
            }
        }
    }
    
    private func generateAnalysisForConversation(_ conversation: [ConversationEntry], context: String = "") async throws -> (String, [String]) {
        let formattedConversation = formatConversation(conversation)
        
        // Build the prompt with the context information
        var prompt = """
        You're analyzing a conversation between two people. 
        """
        
        // Add context if available
        if !context.isEmpty {
            prompt += """
            
            IMPORTANT CONTEXT:
            \(context)
            
            In this conversation, "Speaker 1" refers to the person who provided the context above.
            Your advice should help the "Speaker 1" speaker achieve their goals in this specific situation.
            """
        }
        
        prompt += """
        
        Your job is very specific:
        
        1. Quickly assess if "Speaker 1" is missing any CRITICAL point or question they should address.
        
        2. If nothing critical is missing, respond with exactly: "No suggestions needed."
        
        3. If something important is missing, provide ONE suggestion in exactly 1-2 sentences.
        
        4. Your suggestion must be phrased as something "Speaker 1" could say verbatim in their next turn.
        
        5. Be extremely concise - the entire suggestion must fit in 2 lines on a phone screen.
        
        Conversation:
        \(formattedConversation)
        
        Your suggestion (remember: 1-2 sentences only, or "No suggestions needed"):
        """
        
        do {
            // Generate the analysis with our carefully crafted prompt
            let response = try await mlxModel.generateText(prompt: prompt)
            
            // Clean up the response
            let cleanedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check if no suggestions
            if cleanedResponse.contains("No suggestions needed") {
                return ("No critical points missing.", [])
            } else {
                // The whole response is the suggestion
                return ("Important point identified.", [cleanedResponse])
            }
        } catch {
            throw error
        }
    }
    
    private func formatConversation(_ conversation: [ConversationEntry]) -> String {
        return conversation.map { entry in
            let speaker = entry.speaker.rawValue
            return "\(speaker): \(entry.text)"
        }.joined(separator: "\n")
    }
    
    private func parseAnalysisResponse(_ response: String) -> (String, [String]) {
        // Simple parsing logic - can be improved
        var analysis = ""
        var suggestions: [String] = []
        
        // Look for suggestions section
        if let suggestionsStart = response.range(of: "suggestions", options: .caseInsensitive) {
            let beforeSuggestions = response[..<suggestionsStart.lowerBound]
            analysis = String(beforeSuggestions).trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Extract suggestions
            let afterSuggestions = response[suggestionsStart.upperBound...]
            let lines = afterSuggestions.split(separator: "\n")
            
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.contains(":") || trimmed.contains(".") || trimmed.contains(")") {
                    if !trimmed.isEmpty && !trimmed.lowercased().contains("suggestion") {
                        suggestions.append(trimmed)
                    }
                }
            }
        } else {
            // If no clear "suggestions" section, look for numbered points or bullet points
            let lines = response.split(separator: "\n")
            var inSuggestionSection = false
            
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Check if this line looks like a suggestion
                let isSuggestion = trimmed.range(of: #"^\d+[\.\)]"#, options: .regularExpression) != nil ||
                                  trimmed.hasPrefix("-") ||
                                  trimmed.hasPrefix("•")
                
                if isSuggestion || (inSuggestionSection && !trimmed.isEmpty) {
                    inSuggestionSection = true
                    if !trimmed.isEmpty {
                        suggestions.append(trimmed)
                    }
                } else if !trimmed.isEmpty {
                    if analysis.isEmpty {
                        analysis = trimmed
                    } else {
                        analysis += "\n\(trimmed)"
                    }
                }
            }
            
            // If we still couldn't find suggestions, use the whole response as analysis
            if suggestions.isEmpty {
                analysis = response
            }
        }
        
        return (analysis, suggestions)
    }
    
    // Add specific timeout error type
    struct TimeoutError: Error {
        let message: String
        
        init(_ message: String = "Operation timed out") {
            self.message = message
        }
    }
    
    // Helper function with custom timeout error
    func withTimeout<T>(seconds: Double, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError("Operation timed out after \(Int(seconds)) seconds")
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}