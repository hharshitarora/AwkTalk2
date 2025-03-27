# AwkTalk2

An AI-powered conversation assistant that helps users navigate awkward conversations by providing real-time analysis and suggestions.

## Features

- Real-time speech recognition and transcription
- Speaker diarization
- Conversation analysis using AI
- Contextual suggestions for better communication

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Azure Speech Service account
- Swift 5.5+

## Setup

1. Clone the repository 
bash
git clone https://github.com/yourusername/AwkTalk2.git

2. Install dependencies (if using package manager)

3. Configure API Keys:
   - Copy `Config.template.swift` to `Config.swift`
   - Add your Azure Speech Service credentials
   - Or set environment variables:
     - AZURE_SPEECH_KEY
     - AZURE_SPEECH_REGION

4. Build and run the project

## Environment Variables

The following environment variables are required:

- `AZURE_SPEECH_KEY`: Your Azure Speech Service API key
- `AZURE_SPEECH_REGION`: Your Azure Speech Service region

## Privacy

This application processes audio locally and sends it to Azure Speech Services for transcription. No audio data is stored permanently. Conversation analysis is performed using on-device ML models.

## License
Not Free License