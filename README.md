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
