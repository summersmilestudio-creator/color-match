import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

/// App Tracking Transparency.
///
/// Apple requires the ATT prompt to appear *before* any tracking data is
/// collected (i.e. before the ads SDK initialises). We request it once, after
/// the first frame is on screen so the app is foreground/active when the system
/// prompt is shown — otherwise the prompt silently never appears (the exact
/// rejection reason: "unable to locate the App Tracking Transparency request").
class TrackingService {
  TrackingService._();

  static Future<void> requestIfNeeded() async {
    if (!Platform.isIOS) return;
    try {
      final status =
          await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        // Give the UI a moment to settle so the prompt reliably shows.
        await Future<void>.delayed(const Duration(milliseconds: 350));
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (_) {
      // Never let ATT block app startup.
    }
  }
}
