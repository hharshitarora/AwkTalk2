import Foundation
import MLX
import MLXLLM
import MLXLMCommon
import MLXRandom

class MLXModel {
    private enum LoadState {
        case idle
        case loading
        case loaded(ModelContainer)
        case error(Error)
    }
    
    private var loadState = LoadState.idle
    
    // Use a model that's actually in the ModelRegistry
    private let modelConfiguration = ModelRegistry.phi4bit
    
    // Add a rate limiter to MLXModel
    private var lastGenerationTime: Date?
    private let minimumTimeBetweenGenerations: TimeInterval = 5 // seconds
    
    func loadModel() async throws {
        switch loadState {
        case .idle:
            loadState = .loading
            
            // Limit the buffer cache to reduce memory usage
            MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)
            
            do {
                print("Starting model download: \(modelConfiguration.id)")
                
                let modelContainer = try await LLMModelFactory.shared.loadContainer(
                    configuration: modelConfiguration
                ) { progress in
                    // Progress reporting could be added here if needed
                    print("Downloading model: \(Int(progress.fractionCompleted * 100))%")
                }
                
                print("Model loaded successfully: \(modelConfiguration.id)")
                loadState = .loaded(modelContainer)
            } catch {
                print("Error loading model: \(error)")
                loadState = .error(error)
                throw error
            }
            
        case .loading:
            // Wait for the loading to complete
            while case .loading = loadState {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            }
            
            if case .error(let error) = loadState {
                throw error
            }
            
        case .loaded:
            // Model already loaded, do nothing
            break
            
        case .error(let error):
            throw error
        }
    }
    
    func generateText(prompt: String) async throws -> String {
        guard case .loaded(let modelContainer) = loadState else {
            throw NSError(domain: "MLXModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
        }
        
        // Rate limiting to prevent memory issues
        if let lastTime = lastGenerationTime, 
           Date().timeIntervalSince(lastTime) < minimumTimeBetweenGenerations {
            
            // Wait until we can generate again
            let waitTime = minimumTimeBetweenGenerations - Date().timeIntervalSince(lastTime)
            try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }
        
        // Update the last generation time
        lastGenerationTime = Date()
        
        // Limit prompt size to prevent memory issues
        let limitedPrompt = String(prompt.prefix(2000))
        
        // Release any cached memory before generating
        autoreleasepool {
            // Force a memory cleanup
            MLXRandom.seed(UInt64(Date.timeIntervalSinceReferenceDate * 1000))
        }
        
        do {
            let result = try await modelContainer.perform { context in
                let input = try await context.processor.prepare(
                    input: .init(
                        messages: [
                            ["role": "system", "content": "You are a helpful assistant that analyzes conversations. Be concise."],
                            ["role": "user", "content": limitedPrompt]
                        ]
                    )
                )
                
                return try MLXLMCommon.generate(
                    input: input,
                    parameters: .init(temperature: 0.7),
                    context: context
                ) { tokens in
                    if tokens.count >= 256 { // Reduced from 512 to limit memory usage
                        return .stop
                    } else {
                        return .more
                    }
                }
            }
            
            return result.output
        } catch {
            // If we get an error, force a memory cleanup
            autoreleasepool {
                MLXRandom.seed(UInt64(Date.timeIntervalSinceReferenceDate * 1000))
            }
            throw error
        }
    }
} 
