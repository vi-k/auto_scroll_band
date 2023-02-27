import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class FindRenderChildResult<T> {
  final T renderObject;
  final EdgeInsetsGeometry padding;

  FindRenderChildResult(this.renderObject, this.padding);
}

extension on BuildContext {
  FindRenderChildResult<T>? findRenderChildWithCalcPadding<T>() {
    EdgeInsetsGeometry padding = EdgeInsets.zero;
    var renderObject = findRenderObject();

    while (renderObject != null && renderObject.runtimeType != T) {
      if (renderObject is RenderPadding) {
        padding = padding.add(renderObject.padding);
      }

      RenderObject? renderChild;

      renderObject.visitChildren((child) {
        renderChild = child;
      });

      renderObject = renderChild;
    }

    return renderObject == null
        ? null
        : FindRenderChildResult(renderObject as T, padding);
  }
}

class ScrollAxisAlign {
  static const nearest = ScrollAxisAlign._(double.nan);
  static const start = ScrollAxisAlign(0);
  static const center = ScrollAxisAlign(0.5);
  static const end = ScrollAxisAlign(1);

  final double value;

  const ScrollAxisAlign._(this.value);
  const ScrollAxisAlign(this.value) : assert(value >= 0 && value <= 1);

  bool get isExactAlign => value.isFinite;

  ScrollAxisAlign get reverse =>
      ScrollAxisAlign._(value.isFinite ? 1 - value : value);
}

class ScrollBandController extends ScrollController {
  ScrollBandController({
    super.initialScrollOffset = 0.0,
    super.keepScrollOffset = true,
    super.debugLabel,
  }) : super();

  FindRenderChildResult<RenderFlex> _findRenderFlex() {
    final renderFlex = position.context.storageContext
        .findRenderChildWithCalcPadding<RenderFlex>();
    if (renderFlex != null) {
      return renderFlex;
    }

    throw Exception('RenderFlex not found');
  }

  /// Возвращает смещение по заданной оси.
  static double axisOffset(Axis axis, Offset offset) {
    switch (axis) {
      case Axis.horizontal:
        return offset.dx;

      case Axis.vertical:
        return offset.dy;
    }
  }

  /// Возвращает размер по заданной оси.
  static double axisSize(Axis axis, Size size) {
    switch (axis) {
      case Axis.horizontal:
        return size.width;

      case Axis.vertical:
        return size.height;
    }
  }

  /// Возвращает оступы по заданной оси в сумме.
  static double axisTotalPadding(
    Axis axis,
    EdgeInsetsGeometry padding,
  ) {
    switch (axis) {
      case Axis.horizontal:
        return padding.horizontal;

      case Axis.vertical:
        return padding.vertical;
    }
  }

  /// Ищет нужный child по индексу.
  static RenderBox? childByIndex(RenderFlex parent, int index) {
    var child = parent.firstChild;

    var i = 0;
    while (child != null && i++ < index) {
      final childParentData = child.parentData! as FlexParentData;
      child = childParentData.nextSibling;
    }

    return child;
  }

  /// Показать область с [start] размером [size].
  ///
  /// Метод не вычисляет [padding], поэтому он должен быть передан.
  ///
  /// Подробное описание смотрите в [showArea].
  ///
  // ignore: long-method, long-parameter-list
  void _showArea({
    required double start,
    required double size,
    required EdgeInsetsGeometry padding,
    double? startExtraIndent,
    double? endExtraIndent,
    ScrollAxisAlign? align,
    ScrollAxisAlign? alignIfNotFit,
    bool? moveIfVisible,
    bool? allowMovementOutside,
    Duration? duration,
    Curve? curve,
  }) {
    startExtraIndent ??= 0;
    endExtraIndent ??= 0;
    align ??= ScrollAxisAlign.nearest;
    alignIfNotFit ??= align;
    moveIfVisible ??= false;
    allowMovementOutside ??= false;

    assert(
      duration == null && curve == null || duration != null && curve != null,
    );

    final areaStart = start - startExtraIndent;
    final areaEnd = start + size + endExtraIndent;
    final areaSize = areaEnd - areaStart;

    // Работаем только с одним скроллом. Не разрешаем подключать один контроллер
    // к двум и более.
    final scroll = position;

    // Область всегда задаётся в экранной сетке координат, т.е. слева направо.
    // В то время как смещение скролла зависит от направления текста.
    // Поэтому при необходимости корректируем все нужные значения.
    final reverse = scroll.axis == Axis.horizontal &&
        Directionality.maybeOf(position.context.storageContext) ==
            TextDirection.rtl;

    // Отступы с обоих концов скролла в сумме.
    final totalPadding = axisTotalPadding(scroll.axis, padding);

    // Размер видимой области скролла с учётом отступов.
    final viewSize = scroll.viewportDimension - totalPadding;

    // Размер всей области скролла с учётом отступов.
    final scrollableSize = scroll.maxScrollExtent + viewSize;

    // Текущая позиция скролла.
    final double scrollStart;
    final double scrollEnd;
    if (reverse) {
      scrollEnd = scrollableSize - offset;
      scrollStart = scrollEnd - viewSize;
    } else {
      scrollStart = offset;
      scrollEnd = scrollStart + viewSize;
    }

    // Выходим, если область уже видима.
    if (!moveIfVisible) {
      final visible = scrollStart <= areaStart && scrollEnd >= areaEnd;

      if (visible) return;
    }

    double newOffset;

    // Если требуемая область больше видимой области скролла.
    if (areaSize > viewSize) {
      final a = reverse ? alignIfNotFit.reverse : alignIfNotFit;

      newOffset = a.isExactAlign
          ? areaStart - (viewSize - areaSize) * a.value
          : scrollStart - areaStart < areaEnd - scrollEnd
              ? areaStart
              : areaEnd - viewSize;
    }
    // Если меньше или равна.
    else {
      final a = reverse ? align.reverse : align;

      newOffset = a.isExactAlign
          ? areaStart - (viewSize - areaSize) * a.value
          : areaStart < scrollStart
              ? areaStart
              : areaEnd > scrollEnd
                  ? areaEnd - viewSize
                  : scrollStart;
    }

    // Устанавливаем границы, чтобы перемещение не выходило за рамки доступной
    // области.
    if (!allowMovementOutside) {
      if (newOffset < 0) {
        newOffset = 0;
      } else if (newOffset + viewSize > scrollableSize) {
        newOffset = scrollableSize - viewSize;
      }
    }

    if (reverse) {
      newOffset = scrollableSize - viewSize - newOffset;
    }

    if (duration == null || curve == null) {
      jumpTo(newOffset);
    } else {
      animateTo(
        newOffset,
        duration: duration,
        curve: curve,
      );
    }
  }

  /// Показать область с [start] размером [size].
  ///
  /// С помощью [align] задаётся привязка к месту, где будет показана область.
  /// Это значение от 0 до 1, где:
  /// - 0 [ScrollAxisAlign.start] - начало видимой области скролла (с учётом
  ///   padding);
  /// - 0.5 [ScrollAxisAlign.center] - середина скролла;
  /// - 1 [ScrollAxisAlign.end] - конец скролла (с учётом padding).
  /// Есть и дополнительное значение для размещения к ближайшему краю:
  /// [ScrollAxisAlign.nearest]. Это значение по умолчанию.
  ///
  /// Параметром [alignInNotFit] задаётся привязка в случае, когда область
  /// больше видимой области скролла. По умолчанию равен [align].
  ///
  /// По умолчанию, если область уже находится в видимой области скролла
  /// (с учётом padding), перемещения не происходит. Флаг [moveIfVisible]
  /// меняет это поведение и перемещение происходит всегда.
  ///
  /// По умолчанию перемещение не выходит за рамки размеров скролла, даже если
  /// [align] предполагает этот выход. Флаг [allowMovementOutside] меняет это
  /// поведение. Но сам скролл, разумеется, не позволит сохранить эту позицию
  /// и вернёт куда нужно.
  ///
  /// Если заданы параметры [duration] и [curve], для перемещения используется
  /// метод [animateTo]. В ином случае [jumpTo].
  void showArea({
    required double start,
    required double size,
    double? startExtraIndent,
    double? endExtraIndent,
    ScrollAxisAlign? align,
    ScrollAxisAlign? alignIfNotFit,
    bool? moveIfVisible,
    bool? allowMovementOutside,
    Duration? duration,
    Curve? curve,
  }) {
    final r = _findRenderFlex();

    _showArea(
      start: start,
      size: size,
      padding: r.padding,
      startExtraIndent: startExtraIndent,
      endExtraIndent: endExtraIndent,
      align: align,
      alignIfNotFit: alignIfNotFit,
      moveIfVisible: moveIfVisible,
      allowMovementOutside: allowMovementOutside,
      duration: duration,
      curve: curve,
    );
  }

  /// Показать ребёнка по индексу [index].
  ///
  /// {@see showArea}.
  ///
  // ignore: long-method
  void showChild(
    int index, {
    double? startExtraIndent,
    double? endExtraIndent,
    ScrollAxisAlign? align,
    ScrollAxisAlign? alignIfNotFit,
    bool? moveIfVisible,
    bool? allowMovementOutside,
    Duration? duration,
    Curve? curve,
  }) {
    final scroll = position;

    // Ищем RenderFlex, рассчитываем padding.
    final r = _findRenderFlex();
    final renderFlex = r.renderObject;

    // Ищем нужный child.
    final child = childByIndex(renderFlex, index);
    if (child == null) {
      throw IndexError.withLength(
        index,
        renderFlex.childCount,
        indexable: renderFlex,
      );
    }

    final parentData = child.parentData! as ContainerBoxParentData<RenderBox>;
    final areaStart = axisOffset(scroll.axis, parentData.offset);
    final areaSize = axisSize(scroll.axis, child.size);

    _showArea(
      start: areaStart,
      size: areaSize,
      padding: r.padding,
      startExtraIndent: startExtraIndent,
      endExtraIndent: endExtraIndent,
      align: align,
      alignIfNotFit: alignIfNotFit,
      moveIfVisible: moveIfVisible,
      allowMovementOutside: allowMovementOutside,
      duration: duration,
      curve: curve,
    );
  }

  /// Показать детей с [first] по [last].
  ///
  /// {@see showArea}.
  ///
  // ignore: long-method
  void showChildren(
    int first,
    int last, {
    double? startExtraIndent,
    double? endExtraIndent,
    ScrollAxisAlign? align,
    ScrollAxisAlign? alignIfNotFit,
    bool? moveIfVisible,
    bool? allowMovementOutside,
    Duration? duration,
    Curve? curve,
  }) {
    final scroll = position;

    // Ищем RenderFlex, рассчитываем padding.
    final r = _findRenderFlex();
    final renderFlex = r.renderObject;

    // Ищем нужных детей.
    final firstChild = childByIndex(renderFlex, first);
    if (firstChild == null) {
      throw IndexError.withLength(
        first,
        renderFlex.childCount,
        indexable: renderFlex,
      );
    }

    final lastChild =
        first == last ? firstChild : childByIndex(renderFlex, last);
    if (lastChild == null) {
      throw IndexError.withLength(
        last,
        renderFlex.childCount,
        indexable: renderFlex,
      );
    }

    final firstStart = axisOffset(
      scroll.axis,
      (firstChild.parentData! as ContainerBoxParentData<RenderBox>).offset,
    );
    final lastStart = first == last
        ? firstStart
        : axisOffset(
            scroll.axis,
            (lastChild.parentData! as ContainerBoxParentData<RenderBox>).offset,
          );
    final lastSize = axisSize(scroll.axis, lastChild.size);

    _showArea(
      start: firstStart,
      size: lastStart + lastSize - firstStart,
      padding: r.padding,
      startExtraIndent: startExtraIndent,
      endExtraIndent: endExtraIndent,
      align: align,
      alignIfNotFit: alignIfNotFit,
      moveIfVisible: moveIfVisible,
      allowMovementOutside: allowMovementOutside,
      duration: duration,
      curve: curve,
    );
  }
}
