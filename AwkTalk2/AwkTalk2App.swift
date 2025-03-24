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
            ContentView()
                .environmentObject(audioManager)
        }
    }
}
