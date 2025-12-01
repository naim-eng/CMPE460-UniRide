// Ignore any warnings/errors here unless it actually does not work

import UIKit
import Flutter
import GoogleMaps   // add this import

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Google Maps iOS API key
    GMSServices.provideAPIKey("AIzaSyBMqafToF3BmXAtlHfeZcHmS5pOoqE-3Us")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

