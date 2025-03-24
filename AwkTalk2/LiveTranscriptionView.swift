import SwiftUI

struct LiveTranscriptionView: View {
    let text: String
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Text(text)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .id("transcriptionEnd")
            }
            .onChange(of: text) { _ in
                withAnimation {
                    proxy.scrollTo("transcriptionEnd", anchor: .bottom)
                }
            }
            .onAppear {
                withAnimation {
                    proxy.scrollTo("transcriptionEnd", anchor: .bottom)
                }
            }
        }
        .frame(maxHeight: 80)
        .background(Color(uiColor: .systemGray6).opacity(0.5))
        .cornerRadius(8)
    }
} 