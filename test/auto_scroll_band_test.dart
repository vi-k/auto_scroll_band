import 'package:auto_scroll_band/auto_scroll_band.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScrollAxisAlign', () {
    test('constants have expected values and relationships', () {
      expect(ScrollAxisAlign.nearest.value.isNaN, isTrue);

      expect(ScrollAxisAlign.start.value, 0);
      expect(ScrollAxisAlign.center.value, 0.5);
      expect(ScrollAxisAlign.end.value, 1);
    });

    test('isExactAlign returns true for finite values and false for NaN', () {
      expect(ScrollAxisAlign.start.isExactAlign, isTrue);
      expect(ScrollAxisAlign.center.isExactAlign, isTrue);
      expect(ScrollAxisAlign.end.isExactAlign, isTrue);
      expect(const ScrollAxisAlign(0.25).isExactAlign, isTrue);
      expect(const ScrollAxisAlign(0.8).isExactAlign, isTrue);

      // Counter-checks: non-finite alignment must not report exact alignment
      expect(ScrollAxisAlign.nearest.isExactAlign, isFalse);
      expect(ScrollAxisAlign.nearest.reverse.isExactAlign, isFalse);
    });

    test('reverse mirrors finite alignments and preserves NaN for nearest', () {
      final reversedStart = ScrollAxisAlign.start.reverse;
      expect(reversedStart.value, 1);
      expect(reversedStart.isExactAlign, isTrue);

      final reversedEnd = ScrollAxisAlign.end.reverse;
      expect(reversedEnd.value, 0);
      expect(reversedEnd.isExactAlign, isTrue);

      final reversedCenter = ScrollAxisAlign.center.reverse;
      expect(reversedCenter.value, 0.5);
      expect(reversedCenter.isExactAlign, isTrue);

      const custom = ScrollAxisAlign(0.2);
      final reversedCustom = custom.reverse;
      expect(reversedCustom.value, closeTo(0.8, 1e-9));
      expect(reversedCustom.reverse.value, closeTo(0.2, 1e-9));

      final reversedNearest = ScrollAxisAlign.nearest.reverse;
      expect(reversedNearest.value.isNaN, isTrue);
      expect(reversedNearest.isExactAlign, isFalse);
    });

    test('constructor assert enforces value range [0, 1]', () {
      // Valid boundary and intermediate values must return normally
      expect(() => const ScrollAxisAlign(0), returnsNormally);
      expect(() => const ScrollAxisAlign(1), returnsNormally);
      expect(() => const ScrollAxisAlign(0.5), returnsNormally);
      expect(() => const ScrollAxisAlign(0.001), returnsNormally);
      expect(() => const ScrollAxisAlign(0.999), returnsNormally);

      // Counter-checks: out-of-range or non-finite values must throw AssertionError
      expect(() => ScrollAxisAlign(-0.001), throwsAssertionError);
      expect(() => ScrollAxisAlign(-1), throwsAssertionError);
      expect(() => ScrollAxisAlign(1.001), throwsAssertionError);
      expect(() => ScrollAxisAlign(2), throwsAssertionError);
      expect(() => ScrollAxisAlign(double.nan), throwsAssertionError);
      expect(() => ScrollAxisAlign(double.infinity), throwsAssertionError);
      expect(() => ScrollAxisAlign(-double.infinity), throwsAssertionError);
    });
  });

  group('ScrollBandController static methods', () {
    test('axisOffset extracts coordinate along specified axis', () {
      const offset = Offset(15.5, 42);

      expect(ScrollBandController.axisOffset(Axis.horizontal, offset), 15.5);
      expect(ScrollBandController.axisOffset(Axis.vertical, offset), 42);
      const negativeOffset = Offset(-10, 25);
      expect(ScrollBandController.axisOffset(Axis.horizontal, negativeOffset),
          -10);
      expect(
          ScrollBandController.axisOffset(Axis.vertical, negativeOffset), 25);

      expect(ScrollBandController.axisOffset(Axis.horizontal, Offset.zero), 0);
      expect(ScrollBandController.axisOffset(Axis.vertical, Offset.zero), 0);
    });

    test('axisSize extracts dimension along specified axis', () {
      const size = Size(120, 340);

      expect(ScrollBandController.axisSize(Axis.horizontal, size), 120);
      expect(ScrollBandController.axisSize(Axis.vertical, size), 340);
      expect(ScrollBandController.axisSize(Axis.horizontal, Size.zero), 0);
      expect(ScrollBandController.axisSize(Axis.vertical, Size.zero), 0);
    });

    test('axisTotalPadding calculates sum along specified axis', () {
      const padding = EdgeInsets.fromLTRB(10, 20, 30, 50);

      // Horizontal padding is left + right = 10 + 30 = 40
      expect(
          ScrollBandController.axisTotalPadding(Axis.horizontal, padding), 40);
      // Vertical padding is top + bottom = 20 + 50 = 70
      expect(ScrollBandController.axisTotalPadding(Axis.vertical, padding), 70);
      const directionalPadding = EdgeInsetsDirectional.fromSTEB(5, 12, 15, 28);
      expect(
          ScrollBandController.axisTotalPadding(
              Axis.horizontal, directionalPadding),
          20);
      expect(
          ScrollBandController.axisTotalPadding(
              Axis.vertical, directionalPadding),
          40);

      const asymmetricPadding = EdgeInsets.only(left: 18);
      expect(
          ScrollBandController.axisTotalPadding(
              Axis.horizontal, asymmetricPadding),
          18);
      expect(
          ScrollBandController.axisTotalPadding(
              Axis.vertical, asymmetricPadding),
          0);

      expect(
          ScrollBandController.axisTotalPadding(
              Axis.horizontal, EdgeInsets.zero),
          0);
      expect(
          ScrollBandController.axisTotalPadding(Axis.vertical, EdgeInsets.zero),
          0);
    });

    testWidgets('childByIndex returns correct child by zero-based index',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              SizedBox(key: Key('child_0'), width: 10, height: 10),
              SizedBox(key: Key('child_1'), width: 20, height: 20),
              SizedBox(key: Key('child_2'), width: 30, height: 30),
            ],
          ),
        ),
      );

      final renderFlex = tester.renderObject<RenderFlex>(find.byType(Row));
      final expectedChild0 =
          tester.renderObject<RenderBox>(find.byKey(const Key('child_0')));
      final expectedChild1 =
          tester.renderObject<RenderBox>(find.byKey(const Key('child_1')));
      final expectedChild2 =
          tester.renderObject<RenderBox>(find.byKey(const Key('child_2')));

      final child0 = ScrollBandController.childByIndex(renderFlex, 0);
      final child1 = ScrollBandController.childByIndex(renderFlex, 1);
      final child2 = ScrollBandController.childByIndex(renderFlex, 2);

      expect(child0, equals(expectedChild0));
      expect(child1, equals(expectedChild1));
      expect(child2, equals(expectedChild2));

      // Out-of-bounds indices must return null
      expect(ScrollBandController.childByIndex(renderFlex, 3), isNull);
      expect(ScrollBandController.childByIndex(renderFlex, 10), isNull);

      // Negative index returns firstChild because the loop condition `0 < index` is false
      final childNegative = ScrollBandController.childByIndex(renderFlex, -1);
      expect(childNegative, equals(expectedChild0));
    });

    testWidgets(
        'childByIndex returns null for any index when RenderFlex has no children',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Row(children: []),
        ),
      );

      final renderFlex = tester.renderObject<RenderFlex>(find.byType(Row));
      expect(ScrollBandController.childByIndex(renderFlex, 0), isNull);
      expect(ScrollBandController.childByIndex(renderFlex, 1), isNull);
      expect(ScrollBandController.childByIndex(renderFlex, -1), isNull);
    });
  });

  group('SeparatedFlex, SeparatedRow, SeparatedColumn', () {
    test('constructor assert rejects providing both spacing and separator', () {
      expect(
        () => SeparatedFlex(
          direction: Axis.horizontal,
          spacing: 8,
          separator: const SizedBox(),
          children: const [],
        ),
        throwsAssertionError,
      );

      // Counter-checks: providing only spacing, only separator, or neither must succeed
      expect(
        () => const SeparatedFlex(
          direction: Axis.horizontal,
          spacing: 8,
          children: [],
        ),
        returnsNormally,
      );
      expect(
        () => const SeparatedFlex(
          direction: Axis.horizontal,
          separator: SizedBox(),
          children: [],
        ),
        returnsNormally,
      );
      expect(
        () => const SeparatedFlex(
          direction: Axis.horizontal,
          children: [],
        ),
        returnsNormally,
      );
    });

    testWidgets('custom separator is inserted strictly between children',
        (tester) async {
      const sep = SizedBox(width: 10, height: 10);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SeparatedFlex(
            direction: Axis.horizontal,
            separator: sep,
            children: [
              SizedBox(key: Key('item_0')),
              SizedBox(key: Key('item_1')),
              SizedBox(key: Key('item_2')),
            ],
          ),
        ),
      );

      final flex = tester.widget<Flex>(find.byType(Flex));
      // 3 children + 2 separators = 5 widgets
      expect(flex.children.length, 5);
      expect(flex.children[0].key, const Key('item_0'));
      expect(identical(flex.children[1], sep), isTrue);
      expect(flex.children[2].key, const Key('item_1'));
      expect(identical(flex.children[3], sep), isTrue);
      expect(flex.children[4].key, const Key('item_2'));
    });

    testWidgets(
        'SeparatedRow with spacing creates SizedBox separators with width',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SeparatedRow(
            spacing: 14,
            children: [
              SizedBox(key: Key('item_0')),
              SizedBox(key: Key('item_1')),
            ],
          ),
        ),
      );

      final flex = tester.widget<Flex>(find.byType(Flex));
      expect(flex.direction, Axis.horizontal);
      expect(flex.children.length, 3);
      expect(flex.children[0].key, const Key('item_0'));
      expect(flex.children[2].key, const Key('item_1'));

      expect(flex.children[1], isA<SizedBox>());
      final separator = flex.children[1] as SizedBox;
      expect(separator.width, 14);
      expect(separator.height, isNull);
    });

    testWidgets(
        'SeparatedColumn with spacing creates SizedBox separators with height',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SeparatedColumn(
            spacing: 22,
            children: [
              SizedBox(key: Key('item_0')),
              SizedBox(key: Key('item_1')),
            ],
          ),
        ),
      );

      final flex = tester.widget<Flex>(find.byType(Flex));
      expect(flex.direction, Axis.vertical);
      expect(flex.children.length, 3);
      expect(flex.children[0].key, const Key('item_0'));
      expect(flex.children[2].key, const Key('item_1'));

      expect(flex.children[1], isA<SizedBox>());
      final separator = flex.children[1] as SizedBox;
      expect(separator.height, 22);
      expect(separator.width, isNull);
    });

    testWidgets('null spacing and separator leaves children list unmodified',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SeparatedFlex(
            direction: Axis.horizontal,
            children: [
              SizedBox(key: Key('item_0')),
              SizedBox(key: Key('item_1')),
            ],
          ),
        ),
      );

      final flex = tester.widget<Flex>(find.byType(Flex));
      expect(flex.children.length, 2);
      expect(flex.children[0].key, const Key('item_0'));
      expect(flex.children[1].key, const Key('item_1'));
    });

    testWidgets(
        'empty children list produces empty Flex children even with separator or spacing',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SeparatedRow(
            spacing: 10,
            children: [],
          ),
        ),
      );
      final flexWithSpacing = tester.widget<Flex>(find.byType(Flex));
      expect(flexWithSpacing.children, isEmpty);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SeparatedRow(
            separator: SizedBox(width: 10),
            children: [],
          ),
        ),
      );
      final flexWithSeparator = tester.widget<Flex>(find.byType(Flex));
      expect(flexWithSeparator.children, isEmpty);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SeparatedRow(
            children: [],
          ),
        ),
      );
      final flexEmpty = tester.widget<Flex>(find.byType(Flex));
      expect(flexEmpty.children, isEmpty);
    });

    testWidgets(
        'single child list produces single Flex child without separators',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SeparatedRow(
            spacing: 10,
            children: [
              SizedBox(key: Key('only_child')),
            ],
          ),
        ),
      );
      final flexWithSpacing = tester.widget<Flex>(find.byType(Flex));
      expect(flexWithSpacing.children.length, 1);
      expect(flexWithSpacing.children.first.key, const Key('only_child'));

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SeparatedColumn(
            separator: SizedBox(height: 10),
            children: [
              SizedBox(key: Key('only_child')),
            ],
          ),
        ),
      );
      final flexWithSeparator = tester.widget<Flex>(find.byType(Flex));
      expect(flexWithSeparator.children.length, 1);
      expect(flexWithSeparator.children.first.key, const Key('only_child'));

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SeparatedRow(
            children: [
              SizedBox(key: Key('only_child')),
            ],
          ),
        ),
      );
      final flexWithoutSeparator = tester.widget<Flex>(find.byType(Flex));
      expect(flexWithoutSeparator.children.length, 1);
      expect(flexWithoutSeparator.children.first.key, const Key('only_child'));
    });

    testWidgets('SeparatedRow and SeparatedColumn set correct directions',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SeparatedRow(children: []),
        ),
      );
      final rowFlex = tester.widget<Flex>(find.byType(Flex));
      expect(rowFlex.direction, Axis.horizontal);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SeparatedColumn(children: []),
        ),
      );
      final columnFlex = tester.widget<Flex>(find.byType(Flex));
      expect(columnFlex.direction, Axis.vertical);
    });

    testWidgets('SeparatedFlex forwards default configuration to nested Flex',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SeparatedFlex(
            direction: Axis.horizontal,
            children: [],
          ),
        ),
      );

      final flex = tester.widget<Flex>(find.byType(Flex));
      expect(flex.direction, Axis.horizontal);
      expect(flex.mainAxisAlignment, MainAxisAlignment.start);
      expect(flex.mainAxisSize, MainAxisSize.min);
      expect(flex.crossAxisAlignment, CrossAxisAlignment.center);
      expect(flex.verticalDirection, VerticalDirection.down);
      expect(flex.clipBehavior, Clip.none);
      expect(flex.textDirection, isNull);
      expect(flex.textBaseline, isNull);
    });

    testWidgets('SeparatedFlex forwards custom properties to nested Flex',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SeparatedFlex(
            direction: Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            textDirection: TextDirection.rtl,
            verticalDirection: VerticalDirection.up,
            textBaseline: TextBaseline.alphabetic,
            clipBehavior: Clip.antiAlias,
            children: [],
          ),
        ),
      );

      final flex = tester.widget<Flex>(find.byType(Flex));
      expect(flex.direction, Axis.vertical);
      expect(flex.mainAxisAlignment, MainAxisAlignment.spaceBetween);
      expect(flex.mainAxisSize, MainAxisSize.max);
      expect(flex.crossAxisAlignment, CrossAxisAlignment.stretch);
      expect(flex.textDirection, TextDirection.rtl);
      expect(flex.verticalDirection, VerticalDirection.up);
      expect(flex.textBaseline, TextBaseline.alphabetic);
      expect(flex.clipBehavior, Clip.antiAlias);
    });
  });
}
