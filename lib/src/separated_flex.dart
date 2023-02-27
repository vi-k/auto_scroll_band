import 'package:flutter/material.dart';

/// Separated Flex.
///
/// The point of this widget is only to place widgets with a separator
/// between them.
class SeparatedFlex extends StatelessWidget {
  final Axis direction;
  final double? spacing;
  final Widget? separator;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final TextBaseline? textBaseline;
  final Clip clipBehavior;
  final List<Widget> children;

  const SeparatedFlex({
    Key? key,
    required this.direction,
    this.spacing,
    this.separator,
    MainAxisAlignment? mainAxisAlignment,
    MainAxisSize? mainAxisSize,
    CrossAxisAlignment? crossAxisAlignment,
    this.textDirection,
    VerticalDirection? verticalDirection,
    this.textBaseline,
    Clip? clipBehavior,
    required this.children,
  })  : assert(spacing == null || separator == null),
        mainAxisAlignment = mainAxisAlignment ?? MainAxisAlignment.start,
        mainAxisSize = mainAxisSize ?? MainAxisSize.min,
        crossAxisAlignment = crossAxisAlignment ?? CrossAxisAlignment.center,
        verticalDirection = verticalDirection ?? VerticalDirection.down,
        clipBehavior = clipBehavior ?? Clip.none,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final separator = this.separator ??
        (spacing == null
            ? null
            : SizedBox(
                height: direction == Axis.vertical ? spacing : null,
                width: direction == Axis.horizontal ? spacing : null,
              ));

    return Flex(
      direction: direction,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: textDirection,
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
      clipBehavior: clipBehavior,
      children: separator == null
          ? children
          : [
              for (var i = 0; i < children.length; i++) ...[
                if (i != 0) separator,
                children[i],
              ],
            ],
    );
  }
}

class SeparatedRow extends SeparatedFlex {
  const SeparatedRow({
    super.key,
    super.spacing,
    super.separator,
    super.mainAxisAlignment,
    super.mainAxisSize,
    super.crossAxisAlignment,
    super.verticalDirection,
    super.textBaseline,
    super.clipBehavior,
    required super.children,
  }) : super(direction: Axis.horizontal);
}

class SeparatedColumn extends SeparatedFlex {
  const SeparatedColumn({
    super.key,
    super.spacing,
    super.separator,
    super.mainAxisAlignment,
    super.mainAxisSize,
    super.crossAxisAlignment,
    super.verticalDirection,
    super.textBaseline,
    super.clipBehavior,
    required super.children,
  }) : super(direction: Axis.vertical);
}
