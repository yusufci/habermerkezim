import 'package:flutter/material.dart';

/// Custom page route animasyonları
/// Farklı geçiş efektleri sağlar
class CustomPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final PageTransitionType transitionType;
  final Duration duration;
  final Curve curve;

  CustomPageRoute({
    required this.page,
    this.transitionType = PageTransitionType.slide,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOutCubic,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           return _buildTransition(
             transitionType,
             animation,
             secondaryAnimation,
             child,
             curve,
           );
         },
       );

  static Widget _buildTransition(
    PageTransitionType type,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    Curve curve,
  ) {
    final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);

    switch (type) {
      case PageTransitionType.slide:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case PageTransitionType.fade:
        return FadeTransition(opacity: curvedAnimation, child: child);

      case PageTransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(opacity: curvedAnimation, child: child),
        );

      case PageTransitionType.rotation:
        return RotationTransition(
          turns: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(opacity: curvedAnimation, child: child),
        );

      case PageTransitionType.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case PageTransitionType.slideDown:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, -1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case PageTransitionType.fadeScale:
        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );

      case PageTransitionType.slideRotate:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: RotationTransition(
            turns: Tween<double>(begin: 0.1, end: 0.0).animate(curvedAnimation),
            child: child,
          ),
        );
    }
  }
}

/// Page transition türleri
enum PageTransitionType {
  slide,
  fade,
  scale,
  rotation,
  slideUp,
  slideDown,
  fadeScale,
  slideRotate,
}

/// Modal için özel route
class ModalPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  ModalPageRoute({
    required this.page,
    super.barrierDismissible = true,
    super.barrierColor = Colors.black54,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionDuration: const Duration(milliseconds: 300),
         reverseTransitionDuration: const Duration(milliseconds: 300),
         opaque: false,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final curvedAnimation = CurvedAnimation(
             parent: animation,
             curve: Curves.easeOutCubic,
           );

           return FadeTransition(
             opacity: curvedAnimation,
             child: ScaleTransition(
               scale: Tween<double>(
                 begin: 0.9,
                 end: 1.0,
               ).animate(curvedAnimation),
               child: child,
             ),
           );
         },
       );
}

/// Bottom sheet için özel route
class BottomSheetPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  BottomSheetPageRoute({required this.page, super.barrierDismissible = true})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        opaque: false,
        barrierColor: Colors.black54,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          );
        },
      );
}

/// Navigation helper extension
extension NavigationExtension on BuildContext {
  /// Slide transition ile navigate
  Future<T?> pushWithSlide<T>(Widget page) {
    return Navigator.of(this).push<T>(
      CustomPageRoute(page: page, transitionType: PageTransitionType.slide),
    );
  }

  /// Fade transition ile navigate
  Future<T?> pushWithFade<T>(Widget page) {
    return Navigator.of(this).push<T>(
      CustomPageRoute(page: page, transitionType: PageTransitionType.fade),
    );
  }

  /// Scale transition ile navigate
  Future<T?> pushWithScale<T>(Widget page) {
    return Navigator.of(this).push<T>(
      CustomPageRoute(page: page, transitionType: PageTransitionType.scale),
    );
  }

  /// Modal olarak aç
  Future<T?> pushModal<T>(Widget page) {
    return Navigator.of(this).push<T>(ModalPageRoute(page: page));
  }

  /// Bottom sheet olarak aç
  Future<T?> pushBottomSheet<T>(Widget page) {
    return Navigator.of(this).push<T>(BottomSheetPageRoute(page: page));
  }
}
