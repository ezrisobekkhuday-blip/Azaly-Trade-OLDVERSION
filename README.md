# Azaly Trade

Project structure:

- `mobile` - Flutter app for Android and iPhone.
- `backend` - FastAPI server with SQLite.

## Implemented mobile MVP

- Dark iPhone-style UI.
- Bottom tabs: `Create`, `Products`, `Empty`.
- Top settings button with editable display name.
- Product creation with gallery and camera photo picking.
- Fields: amount, material, size.
- Auto status `new` on create.
- Products tab with edit, delete, and fullscreen photo viewer.
- Local persistence with `SharedPreferences`.

## Run Flutter mobile app

```bash
cd mobile
flutter pub get
flutter run
```

Run directly on Android emulator:

```bash
flutter run -d emulator-5554
```

## Run as web / PWA

For local browser testing:

```bash
cd mobile
flutter run -d chrome
```

Build production web files:

```bash
cd mobile
flutter build web
```

Then serve `mobile/build/web` with any HTTP server. Example:

```bash
cd mobile/build/web
python -m http.server 8088
```

Open:

```text
http://127.0.0.1:8088
```

Notes:

- The app already uses the FastAPI server URL configured in the Flutter code or `--dart-define=AZALY_API_URL=...`.
- PWA install behavior works correctly on `localhost` and HTTPS. If you open it from plain `http` on a random IP, the web app can still work, but install/camera/geolocation behavior may be limited by the browser.

## Run backend

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Server URL:

```text
http://127.0.0.1:8000
```

## Next step

Connect the Flutter app to the FastAPI backend so that products and profile name are stored in SQLite instead of only local device storage.
