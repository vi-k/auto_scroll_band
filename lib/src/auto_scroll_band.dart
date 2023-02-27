import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'custom_scroll_band.dart';
import 'scroll_band_controller.dart';

class AutoScrollBand extends StatefulWidget {
  final Axis? scrollDirection;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final DragStartBehavior? dragStartBehavior;
  final Clip? clipBehavior;
  final String? restorationId;
  final ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior;
  final MainAxisAlignment? mainAxisAlignment;
  final MainAxisSize? mainAxisSize;
  final CrossAxisAlignment? crossAxisAlignment;
  final VerticalDirection? verticalDirection;
  final TextBaseline? textBaseline;
  final double? innerWidth;
  final double? innerHeight;
  final ScrollBandController? controller;
  final double? spacing;
  final Widget? separator;
  final List<Widget> children;
  final bool Function(int index) selected;
  final double startExtraIndent;
  final double endExtraIndent;
  final bool initialAnimation;
  final ScrollAxisAlign initialAlign;
  final ScrollAxisAlign initialAlignIfNotFit;
  final ScrollAxisAlign align;
  final ScrollAxisAlign alignIfNotFit;
  final bool initialMoveIfVisible;
  final bool moveIfVisible;
  final bool allowMovementOutside;
  final Duration? duration;
  final Curve? curve;

  const AutoScrollBand({
    super.key,
    this.scrollDirection,
    this.padding,
    this.physics,
    this.dragStartBehavior,
    this.clipBehavior,
    this.restorationId,
    this.keyboardDismissBehavior,
    this.mainAxisAlignment,
    this.mainAxisSize,
    this.crossAxisAlignment,
    this.verticalDirection,
    this.textBaseline,
    this.innerWidth,
    this.innerHeight,
    this.controller,
    this.spacing,
    this.separator,
    required this.children,
    required this.selected,
    double? startExtraIndent,
    double? endExtraIndent,
    bool? initialAnimation,
    ScrollAxisAlign? initialAlign,
    ScrollAxisAlign? initialAlignIfNotFit,
    ScrollAxisAlign? align,
    ScrollAxisAlign? alignIfNotFit,
    bool? initialMoveIfVisible,
    bool? moveIfVisible,
    bool? allowMovementOutside,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.fastOutSlowIn,
  })  : startExtraIndent = startExtraIndent ?? 0,
        endExtraIndent = endExtraIndent ?? 0,
        initialAnimation = initialAnimation ?? false,
        initialAlign = initialAlign ?? ScrollAxisAlign.center,
        initialAlignIfNotFit = initialAlignIfNotFit ?? ScrollAxisAlign.start,
        align = align ?? ScrollAxisAlign.center,
        alignIfNotFit = alignIfNotFit ?? ScrollAxisAlign.start,
        initialMoveIfVisible = initialMoveIfVisible ?? true,
        moveIfVisible = moveIfVisible ?? true,
        allowMovementOutside = allowMovementOutside ?? false;

  bool get hasSeparator => spacing != null || separator != null;
  int get childIncrement => hasSeparator ? 2 : 1;

  @override
  State<AutoScrollBand> createState() => _AutoScrollBandState();
}

class _AutoScrollBandState extends State<AutoScrollBand> {
  ScrollBandController? _controller;
  final Set<int> _selected = {};
  late bool _firstFrameDone;

  ScrollBandController get controller => widget.controller ?? _controller!;

  @override
  void initState() {
    super.initState();

    if (widget.controller == null) {
      _controller = ScrollBandController();
    }

    _firstFrameDone = widget.initialAnimation;

    _update();
    _delayedShow(_selected, init: true);
  }

  @override
  void dispose() {
    _controller?.dispose();

    super.dispose();
  }

  void _update() {
    _selected.clear();
    final count = widget.children.length;

    for (var i = 0; i < count; i++) {
      if (widget.selected(i)) {
        _selected.add(i);
      }
    }
  }

  void _delayedShow(Set<int> set, {bool init = false}) {
    if (set.isNotEmpty) {
      Future<void>.microtask(() {
        final childIncrement = widget.childIncrement;
        final first = set.reduce(math.min) * childIncrement;
        final last = set.reduce(math.max) * childIncrement;

        controller.showChildren(
          first,
          last,
          startExtraIndent: widget.startExtraIndent,
          endExtraIndent: widget.endExtraIndent,
          align: init ? widget.initialAlign : widget.align,
          alignIfNotFit:
              init ? widget.initialAlignIfNotFit : widget.alignIfNotFit,
          moveIfVisible:
              init ? widget.initialMoveIfVisible : widget.moveIfVisible,
          allowMovementOutside: widget.allowMovementOutside,
          duration: init && !widget.initialAnimation ? null : widget.duration,
          curve: init && !widget.initialAnimation ? null : widget.curve,
        );
      });
    }
  }

  @override
  void didUpdateWidget(covariant AutoScrollBand oldWidget) {
    super.didUpdateWidget(oldWidget);

    final selected = Set<int>.from(_selected);

    _update();

    final newSelected = _selected.difference(selected);
    _delayedShow(newSelected);
  }

  @override
  Widget build(BuildContext context) {
    Widget child = CustomScrollBand(
      scrollDirection: widget.scrollDirection,
      padding: widget.padding,
      physics: widget.physics,
      dragStartBehavior: widget.dragStartBehavior,
      clipBehavior: widget.clipBehavior,
      restorationId: widget.restorationId,
      keyboardDismissBehavior: widget.keyboardDismissBehavior,
      mainAxisAlignment: widget.mainAxisAlignment,
      mainAxisSize: widget.mainAxisSize,
      crossAxisAlignment: widget.crossAxisAlignment,
      verticalDirection: widget.verticalDirection,
      textBaseline: widget.textBaseline,
      innerWidth: widget.innerWidth,
      innerHeight: widget.innerHeight,
      controller: controller,
      spacing: widget.spacing,
      separator: widget.separator,
      children: widget.children,
    );

    // Перед тем как переместить скролл в нужное место, должны быть вычислены
    // все размеры. Поэтому установить нужное смещение мы сможем только во
    // втором кадре. Но чтобы не было дёргания, в первом кадре убираем скролл
    // с экрана.
    if (!widget.initialAnimation) {
      child = Opacity(
        opacity: _firstFrameDone ? 1 : 0,
        child: child,
      );

      if (!_firstFrameDone) {
        Future<void>.microtask(() {
          setState(() {
            _firstFrameDone = true;
          });
        });
      }
    }

    return child;
  }
}
