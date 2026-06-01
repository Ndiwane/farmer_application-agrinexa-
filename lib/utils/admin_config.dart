/// Central admin configuration for AgriNexa
/// Add your Firebase UID here to get admin privileges
class AdminConfig {
  // ── Replace with your actual Firebase UID ─────────────────────────────────
  // Find it in: Firebase Console → Authentication → Users → Copy UID
  static const List<String> adminUids = [
    'yBRFEdxi0LTfqDP2LPQYfuSGIRp1', 
  ];

  // ── AgriNexa support contact ───────────────────────────────────────────────
  static const String supportWhatsApp = '237674238006'; // Replace with your number
  static const String supportEmail = 'agrinexa.app@gmail.com';
  static const String appName = 'AgriNexa';
  static const String verifiedLabel = 'AgriNexa Verified ✅';

  // ── Check if current user is admin ────────────────────────────────────────
  static bool isAdmin(String? uid) {
    if (uid == null) return false;
    return adminUids.contains(uid);
  }
}