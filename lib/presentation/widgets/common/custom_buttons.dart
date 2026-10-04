import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../themes/app_theme.dart';

/// Buton boyutları
enum ButtonSize { small, medium, large }

/// Buton varyantları
enum ButtonVariant {
  /// Dolu arka plan, birincil renk
  primary,

  /// Dolu arka plan, ikincil renk
  secondary,

  /// Sadece kenarlık
  outlined,

  /// Sadece metin
  text,

  /// Tehlike/silme işlemleri için
  danger,

  /// Başarı işlemleri için
  success,

  /// Glassmorphism efekti
  glass,
}

/// Modern Primary Button - Gradient ve gölge efektli
class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final ButtonSize size;
  final bool fullWidth;
  final Color? customColor;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.size = ButtonSize.medium,
    this.fullWidth = false,
    this.customColor,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }

  double _getFontSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 13;
      case ButtonSize.medium:
        return 15;
      case ButtonSize.large:
        return 17;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.customColor ?? theme.colorScheme.primary;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.fullWidth ? double.infinity : null,
          padding: _getPadding(),
          decoration: BoxDecoration(
            gradient: isDisabled
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                  ),
            color: isDisabled
                ? theme.colorScheme.onSurface.withValues(alpha: 0.12)
                : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: primaryColor.withValues(
                        alpha: _isPressed ? 0.4 : 0.3,
                      ),
                      blurRadius: _isPressed ? 12 : 8,
                      offset: Offset(0, _isPressed ? 6 : 4),
                      spreadRadius: _isPressed ? 1 : 0,
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: widget.fullWidth
                ? MainAxisSize.max
                : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                SizedBox(
                  width: _getIconSize(),
                  height: _getIconSize(),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDisabled
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                          : Colors.white,
                    ),
                  ),
                )
              else if (widget.icon != null)
                Icon(
                  widget.icon,
                  size: _getIconSize(),
                  color: isDisabled
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                      : Colors.white,
                ),
              if ((widget.icon != null || widget.isLoading) &&
                  widget.text.isNotEmpty)
                const SizedBox(width: 8),
              Text(
                widget.text,
                style: TextStyle(
                  fontSize: _getFontSize(),
                  fontWeight: FontWeight.w600,
                  color: isDisabled
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                      : Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Secondary Button - Outlined style
class SecondaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final ButtonSize size;
  final bool fullWidth;
  final Color? customColor;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.size = ButtonSize.medium,
    this.fullWidth = false,
    this.customColor,
  });

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }

  double _getFontSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 13;
      case ButtonSize.medium:
        return 15;
      case ButtonSize.large:
        return 17;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.customColor ?? theme.colorScheme.primary;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          onTap: isDisabled ? null : widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.fullWidth ? double.infinity : null,
            padding: _getPadding(),
            decoration: BoxDecoration(
              color: _isHovered || _isPressed
                  ? primaryColor.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDisabled
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.12)
                    : primaryColor.withValues(alpha: _isHovered ? 1.0 : 0.6),
                width: _isHovered || _isPressed ? 2 : 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: widget.fullWidth
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading)
                  SizedBox(
                    width: _getIconSize(),
                    height: _getIconSize(),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDisabled
                            ? theme.colorScheme.onSurface.withValues(
                                alpha: 0.38,
                              )
                            : primaryColor,
                      ),
                    ),
                  )
                else if (widget.icon != null)
                  Icon(
                    widget.icon,
                    size: _getIconSize(),
                    color: isDisabled
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                        : primaryColor,
                  ),
                if ((widget.icon != null || widget.isLoading) &&
                    widget.text.isNotEmpty)
                  const SizedBox(width: 8),
                Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: _getFontSize(),
                    fontWeight: FontWeight.w600,
                    color: isDisabled
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                        : primaryColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Text Button - Minimal style
class TertiaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final ButtonSize size;
  final Color? customColor;

  const TertiaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.size = ButtonSize.medium,
    this.customColor,
  });

  @override
  State<TertiaryButton> createState() => _TertiaryButtonState();
}

class _TertiaryButtonState extends State<TertiaryButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 10);
    }
  }

  double _getFontSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 13;
      case ButtonSize.medium:
        return 15;
      case ButtonSize.large:
        return 17;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.customColor ?? theme.colorScheme.primary;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) {
          if (!isDisabled) {
            setState(() => _isPressed = true);
            HapticFeedback.selectionClick();
          }
        },
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: _getPadding(),
          decoration: BoxDecoration(
            color: _isHovered || _isPressed
                ? primaryColor.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isLoading)
                SizedBox(
                  width: _getIconSize(),
                  height: _getIconSize(),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDisabled
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                          : primaryColor,
                    ),
                  ),
                )
              else if (widget.icon != null)
                Icon(
                  widget.icon,
                  size: _getIconSize(),
                  color: isDisabled
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                      : primaryColor,
                ),
              if ((widget.icon != null || widget.isLoading) &&
                  widget.text.isNotEmpty)
                const SizedBox(width: 6),
              Text(
                widget.text,
                style: TextStyle(
                  fontSize: _getFontSize(),
                  fontWeight: FontWeight.w600,
                  color: isDisabled
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                      : primaryColor,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Danger Button - Kırmızı, tehlike işlemleri için
class DangerButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final ButtonSize size;
  final bool fullWidth;
  final bool outlined;

  const DangerButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.size = ButtonSize.medium,
    this.fullWidth = false,
    this.outlined = false,
  });

  @override
  State<DangerButton> createState() => _DangerButtonState();
}

class _DangerButtonState extends State<DangerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.mediumImpact();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }

  double _getFontSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 13;
      case ButtonSize.medium:
        return 15;
      case ButtonSize.large:
        return 17;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const dangerColor = AppTheme.errorRed;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.fullWidth ? double.infinity : null,
          padding: _getPadding(),
          decoration: BoxDecoration(
            gradient: widget.outlined || isDisabled
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [dangerColor, dangerColor.withValues(alpha: 0.85)],
                  ),
            color: isDisabled
                ? theme.colorScheme.onSurface.withValues(alpha: 0.12)
                : widget.outlined
                ? (_isPressed
                      ? dangerColor.withValues(alpha: 0.08)
                      : Colors.transparent)
                : null,
            borderRadius: BorderRadius.circular(12),
            border: widget.outlined
                ? Border.all(
                    color: isDisabled
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.12)
                        : dangerColor,
                    width: 1.5,
                  )
                : null,
            boxShadow: widget.outlined || isDisabled
                ? null
                : [
                    BoxShadow(
                      color: dangerColor.withValues(
                        alpha: _isPressed ? 0.4 : 0.3,
                      ),
                      blurRadius: _isPressed ? 12 : 8,
                      offset: Offset(0, _isPressed ? 6 : 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: widget.fullWidth
                ? MainAxisSize.max
                : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                SizedBox(
                  width: _getIconSize(),
                  height: _getIconSize(),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.outlined ? dangerColor : Colors.white,
                    ),
                  ),
                )
              else if (widget.icon != null)
                Icon(
                  widget.icon,
                  size: _getIconSize(),
                  color: isDisabled
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                      : widget.outlined
                      ? dangerColor
                      : Colors.white,
                ),
              if ((widget.icon != null || widget.isLoading) &&
                  widget.text.isNotEmpty)
                const SizedBox(width: 8),
              Text(
                widget.text,
                style: TextStyle(
                  fontSize: _getFontSize(),
                  fontWeight: FontWeight.w600,
                  color: isDisabled
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                      : widget.outlined
                      ? dangerColor
                      : Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon Button - Modern circular icon button
class ModernIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final String? tooltip;
  final bool showBorder;

  const ModernIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = 40,
    this.tooltip,
    this.showBorder = false,
  });

  @override
  State<ModernIconButton> createState() => _ModernIconButtonState();
}

class _ModernIconButtonState extends State<ModernIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = widget.color ?? theme.colorScheme.onSurface;
    final bgColor =
        widget.backgroundColor ??
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final isDisabled = widget.onPressed == null;

    final Widget button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) {
            if (!isDisabled) {
              _controller.forward();
              HapticFeedback.selectionClick();
            }
          },
          onTapUp: (_) => _controller.reverse(),
          onTapCancel: () => _controller.reverse(),
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: _isHovered ? bgColor.withValues(alpha: 0.8) : bgColor,
              shape: BoxShape.circle,
              border: widget.showBorder
                  ? Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    )
                  : null,
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: iconColor.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              widget.icon,
              size: widget.size * 0.5,
              color: isDisabled ? iconColor.withValues(alpha: 0.38) : iconColor,
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }

    return button;
  }
}

/// Floating Action Button - Modern tasarım
class ModernFAB extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? label;
  final bool extended;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ModernFAB({
    super.key,
    required this.icon,
    this.onPressed,
    this.label,
    this.extended = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<ModernFAB> createState() => _ModernFABState();
}

class _ModernFABState extends State<ModernFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = widget.backgroundColor ?? theme.colorScheme.primary;
    final fgColor = widget.foregroundColor ?? theme.colorScheme.onPrimary;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) {
            _controller.forward();
            HapticFeedback.mediumImpact();
          },
          onTapUp: (_) => _controller.reverse(),
          onTapCancel: () => _controller.reverse(),
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: widget.extended
                ? const EdgeInsets.symmetric(horizontal: 20, vertical: 16)
                : const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bgColor, bgColor.withValues(alpha: 0.85)],
              ),
              borderRadius: BorderRadius.circular(widget.extended ? 28 : 16),
              boxShadow: [
                BoxShadow(
                  color: bgColor.withValues(alpha: _isHovered ? 0.5 : 0.35),
                  blurRadius: _isHovered ? 20 : 12,
                  offset: Offset(0, _isHovered ? 8 : 6),
                  spreadRadius: _isHovered ? 2 : 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 24, color: fgColor),
                if (widget.extended && widget.label != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    widget.label!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: fgColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip Button - Seçilebilir chip tarzı buton
class ChipButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? selectedColor;

  const ChipButton({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onPressed,
    this.icon,
    this.selectedColor,
  });

  @override
  State<ChipButton> createState() => _ChipButtonState();
}

class _ChipButtonState extends State<ChipButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = widget.selectedColor ?? theme.colorScheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onPressed?.call();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? selectedColor.withValues(alpha: 0.15)
                : _isHovered
                ? theme.colorScheme.surfaceContainerHighest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected
                  ? selectedColor
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: widget.isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.isSelected
                      ? selectedColor
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.isSelected
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: widget.isSelected
                      ? selectedColor
                      : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              if (widget.isSelected) ...[
                const SizedBox(width: 6),
                Icon(Icons.check_rounded, size: 14, color: selectedColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Gradient Button - Özel gradient ile buton
class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final List<Color> gradientColors;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    required this.gradientColors,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: GestureDetector(
        onTapDown: (_) {
          if (!isDisabled) {
            setState(() => _isPressed = true);
            _controller.forward();
            HapticFeedback.lightImpact();
          }
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _controller.reverse();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _controller.reverse();
        },
        onTap: isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            gradient: isDisabled
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.gradientColors,
                  ),
            color: isDisabled
                ? theme.colorScheme.onSurface.withValues(alpha: 0.12)
                : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: widget.gradientColors.first.withValues(
                        alpha: _isPressed ? 0.5 : 0.35,
                      ),
                      blurRadius: _isPressed ? 16 : 10,
                      offset: Offset(0, _isPressed ? 8 : 5),
                      spreadRadius: _isPressed ? 2 : 0,
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: widget.fullWidth
                ? MainAxisSize.max
                : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else if (widget.icon != null)
                Icon(widget.icon, size: 20, color: Colors.white),
              if ((widget.icon != null || widget.isLoading) &&
                  widget.text.isNotEmpty)
                const SizedBox(width: 10),
              Text(
                widget.text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDisabled
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                      : Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
