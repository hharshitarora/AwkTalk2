import SwiftUI

struct  MessageBubble: View {
    let entry: ConversationEntry
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if entry.speaker == .user {
                Spacer()
            }
            
            VStack(alignment: entry.speaker == .user ? .trailing : .leading, spacing: 4) {
                Text(entry.speaker.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                
                Text(entry.text)
                    .font(.body) // Ensure text is at least 11pt (Apple's guideline)
                    .foregroundColor(entry.speaker == .user ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(entry.speaker == .user ? Color.accentColor : Color(uiColor: .systemGray5))
                    )
                    .contextMenu {
                        Button(action: {
                            UIPasteboard.general.string = entry.text
                        }) {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }
            }
            
            if entry.speaker == .other {
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack {
        MessageBubble(entry: ConversationEntry(text: "Hello, how are you?", speaker: .user, timestamp: Date()))
        MessageBubble(entry: ConversationEntry(text: "I'm doing well, thanks for asking!", speaker: .other, timestamp: Date()))
    }
    .padding()
} 
