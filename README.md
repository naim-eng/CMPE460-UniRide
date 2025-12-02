# UniRide

UniRide is a cross-platform Flutter application designed to help university students offer rides, find rides, and coordinate trips efficiently. The app supports both drivers and riders, including ride posting, searching, accepting requests, and in-app communication.

# Features
## Driver Features

- Post a ride with details such as destination, time, seats, and price
- View incoming rider requests
- Accept or reject riders
- View all posted rides
- Rate riders after the ride

## Rider Features

- Search for available rides
- Request to join a ride
- Cancel a ride request
- Chat with the assigned driver
- Rate drivers after the ride

## System Features

- Firebase authentication
- Real-time updates using Firestore
- Push notifications for requests, acceptances, and confirmations
- Google Maps integration
- Organized UI built with Flutter

## Tech Stack

### Frontend

- Flutter (3.x)
- Dart
-Google Maps Flutter

### Backend

- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Messaging

### Tooling

- Android Studio
- Xcode
- GitHub

# Getting Started
1. Clone the Repository
git clone https://github.com/naim-eng/CMPE460-UniRide
cd uniride_app

2. Install Dependencies
flutter pub get

3. Firebase Configuration

The project uses Firebase for authentication and database functionality.
Make sure the following files exist:

Android:

android/app/google-services.json

iOS:

ios/Runner/GoogleService-Info.plist


If they are missing, download them from the Firebase Console under
Project Settings → Your Apps.

Run the Application
flutter run

Folder Structure (Simplified)
lib -> (screens , main.dart)

# Possible Future Additions

- Improved ride filtering
- Admin dashboard (if required)
- Enhanced chat features
- Ride history and receipts

# License

This project is developed as part of CMPE460 coursework and is for academic use only.
