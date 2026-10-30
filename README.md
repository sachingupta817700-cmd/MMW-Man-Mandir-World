# MMW – Man Mandir World (Flutter starter)

A premium black-and-gold Android music app starter for the YouTube channel:
https://youtube.com/@manmandirworld

## Included
- Dark black/gold MMW home screen
- Loads public uploads from the channel using YouTube Data API v3
- In-app YouTube playback using the YouTube IFrame player
- Local favorites
- Refreshable song list

## Important setup
This is a starter project, not a signed/published APK. To load all channel uploads:
1. Install Flutter SDK and Android Studio.
2. Create a Google Cloud project and enable **YouTube Data API v3**.
3. Create an API key. Restrict it to YouTube Data API v3 and, for production, secure it through a backend rather than shipping an unrestricted key in the app.
4. Run from this folder:
   `flutter pub get`
   `flutter run --dart-define=YOUTUBE_API_KEY=YOUR_API_KEY`
5. Build:
   `flutter build apk --release --dart-define=YOUTUBE_API_KEY=YOUR_API_KEY`

## Notes
- The app plays videos through YouTube's embedded player. It does not download audio, bypass ads, or provide background/offline playback for YouTube videos.
- The current sample fetches the first 50 uploads. Add `nextPageToken` pagination to fetch more than 50 videos.
- The YouTube API quota applies. Keep the key private; for a public release, proxy API calls through a backend.
- Replace the temporary music-note mark with your supplied MMW logo when you provide it.
- Add your own privacy policy and app-store disclosures before publishing.
