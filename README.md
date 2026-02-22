# IPTV Player (Flutter)

Flutter IPTV player with **Xtreme Codes** login support.

## Features

- **Login**: Server URL, Username, Password; validates via `player_api.php` and `user_info` status
- **Live categories**: Fetched via `get_live_categories`, shown in a ListView
- **Channels**: Per-category live streams via `get_live_streams`; channel name, logo, tap to play
- **Video player**: HLS playback with `better_player`, fullscreen and landscape
- **State**: Provider for auth, categories, streams
- **Persistence**: Credentials saved with `shared_preferences`

## Project structure (clean architecture)

```
lib/
  models/       # user_info, live_category, live_stream
  services/     # api_service, auth_storage_service
  providers/    # auth, categories, streams
  screens/      # login, categories, streams, player
  widgets/      # channel_tile, etc.
  main.dart
```

## Setup

1. Install Flutter and ensure it’s on your PATH.
2. From the project root run:
   ```bash
   flutter pub get
   ```
3. If this folder was not created with `flutter create`, generate platform folders (optional):
   ```bash
   flutter create . --project-name iptv_app
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## API (Xtreme Codes)

- Login: `{SERVER}/player_api.php?username={USER}&password={PASS}` → check `user_info.status`
- Categories: `...&action=get_live_categories`
- Streams: `...&action=get_live_streams&category_id={ID}`
- Stream URL: `{SERVER}/live/{USER}/{PASS}/{STREAM_ID}.m3u8`

## Dependencies

- `provider` – state management
- `shared_preferences` – save login
- `http` – API calls
- `better_player` – video playback (HLS, fullscreen, landscape)
