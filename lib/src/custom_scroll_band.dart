import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'scroll_band_controller.dart';
import 'separated_flex.dart';

class CustomScrollBand extends StatefulWidget {
  final Axis scrollDirection;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final DragStartBehavior dragStartBehavior;
  final Clip clipBehavior;
  final String? restorationId;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final VerticalDirection verticalDirection;
  final TextBaseline? textBaseline;
  final double? innerWidth;
  final double? innerHeight;
  final ScrollBandController? controller;
  final double? spacing;
  final Widget? separator;
  final List<Widget> children;

  const CustomScrollBand({
    super.key,
    Axis? scrollDirection,
    this.padding,
    this.physics,
    DragStartBehavior? dragStartBehavior,
    Clip? clipBehavior,
    this.restorationId,
    ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior,
    MainAxisAlignment? mainAxisAlignment,
    MainAxisSize? mainAxisSize,
    CrossAxisAlignment? crossAxisAlignment,
    VerticalDirection? verticalDirection,
    this.textBaseline,
    this.innerWidth,
    this.innerHeight,
    this.controller,
    this.spacing,
    this.separator,
    required this.children,
  })  : scrollDirection = scrollDirection ?? Axis.horizontal,
        dragStartBehavior = dragStartBehavior ?? DragStartBehavior.start,
        clipBehavior = clipBehavior ?? Clip.hardEdge,
        keyboardDismissBehavior =
            keyboardDismissBehavior ?? ScrollViewKeyboardDismissBehavior.manual,
        mainAxisAlignment = mainAxisAlignment ?? MainAxisAlignment.start,
        mainAxisSize = mainAxisSize ?? MainAxisSize.max,
        crossAxisAlignment = crossAxisAlignment ?? CrossAxisAlignment.center,
        verticalDirection = verticalDirection ?? VerticalDirection.down;

  bool get hasSeparator => spacing != null || separator != null;
  int get childIncrement => hasSeparator ? 2 : 1;

  @override
  State<CustomScrollBand> createState() => CustomScrollBandState();
}

class CustomScrollBandState extends State<CustomScrollBand> {
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: widget.scrollDirection,
        padding: widget.padding,
        controller: widget.controller,
        dragStartBehavior: widget.dragStartBehavior,
        clipBehavior: widget.clipBehavior,
        restorationId: widget.restorationId,
        keyboardDismissBehavior: widget.keyboardDismissBehavior,
        child: SizedBox(
          width: widget.innerWidth,
          height: widget.innerHeight,
          child: SeparatedFlex(
            direction: widget.scrollDirection,
            spacing: widget.spacing,
            separator: widget.separator,
            mainAxisAlignment: widget.mainAxisAlignment,
            mainAxisSize: widget.mainAxisSize,
            crossAxisAlignment: widget.crossAxisAlignment,
            verticalDirection: widget.verticalDirection,
            textBaseline: widget.textBaseline,
            children: widget.children,
          ),
        ),
      );
}
