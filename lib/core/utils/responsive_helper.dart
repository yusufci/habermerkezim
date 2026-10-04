import 'package:flutter/material.dart';

/// Responsive breakpoint'ler
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double largeDesktop = 1800;
}

/// Cihaz türü
enum DeviceType {
  mobile,
  tablet,
  desktop,
  largeDesktop;

  bool get isMobile => this == DeviceType.mobile;
  bool get isTablet => this == DeviceType.tablet;
  bool get isDesktop =>
      this == DeviceType.desktop || this == DeviceType.largeDesktop;
  bool get isLargeScreen =>
      this == DeviceType.tablet ||
      this == DeviceType.desktop ||
      this == DeviceType.largeDesktop;
}

/// Ekran yönü
enum ScreenOrientation {
  portrait,
  landscape;

  bool get isPortrait => this == ScreenOrientation.portrait;
  bool get isLandscape => this == ScreenOrientation.landscape;
}

/// Responsive helper sınıfı
class ResponsiveHelper {
  final BuildContext context;
  late final Size _screenSize;
  late final double _width;
  late final double _height;
  late final DeviceType _deviceType;
  late final ScreenOrientation _orientation;

  ResponsiveHelper(this.context) {
    _screenSize = MediaQuery.of(context).size;
    _width = _screenSize.width;
    _height = _screenSize.height;
    _deviceType = _calculateDeviceType();
    _orientation = _calculateOrientation();
  }

  /// Ekran genişliği
  double get width => _width;

  /// Ekran yüksekliği
  double get height => _height;

  /// Ekran boyutu
  Size get screenSize => _screenSize;

  /// Cihaz türü
  DeviceType get deviceType => _deviceType;

  /// Ekran yönü
  ScreenOrientation get orientation => _orientation;

  /// Mobil mi?
  bool get isMobile => _deviceType.isMobile;

  /// Tablet mi?
  bool get isTablet => _deviceType.isTablet;

  /// Desktop mu?
  bool get isDesktop => _deviceType.isDesktop;

  /// Büyük ekran mı? (tablet veya desktop)
  bool get isLargeScreen => _deviceType.isLargeScreen;

  /// Portrait mı?
  bool get isPortrait => _orientation.isPortrait;

  /// Landscape mı?
  bool get isLandscape => _orientation.isLandscape;

  /// Cihaz türünü hesapla
  DeviceType _calculateDeviceType() {
    if (_width < ResponsiveBreakpoints.mobile) {
      return DeviceType.mobile;
    } else if (_width < ResponsiveBreakpoints.tablet) {
      return DeviceType.tablet;
    } else if (_width < ResponsiveBreakpoints.desktop) {
      return DeviceType.desktop;
    } else {
      return DeviceType.largeDesktop;
    }
  }

  /// Ekran yönünü hesapla
  ScreenOrientation _calculateOrientation() {
    return _width > _height
        ? ScreenOrientation.landscape
        : ScreenOrientation.portrait;
  }

  /// Grid sütun sayısı
  int get gridColumns {
    switch (_deviceType) {
      case DeviceType.mobile:
        return isLandscape ? 2 : 1;
      case DeviceType.tablet:
        return isLandscape ? 3 : 2;
      case DeviceType.desktop:
        return 3;
      case DeviceType.largeDesktop:
        return 4;
    }
  }

  /// Liste öğesi genişliği
  double get listItemWidth {
    if (isMobile) {
      return _width;
    } else if (isTablet) {
      return isLandscape ? _width / 2 : _width;
    } else {
      return _width / gridColumns;
    }
  }

  /// Padding değeri
  double get padding {
    switch (_deviceType) {
      case DeviceType.mobile:
        return 16;
      case DeviceType.tablet:
        return 24;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return 32;
    }
  }

  /// Horizontal padding
  double get horizontalPadding {
    if (isDesktop) {
      // Desktop'ta içeriği ortala
      const maxContentWidth = 1200.0;
      if (_width > maxContentWidth) {
        return (_width - maxContentWidth) / 2;
      }
    }
    return padding;
  }

  /// Card genişliği
  double get cardWidth {
    switch (_deviceType) {
      case DeviceType.mobile:
        return _width - (padding * 2);
      case DeviceType.tablet:
        return isLandscape
            ? (_width - (padding * 3)) / 2
            : _width - (padding * 2);
      case DeviceType.desktop:
        return (_width - (padding * 4)) / 3;
      case DeviceType.largeDesktop:
        return (_width - (padding * 5)) / 4;
    }
  }

  /// Font scale faktörü
  double get fontScale {
    switch (_deviceType) {
      case DeviceType.mobile:
        return 1.0;
      case DeviceType.tablet:
        return 1.1;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return 1.15;
    }
  }

  /// Icon boyutu
  double get iconSize {
    switch (_deviceType) {
      case DeviceType.mobile:
        return 24;
      case DeviceType.tablet:
        return 28;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return 32;
    }
  }

  /// AppBar yüksekliği
  double get appBarHeight {
    switch (_deviceType) {
      case DeviceType.mobile:
        return kToolbarHeight;
      case DeviceType.tablet:
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return kToolbarHeight + 8;
    }
  }

  /// Drawer genişliği
  double get drawerWidth {
    switch (_deviceType) {
      case DeviceType.mobile:
        return _width * 0.85;
      case DeviceType.tablet:
        return 320;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return 360;
    }
  }

  /// Dialog genişliği
  double get dialogWidth {
    switch (_deviceType) {
      case DeviceType.mobile:
        return _width * 0.9;
      case DeviceType.tablet:
        return 500;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return 600;
    }
  }

  /// Maksimum içerik genişliği (desktop için)
  double get maxContentWidth {
    switch (_deviceType) {
      case DeviceType.mobile:
        return _width;
      case DeviceType.tablet:
        return 720;
      case DeviceType.desktop:
        return 900;
      case DeviceType.largeDesktop:
        return 1200;
    }
  }

  /// Responsive değer döndür
  T value<T>({required T mobile, T? tablet, T? desktop}) {
    switch (_deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// Responsive widget döndür
  Widget builder({required Widget mobile, Widget? tablet, Widget? desktop}) {
    switch (_deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return desktop ?? tablet ?? mobile;
    }
  }
}

/// Responsive widget builder
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ResponsiveHelper responsive)
  builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return builder(context, ResponsiveHelper(context));
  }
}

/// Responsive layout widget
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, responsive) {
        return responsive.builder(
          mobile: mobile,
          tablet: tablet,
          desktop: desktop,
        );
      },
    );
  }
}

/// Responsive grid view
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final EdgeInsets? padding;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, responsive) {
        return GridView.builder(
          padding: padding ?? EdgeInsets.all(responsive.padding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: responsive.gridColumns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: responsive.isLandscape ? 1.5 : 1.2,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

/// Responsive padding widget
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final bool horizontal;
  final bool vertical;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.horizontal = true,
    this.vertical = true,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, responsive) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontal ? responsive.horizontalPadding : 0,
            vertical: vertical ? responsive.padding : 0,
          ),
          child: child,
        );
      },
    );
  }
}

/// Responsive container - maksimum genişlik sınırı ile
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, responsive) {
        return Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding:
                padding ?? EdgeInsets.symmetric(horizontal: responsive.padding),
            child: child,
          ),
        );
      },
    );
  }
}

/// Extension for easy access
extension ResponsiveContext on BuildContext {
  ResponsiveHelper get responsive => ResponsiveHelper(this);
}
