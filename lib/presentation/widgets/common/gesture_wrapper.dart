import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Swipe yönleri
enum SwipeDirection { left, right, up, down }

/// Swipe action widget - kaydırma ile aksiyon
class SwipeActionWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final Widget? leftActionWidget;
  final Widget? rightActionWidget;
  final Color? leftActionColor;
  final Color? rightActionColor;
  final IconData? leftActionIcon;
  final IconData? rightActionIcon;
  final double threshold;
  final bool enabled;
  final bool confirmDismiss;

  const SwipeActionWidget({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.leftActionWidget,
    this.rightActionWidget,
    this.leftActionColor,
    this.rightActionColor,
    this.leftActionIcon,
    this.rightActionIcon,
    this.threshold = 0.3,
    this.enabled = true,
    this.confirmDismiss = false,
  });

  @override
  State<SwipeActionWidget> createState() => _SwipeActionWidgetState();
}

class _SwipeActionWidgetState extends State<SwipeActionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragExtent = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    if (!widget.enabled) return;
    _isDragging = true;
    _dragExtent = 0;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled || !_isDragging) return;

    setState(() {
      _dragExtent += details.primaryDelta ?? 0;

      // Sınırla
      if (widget.onSwipeRight == null && _dragExtent > 0) {
        _dragExtent = 0;
      }
      if (widget.onSwipeLeft == null && _dragExtent < 0) {
        _dragExtent = 0;
      }
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!widget.enabled || !_isDragging) return;
    _isDragging = false;

    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * widget.threshold;

    if (_dragExtent.abs() > threshold) {
      if (_dragExtent > 0 && widget.onSwipeRight != null) {
        HapticFeedback.mediumImpact();
        widget.onSwipeRight!();
      } else if (_dragExtent < 0 && widget.onSwipeLeft != null) {
        HapticFeedback.mediumImpact();
        widget.onSwipeLeft!();
      }
    }

    setState(() {
      _dragExtent = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Sol aksiyon arka planı
        if (_dragExtent > 0 && widget.onSwipeRight != null)
          Positioned.fill(
            child: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 24),
              decoration: BoxDecoration(
                color: widget.rightActionColor ?? Colors.green,
              ),
              child:
                  widget.rightActionWidget ??
                  Icon(
                    widget.rightActionIcon ?? Icons.check_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
            ),
          ),

        // Sağ aksiyon arka planı
        if (_dragExtent < 0 && widget.onSwipeLeft != null)
          Positioned.fill(
            child: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              decoration: BoxDecoration(
                color: widget.leftActionColor ?? Colors.red,
              ),
              child:
                  widget.leftActionWidget ??
                  Icon(
                    widget.leftActionIcon ?? Icons.delete_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
            ),
          ),

        // Ana içerik
        GestureDetector(
          onHorizontalDragStart: _handleDragStart,
          onHorizontalDragUpdate: _handleDragUpdate,
          onHorizontalDragEnd: _handleDragEnd,
          child: Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

/// Double tap widget
class DoubleTapWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onDoubleTap;
  final Widget? doubleTapFeedback;
  final Duration feedbackDuration;
  final bool showFeedback;

  const DoubleTapWidget({
    super.key,
    required this.child,
    this.onDoubleTap,
    this.doubleTapFeedback,
    this.feedbackDuration = const Duration(milliseconds: 800),
    this.showFeedback = true,
  });

  @override
  State<DoubleTapWidget> createState() => _DoubleTapWidgetState();
}

class _DoubleTapWidgetState extends State<DoubleTapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _showFeedback = false;
  Offset _tapPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.feedbackDuration,
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showFeedback = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    HapticFeedback.mediumImpact();
    widget.onDoubleTap?.call();

    if (widget.showFeedback) {
      setState(() {
        _showFeedback = true;
      });
      _controller.forward(from: 0);
    }
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _tapPosition = details.localPosition;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      onDoubleTapDown: _handleDoubleTapDown,
      child: Stack(
        children: [
          widget.child,
          if (_showFeedback)
            Positioned(
              left: _tapPosition.dx - 30,
              top: _tapPosition.dy - 30,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _opacityAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child:
                    widget.doubleTapFeedback ??
                    const Icon(
                      Icons.favorite_rounded,
                      color: Colors.red,
                      size: 60,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Long press widget
class LongPressWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onLongPress;
  final Widget Function(BuildContext context)? contextMenuBuilder;
  final Duration longPressDuration;
  final bool showContextMenu;

  const LongPressWidget({
    super.key,
    required this.child,
    this.onLongPress,
    this.contextMenuBuilder,
    this.longPressDuration = const Duration(milliseconds: 500),
    this.showContextMenu = false,
  });

  @override
  State<LongPressWidget> createState() => _LongPressWidgetState();
}

class _LongPressWidgetState extends State<LongPressWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
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

  void _handleLongPressStart(LongPressStartDetails details) {
    _controller.forward();
  }

  void _handleLongPress() {
    HapticFeedback.heavyImpact();
    widget.onLongPress?.call();

    if (widget.showContextMenu && widget.contextMenuBuilder != null) {
      _showContextMenu();
    }
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    _controller.reverse();
  }

  void _showContextMenu() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + size.height,
        position.dx + size.width,
        position.dy + size.height + 100,
      ),
      items: [PopupMenuItem(child: widget.contextMenuBuilder!(context))],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: _handleLongPressStart,
      onLongPress: _handleLongPress,
      onLongPressEnd: _handleLongPressEnd,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: widget.child,
      ),
    );
  }
}

/// Pinch to zoom widget
class PinchToZoomWidget extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final bool enabled;
  final VoidCallback? onZoomStart;
  final VoidCallback? onZoomEnd;

  const PinchToZoomWidget({
    super.key,
    required this.child,
    this.minScale = 1.0,
    this.maxScale = 3.0,
    this.enabled = true,
    this.onZoomStart,
    this.onZoomEnd,
  });

  @override
  State<PinchToZoomWidget> createState() => _PinchToZoomWidgetState();
}

class _PinchToZoomWidgetState extends State<PinchToZoomWidget>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  bool _isZooming = false;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onInteractionStart(ScaleStartDetails details) {
    if (!widget.enabled) return;

    if (!_isZooming) {
      _isZooming = true;
      widget.onZoomStart?.call();
    }
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    if (!widget.enabled) return;

    final scale = _transformationController.value.getMaxScaleOnAxis();

    if (scale < widget.minScale) {
      _animateToIdentity();
    }

    if (_isZooming) {
      _isZooming = false;
      widget.onZoomEnd?.call();
    }
  }

  void _animateToIdentity() {
    _animation =
        Matrix4Tween(
          begin: _transformationController.value,
          end: Matrix4.identity(),
        ).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animation!.addListener(() {
      _transformationController.value = _animation!.value;
    });

    _animationController.forward(from: 0);
  }

  void _onDoubleTap() {
    if (!widget.enabled) return;

    final scale = _transformationController.value.getMaxScaleOnAxis();

    if (scale > widget.minScale) {
      _animateToIdentity();
    } else {
      final position = _transformationController.value.getTranslation();
      final zoomed = Matrix4.identity()
        // ignore: deprecated_member_use
        ..translate(position.x, position.y)
        // ignore: deprecated_member_use
        ..scale(2.0);

      _animation =
          Matrix4Tween(
            begin: _transformationController.value,
            end: zoomed,
          ).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOut,
            ),
          );

      _animation!.addListener(() {
        _transformationController.value = _animation!.value;
      });

      _animationController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: widget.minScale,
        maxScale: widget.maxScale,
        onInteractionStart: _onInteractionStart,
        onInteractionEnd: _onInteractionEnd,
        child: widget.child,
      ),
    );
  }
}

/// Pull to refresh custom widget
class CustomPullToRefresh extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Widget? refreshIndicator;
  final double triggerDistance;
  final Color? indicatorColor;

  const CustomPullToRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
    this.refreshIndicator,
    this.triggerDistance = 100,
    this.indicatorColor,
  });

  @override
  State<CustomPullToRefresh> createState() => _CustomPullToRefreshState();
}

class _CustomPullToRefreshState extends State<CustomPullToRefresh>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    HapticFeedback.mediumImpact();
    await widget.onRefresh();

    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorColor = widget.indicatorColor ?? theme.colorScheme.primary;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: indicatorColor,
      backgroundColor: theme.colorScheme.surface,
      strokeWidth: 2.5,
      displacement: 40,
      child: widget.child,
    );
  }
}
