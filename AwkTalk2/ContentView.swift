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
    @State private var showingError = false
    @State private var scrollToLatest = UUID() // ID for scrolling to latest message
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Fixed suggestion area at the top
                TopSuggestionView()
                    .environmentObject(audioManager)
                
                // Main content
                ZStack {
                    VStack {
                        // Conversation Transcript View with auto-scrolling
                        ScrollViewReader { scrollProxy in
                            ScrollView {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(audioManager.conversationLog) { entry in
                                        ConversationEntryView(entry: entry)
                                            .id(entry.id) // Use entry's ID for identification
                                    }
                                    
                                    // Invisible view at the bottom for scrolling
                                    Color.clear
                                        .frame(height: 1)
                                        .id(scrollToLatest)
                                }
                                .padding()
                            }
                            .onChange(of: audioManager.conversationLog) { _ in
                                // When conversation changes, scroll to bottom with animation
                                withAnimation {
                                    scrollProxy.scrollTo(scrollToLatest, anchor: .bottom)
                                }
                            }
                            .onAppear {
                                // Scroll to bottom when view appears
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    withAnimation {
                                        scrollProxy.scrollTo(scrollToLatest, anchor: .bottom)
                                    }
                                }
                            }
                        }
                        
                        // Recording Controls
                        RecordingControlsView()
                            .environmentObject(audioManager)
                    }
                }
            }
            .navigationTitle("AwkTalk")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        audioManager.clearConversation()
                    }) {
                        Image(systemName: "trash")
                            .frame(width: 44, height: 44)
                    }
                }
            }
        }
        .sheet(isPresented: $showingError) {
            if let error = audioManager.error {
                ErrorView(error: error) {
                    showingError = false
                    audioManager.error = nil
                }
            }
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
