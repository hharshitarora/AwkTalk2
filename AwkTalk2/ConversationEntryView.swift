import SwiftUI

struct ConversationEntryView: View {
    let entry: ConversationEntry
    
    var body: some View {
        MessageBubble(entry: entry)
    }
} 