//
//  ContentView.swift
//  AwkTalk2
//
//  Created by Harshit Arora on 3/5/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var audioManager: AudioManager
    @State private var showingSettings = false
    @State private var transcriptionScrollId = UUID()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()
                
                conversationView
                
                if let error = audioManager.error {
                    ErrorView(error: error)
                }
            }
            .navigationTitle("AwkTalk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                            .font(.system(size: 17))
                            .frame(width: 44, height: 44) // Apple's minimum touch target size
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        // Clear conversation
                        withAnimation {
                            audioManager.clearConversation()
                        }
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 17))
                            .frame(width: 44, height: 44) // Apple's minimum touch target size
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
    
    private var conversationView: some View {
        VStack(spacing: 0) {
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(spacing: 20) { // Increased spacing for better readability
                        ForEach(audioManager.conversationLog) { entry in
                            MessageBubble(entry: entry)
                                .id(entry.id)
                        }
                        
                        // Invisible spacer view that helps with scrolling
                        Color.clear
                            .frame(height: 1)
                            .id("bottomScrollAnchor")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                }
                .onChange(of: audioManager.conversationLog.count) { _ in
                    withAnimation(.easeOut(duration: 0.2)) {
                        scrollView.scrollTo("bottomScrollAnchor", anchor: .bottom)
                    }
                }
            }
            
            Spacer()
            
            // Compact transcription and recording controls
            VStack(spacing: 12) { // Increased spacing
                if !audioManager.transcribedText.isEmpty {
                    LiveTranscriptionView(text: audioManager.transcribedText)
                }
                
                HStack {
                    Spacer() // Center the button
                    
                    Button(action: {
                        if audioManager.isRecording {
                            audioManager.stopRecording()
                        } else {
                            audioManager.startRecording()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(audioManager.isRecording ? Color.red : Color.accentColor)
                                .frame(width: 64, height: 64) // Increased to 64pt for better tappability
                                .shadow(color: audioManager.isRecording ? Color.red.opacity(0.2) : Color.accentColor.opacity(0.2), 
                                        radius: 6, x: 0, y: 3)
                            
                            Image(systemName: audioManager.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.vertical, 16) // Increased padding for better touch area
                    
                    Spacer() // Center the button
                }
            }
            .padding(.horizontal)
            .background(
                Color(uiColor: .systemGray6)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: -3)
            )
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SettingsView: View {
    @EnvironmentObject var audioManager: AudioManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("Version 1.0")
                        Spacer()
                        Text("Build 1")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AudioManager())
}
