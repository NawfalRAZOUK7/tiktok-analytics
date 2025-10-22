import 'package:flutter/material.dart';

/// Responsive breakpoints for different screen sizes
class Responsive {
  /// Mobile breakpoint (phones)
  static const double mobile = 600;
  
  /// Tablet breakpoint (tablets, small laptops)
  static const double tablet = 900;
  
  /// Desktop breakpoint (large screens)
  static const double desktop = 1200;

  /// Check if the current screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }

  /// Check if the current screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < desktop;
  }

  /// Check if the current screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }

  /// Get the number of columns for a grid based on screen size
  static int getGridCrossAxisCount(BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getPadding(BuildContext context, {
    EdgeInsets? mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
  }) {
    if (isMobile(context)) {
      return mobile ?? const EdgeInsets.all(16);
    }
    if (isTablet(context)) {
      return tablet ?? const EdgeInsets.all(24);
    }
    return desktop ?? const EdgeInsets.all(32);
  }

  /// Get responsive value based on screen size
  static T getValue<T>(BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return desktop ?? tablet ?? mobile;
  }

  /// Build a responsive widget based on screen size
  static Widget builder({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return desktop ?? tablet ?? mobile;
  }
}

/// Extension on BuildContext for easy access to responsive utilities
extension ResponsiveExtension on BuildContext {
  bool get isMobile => Responsive.isMobile(this);
  bool get isTablet => Responsive.isTablet(this);
  bool get isDesktop => Responsive.isDesktop(this);
  
  int gridColumns({int mobile = 1, int tablet = 2, int desktop = 3}) {
    return Responsive.getGridCrossAxisCount(
      this,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
  
  EdgeInsets responsivePadding({
    EdgeInsets? mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
  }) {
    return Responsive.getPadding(
      this,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
  
  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    return Responsive.getValue(
      this,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}
