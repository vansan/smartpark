# SmartPark 🅿️

**SmartPark** is a UAE-themed smart parking management POC built with Flutter Web + Firebase.

## Features

- 🔐 Google Sign-In authentication
- 🗺️ Interactive map showing parking locations (Dubai)
- 🟢 Real-time slot availability (Free / Booked / Occupied)
- 📅 Date, time & duration-based slot booking
- 🗺️ **GPS Directions to Parking Spot**: Route navigation directly from the user's location to their specific booked parking space.
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

Deployed on Vercel: [https://smartpark-lac.vercel.app/](https://smartpark-lac.vercel.app/)

## Stakeholder Presentation 📊

The stakeholder presentation slides are saved directly in this repository as:
- [SmartPark_Stakeholder_Presentation.pptx](file:///C:/work/SmartPark/SmartPark_Stakeholder_Presentation.pptx)

**How to download the presentation:**
1. Go to the repository on GitHub: [https://github.com/vansan/smartpark](https://github.com/vansan/smartpark)
2. Click on the file `SmartPark_Stakeholder_Presentation.pptx`.
3. Click the **"Download raw file"** button (or the download icon on the right side of the screen) to save the PowerPoint file directly to your local computer.

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
