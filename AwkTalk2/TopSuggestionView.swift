import SwiftUI

struct TopSuggestionView: View {
    @EnvironmentObject var audioManager: AudioManager
    @State private var currentSuggestionIndex = 0
    @State private var isExpanded = false
    
    private var currentSuggestion: String? {
        guard !audioManager.conversationSuggestions.isEmpty,
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
            if let suggestion = currentSuggestion {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "quote.bubble.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 16))
                        
                        Text("Try saying:")
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Only show next button if there are more suggestions
                        if hasMoreSuggestions {
                            Button(action: {
                                withAnimation {
                                    currentSuggestionIndex += 1
                                }
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundColor(.secondary)
                                    .padding(4)
                            }
                        }
                        
                        Button(action: {
                            withAnimation {
                                isExpanded.toggle()
                            }
                        }) {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                                .padding(4)
                        }
                    }
                    
                    if isExpanded {
                        Text(suggestion)
                            .font(.callout)
                            .lineLimit(nil) // Allow full text when expanded
                            .padding(.vertical, 4)
                    } else {
                        Text(suggestion)
                            .font(.callout)
                            .lineLimit(2) // Limit to 2 lines when collapsed
                            .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .padding(.horizontal)
                .padding(.vertical, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.spring(), value: currentSuggestion)
            } else {
                // Empty spacer when no suggestions
                EmptyView()
                    .frame(height: 0)
            }
        }
        .onChange(of: audioManager.conversationSuggestions) { newValue in
            if !newValue.isEmpty {
                // Reset to first suggestion when new ones arrive
                withAnimation {
                    currentSuggestionIndex = 0
                    // Auto-expand for new suggestions
                    isExpanded = true
                }
            }
        }
    }
} 