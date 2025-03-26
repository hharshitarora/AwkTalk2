import SwiftUI

struct RecordingControlsView: View {
    @EnvironmentObject var audioManager: AudioManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Live transcription area
            if !audioManager.transcribedText.isEmpty {
                LiveTranscriptionView(text: audioManager.transcribedText)
            }
            
            // Recording button
            Button(action: {
                if audioManager.isRecording {
                    audioManager.stopRecording()
                } else {
                    audioManager.startRecording()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(audioManager.isRecording ? Color.red : Color.blue)
                        .frame(width: 68, height: 68)
                        .shadow(radius: 4)
                    
                    Image(systemName: audioManager.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.vertical, 8)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
} 