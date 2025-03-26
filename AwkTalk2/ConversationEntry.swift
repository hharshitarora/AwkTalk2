import Foundation

struct ConversationEntry: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let text: String
    let speaker: Speaker
    
    // Add Equatable conformance
    static func == (lhs: ConversationEntry, rhs: ConversationEntry) -> Bool {
        return lhs.id == rhs.id &&
               lhs.timestamp == rhs.timestamp &&
               lhs.text == rhs.text &&
               lhs.speaker == rhs.speaker
    }
    
    enum Speaker: String, Equatable {
        case user = "You"
        case other = "Other"
        case unknown = "Unknown"
    }
} 