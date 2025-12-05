# Widgetbook Setup for UniRide

## What is Widgetbook?

Widgetbook lets you preview and test all your app screens in isolation without needing to navigate through the app or log in. Think of it as a gallery of all your screens.

## How to Use

### Running Widgetbook

```bash
flutter run -t widgetbook/widgetbook.dart
```

This will launch a special version of your app with all screens organized in a sidebar.

### Navigation

Once Widgetbook is running, you'll see:

1. **Left Sidebar**: A tree view of all your screens organized by category:
   - Authentication (Login, Register)
   - Main Screens (Home, Profile)
   - Ride Management (Find Ride, Offer Ride, My Rides, etc.)
   - Vehicle Management (Create Vehicle, Vehicles List)

2. **Center**: The selected screen preview

3. **Right Panel**: Controls for:
   - Device selection (iPhone 13, Samsung Galaxy S20, etc.)
   - Text scale adjustment (1.0x, 1.5x, 2.0x)

### Features

- **Device Frames**: See how your screens look on different devices
- **Text Scaling**: Test accessibility with different text sizes
- **No Login Required**: Preview screens that normally require authentication
- **Quick Navigation**: Jump to any screen instantly

## File Structure

```
widgetbook/
  └── widgetbook.dart    # Main Widgetbook configuration
```

## Adding New Screens

To add a new screen to Widgetbook, edit `widgetbook/widgetbook.dart`:

```dart
WidgetbookComponent(
  name: 'Your Screen Name',
  useCases: [
    WidgetbookUseCase(
      name: 'Default',
      builder: (context) => const YourScreen(),
    ),
  ],
),
```

## Tips

- Widgetbook doesn't connect to Firebase, so screens that rely on real data will show empty states
- Perfect for UI development and design reviews
- Great for taking screenshots for documentation
- Helps identify which screen is which when you have many similar-looking screens
