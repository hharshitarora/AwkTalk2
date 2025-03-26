import SwiftUI

struct ConversationAnalysisView: View {
    @EnvironmentObject var audioManager: AudioManager
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Conversation Analysis")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !audioManager.modelLoadingStatus.isEmpty {
                    Text(audioManager.modelLoadingStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 30, height: 30)
                        .background(Color(uiColor: .systemGray5))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(uiColor: .systemGray6))
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    if audioManager.isAnalyzing {
                        HStack {
                            ProgressView()
                                .padding(.trailing, 8)
                            Text("Analyzing conversation...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                    } else if !audioManager.conversationAnalysis.isEmpty {
                        Text("Analysis")
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)
                        
                        Text(audioManager.conversationAnalysis)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if !audioManager.conversationSuggestions.isEmpty {
                            Text("Suggestions")
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                                .padding(.top, 8)
                            
                            ForEach(audioManager.conversationSuggestions, id: \.self) { suggestion in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 14))
                                    
                                    Text(suggestion)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    } else {
                        Text("Start a conversation to see analysis")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                }
                .padding(16)
                .background(Color(uiColor: .systemBackground))
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
} 