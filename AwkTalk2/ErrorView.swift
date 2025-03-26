import SwiftUI

struct ErrorView: View {
    let error: Error
    let dismissAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text(errorTitle)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text(errorMessage)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(action: dismissAction) {
                Text("Dismiss")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .padding(30)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding(20)
    }
    
    private var errorTitle: String {
        if let audioError = error as? AudioError {
            switch audioError {
            case .permissionDenied:
                return "Microphone Access Required"
            case .recordingFailed:
                return "Recording Failed"
            case .transcriptionFailed:
                return "Transcription Failed"
            }
        } else if let azureError = error as? AzureError {
            switch azureError {
            case .configurationFailed:
                return "Configuration Failed"
            case .recognitionFailed:
                return "Recognition Failed"
            case .noSubscriptionKey:
                return "Subscription Key Missing"
            }
        } else {
            return "Error Occurred"
        }
    }
    
    private var errorMessage: String {
        if let audioError = error as? AudioError {
            return audioError.message
        } else if let azureError = error as? AzureError {
            return azureError.message
        } else {
            return error.localizedDescription
        }
    }
}

#Preview {
    ErrorView(
        error: AudioError.recordingFailed("Microphone access denied"),
        dismissAction: {}
    )
} 
