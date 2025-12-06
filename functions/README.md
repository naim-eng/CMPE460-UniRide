# Firebase Cloud Functions Setup for Secure Google Places API

This setup moves your Google API key from the Flutter app to a secure backend, preventing API key theft.

## Step 1: Install Firebase CLI

```bash
npm install -g firebase-tools
```

## Step 2: Login to Firebase

```bash
firebase login
```

## Step 3: Install Dependencies

```bash
cd functions
npm install
cd ..
```

## Step 4: Set Your Google API Key Securely

Set your Google API key as an environment variable (NOT in code):

```bash
firebase functions:config:set google.api_key="AIzaSyAIeZNs7EWG2VR_gxHVU8hb9Gs06v0GNJg"
```

## Step 5: Update firebase.json

Add this to your `firebase.json` (in the root, next to the existing "flutter" section):

```json
{
  "functions": {
    "source": "functions",
    "predeploy": [],
    "ignore": [
      "node_modules",
      ".git"
    ]
  },
  "flutter": {
    ... (keep existing flutter config)
  }
}
```

## Step 6: Add cloud_functions to pubspec.yaml

Add this dependency to your `pubspec.yaml`:

```yaml
dependencies:
  cloud_functions: ^4.6.0
```

Then run:
```bash
flutter pub get
```

## Step 7: Deploy Cloud Functions

```bash
firebase deploy --only functions
```

This will deploy three functions:
- `placesAutocomplete` - Search for places
- `placeDetails` - Get coordinates for a place
- `reverseGeocode` - Convert coordinates to address

## Step 8: Update Your Flutter Code

I've already created `lib/services/secure_places_service.dart` which uses these Cloud Functions.

Now you need to update your screens to use `SecurePlacesService` instead of `LocationSearchService`.

### In passenger_find_ride_screen.dart and driver_offer_ride_screen.dart:

1. Remove the `LocationSearchService` class entirely
2. Import the secure service:
   ```dart
   import 'package:uniride_app/services/secure_places_service.dart';
   ```
3. Replace `LocationSearchService.search()` with `SecurePlacesService.search()`
4. Update the search flow to get coordinates after selecting a suggestion

## Step 9: Secure Your Old API Key

After deploying and verifying everything works:

1. Go to Google Cloud Console
2. **Create a NEW API key** for the Cloud Functions (with no restrictions)
3. **Delete or restrict your old API key** to prevent abuse
4. Update the Cloud Functions config:
   ```bash
   firebase functions:config:set google.api_key="NEW_KEY_HERE"
   firebase deploy --only functions
   ```

## Step 10: Remove API Key from Code

Delete the API key from:
- `lib/screens/passenger_find_ride_screen.dart`
- `lib/screens/driver_offer_ride_screen.dart`
- `ios/Runner/AppDelegate.swift` (keep the Maps SDK key only)
- `android/app/src/main/AndroidManifest.xml` (keep the Maps SDK key only)

## Cost Considerations

- Firebase Cloud Functions free tier: 2M invocations/month
- After that: $0.40 per million invocations
- For a ride-sharing app, this should stay within free tier for development

## Security Benefits

✅ API key never exposed in app code
✅ Can't be extracted by decompiling your app
✅ Requires Firebase Authentication (users must be logged in)
✅ Can add rate limiting and usage monitoring
✅ Can revoke access by updating Cloud Functions without app update

## Testing Locally (Optional)

To test functions locally before deploying:

```bash
firebase emulators:start --only functions
```

Then update your Flutter app to use the emulator:
```dart
FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
```
