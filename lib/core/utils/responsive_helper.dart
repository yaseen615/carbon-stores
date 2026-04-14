import 'package:flutter/widgets.dart';

/// Three-tier responsive breakpoint system.
///
/// Phone:   width < 600
/// Tablet:  600 ≤ width < 1000
/// Desktop: width ≥ 1000
enum DeviceType { phone, tablet, desktop }

class Responsive {
  static DeviceType of(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 600) return DeviceType.phone;
    if (w < 1000) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  static bool isPhone(BuildContext context) => of(context) == DeviceType.phone;
  static bool isTablet(BuildContext context) =>
      of(context) == DeviceType.tablet;
  static bool isDesktop(BuildContext context) =>
      of(context) == DeviceType.desktop;

  /// True for both tablet and desktop (i.e. the "landscape" / wide UIs).
  static bool isTabletOrDesktop(BuildContext context) => !isPhone(context);
}
