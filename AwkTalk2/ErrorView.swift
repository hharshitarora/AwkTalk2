import SwiftUI

struct ErrorView: View {
    let error: AudioError
    @State private var isVisible = false
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                
                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(uiColor: .systemGray6))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 60)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -20)
        .animation(.spring(response: 0.3), value: isVisible)
        .onAppear {
            isVisible = true
            
            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                isVisible = false
            }
        }
    }
}

#Preview {
    ErrorView(error: .recordingFailed("Microphone access denied"))
} 