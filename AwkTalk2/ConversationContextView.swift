import SwiftUI

struct ConversationContextView: View {
    @EnvironmentObject var audioManager: AudioManager
    @State private var conversationContext: String = ""
    @State private var isShowingConversation = false
    @State private var isSetupComplete = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header image or illustration
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue, .blue.opacity(0.7))
                    .padding(.top, 40)
                
                Text("What awkward conversation can we help you with today?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Context input area
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add context")
                        .font(.headline)
                    
                    Text("The more details you provide, the better we can help. (e.g., who you're talking to, what's the situation, what's your goal)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                    
                    TextEditor(text: $conversationContext)
                        .focused($isTextFieldFocused)
                        .frame(minHeight: 150)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Start button
                Button(action: {
                    audioManager.setConversationContext(conversationContext)
                    
                    // Set up speech recognition when user starts a conversation
                    if !isSetupComplete {
                        audioManager.setupSpeechRecognition()
                        isSetupComplete = true
                    }
                    
                    isShowingConversation = true
                }) {
                    Text("Start Conversation")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(height: 55)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(14)
                        .padding(.horizontal)
                }
                .padding(.bottom, 30)
                .disabled(conversationContext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(conversationContext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1)
            }
            .padding()
            .navigationDestination(isPresented: $isShowingConversation) {
                ContentView()
                    .environmentObject(audioManager)
            }
            .onAppear {
                // Auto focus the text field when the view appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextFieldFocused = true
                }
            }
        }
    }
} 