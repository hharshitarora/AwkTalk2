import SwiftUI

struct SuggestionBubble: View {
    let suggestion: String
    var onDismiss: () -> Void
    var onNextSuggestion: () -> Void
    
    @State private var offset: CGFloat = 100
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Image(systemName: "quote.bubble.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                
                Text("Try saying:")
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .padding(4)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            
            Text(suggestion)
                .font(.callout)
                .lineLimit(3)
                .padding(.vertical, 4)
            
            HStack {
                Spacer()
                
                Button(action: onNextSuggestion) {
                    HStack(spacing: 4) {
                        Text("Next Suggestion")
                            .font(.footnote)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(BorderlessButtonStyle())
                .opacity(0.8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                offset = 0
                opacity = 1
            }
        }
    }
} 