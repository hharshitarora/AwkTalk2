import SwiftUI

struct FloatingSuggestionsView: View {
    @EnvironmentObject var audioManager: AudioManager
    @State private var showingSuggestion = false
    @State private var currentSuggestionIndex = 0
    @State private var hasNewSuggestions = false
    
    private var currentSuggestion: String? {
        guard !audioManager.conversationSuggestions.isEmpty,
              audioManager.conversationSuggestions.count > 0,
              currentSuggestionIndex >= 0,
              currentSuggestionIndex < audioManager.conversationSuggestions.count else {
            return nil
        }
        return audioManager.conversationSuggestions[currentSuggestionIndex]
    }
    
    private var hasMoreSuggestions: Bool {
        !audioManager.conversationSuggestions.isEmpty && 
        currentSuggestionIndex < audioManager.conversationSuggestions.count - 1
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            if showingSuggestion, let suggestion = currentSuggestion {
                SuggestionBubble(
                    suggestion: suggestion,
                    onDismiss: {
                        withAnimation {
                            showingSuggestion = false
                        }
                    },
                    onNextSuggestion: {
                        withAnimation {
                            if hasMoreSuggestions {
                                currentSuggestionIndex += 1
                            } else {
                                // Cycle back to first suggestion
                                currentSuggestionIndex = 0
                            }
                        }
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .zIndex(1)
            }
            
            // Collapsed indicator button only shows when there are suggestions but none are displayed
            if !audioManager.conversationSuggestions.isEmpty && !showingSuggestion {
                Button(action: {
                    withAnimation {
                        showingSuggestion = true
                        hasNewSuggestions = false
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: hasNewSuggestions ? "speech.bubble.fill" : "speech.bubble")
                            .foregroundColor(hasNewSuggestions ? .blue : .primary)
                        
                        Text(hasNewSuggestions ? "New suggestion" : "View suggestion")
                            .font(.footnote.bold())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.bottom, 8)
                .transition(.opacity)
            }
        }
        .padding(.bottom, 16)
        .onChange(of: audioManager.conversationSuggestions) { newValue in
            if !newValue.isEmpty {
                // Reset to first suggestion when new ones arrive
                currentSuggestionIndex = 0
                hasNewSuggestions = true
                
                // Automatically show the suggestion if we're not in the middle of showing one
                if !showingSuggestion {
                    DispatchQueue.main.async {
                        withAnimation {
                            showingSuggestion = true
                        }
                    }
                }
            }
        }
    }
}

// Add a subtle success indicator
struct SuccessIndicator: View {
    @State private var isShowing = false
    
    var body: some View {
        VStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 40))
            
            Text("Copied!")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Material.ultraThin)
        .cornerRadius(12)
        .opacity(isShowing ? 1 : 0)
        .scaleEffect(isShowing ? 1 : 0.5)
        .onAppear {
            withAnimation(.spring()) {
                isShowing = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut) {
                    isShowing = false
                }
            }
        }
    }
}
