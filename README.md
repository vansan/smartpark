# SmartPark 🅿️

**SmartPark** is a UAE-themed smart parking management POC built with Flutter Web + Firebase.

## Features

- 🔐 Google Sign-In authentication
- 🗺️ Interactive map showing parking locations (Dubai)
- 🟢 Real-time slot availability (Free / Booked / Occupied)
- 📅 Date, time & duration-based slot booking
- 💳 Mock prepaid payment flow (AED 5/hr + 5% VAT)
- 📱 QR code generation for parking entry validation
- 🔃 3-step parking flow: Book → Show QR → Park Vehicle
- ⏱️ Auto-release of expired bookings
- 👮 Guard mode: QR scanner to validate and occupy slots

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter Web |
| Backend | Firebase Firestore |
| Auth | Firebase Auth (Google Sign-In) |
| Maps | Google Maps Flutter |
| State | Riverpod |
| Navigation | GoRouter |

## Live Demo

Deployed on Vercel — see [deployment URL]

## Color Theme

Inspired by the 🇦🇪 UAE Flag:
- 🟢 Green — Free slots / Primary actions
- 🔴 Red — Booked slots / Cancel actions  
- ⬜ White — Guard mode
- ⬛ Black — Background (obsidian)

## Local Development

```bash
cd smartpark_app
flutter pub get
flutter build web --release --no-wasm-dry-run
# Serve build/web on any static server
python -m http.server 8090 # from build/web directory
```
