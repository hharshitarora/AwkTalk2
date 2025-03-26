//
//  AwkTalk2App.swift
//  AwkTalk2
//
//  Created by Harshit Arora on 3/5/25.
//

import SwiftUI

@main
struct AwkTalk2App: App {
    @StateObject private var audioManager = AudioManager()
    
    var body: some Scene {
        WindowGroup {
            ConversationContextView()
                .environmentObject(audioManager)
                .onAppear {
                    // Optionally pre-load some components after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        // Start loading the model in the background after UI is shown
                        // Use a public method instead of accessing private property
                        audioManager.preloadModel()
                    }
                }
        }
    }
}
