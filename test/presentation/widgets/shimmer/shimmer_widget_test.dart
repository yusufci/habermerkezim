import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haber_merkezi/presentation/widgets/shimmer/shimmer_widget.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('ShimmerWidget', () {
    testWidgets('render edilmeli', (tester) async {
      // Arrange & Act
      await pumpApp(
        tester,
        ShimmerWidget(
          child: Container(width: 200, height: 100, color: Colors.white),
        ),
      );

      // Assert
      expect(find.byType(ShimmerWidget), findsOneWidget);
    });

    testWidgets('child widget render edilmeli', (tester) async {
      // Arrange & Act
      await pumpApp(
        tester,
        const ShimmerWidget(
          child: SizedBox(key: Key('shimmer-child'), width: 100, height: 50),
        ),
      );

      // Assert
      expect(find.byKey(const Key('shimmer-child')), findsOneWidget);
    });

    testWidgets('animasyon çalışmalı (pump ile ilerleme)', (tester) async {
      // Arrange & Act
      await pumpApp(
        tester,
        ShimmerWidget(
          duration: const Duration(milliseconds: 500),
          child: Container(width: 100, height: 50, color: Colors.white),
        ),
      );

      // Animasyonu ileri sar
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));

      // Assert - widget hala render edilmeli
      expect(find.byType(ShimmerWidget), findsOneWidget);
    });

    testWidgets('rectangular factory doğru çalışmalı', (tester) async {
      // Act
      await pumpApp(tester, ShimmerWidget.rectangular(width: 200, height: 20));

      // Assert
      expect(find.byType(ShimmerWidget), findsOneWidget);
    });

    testWidgets('circular factory doğru çalışmalı', (tester) async {
      // Act
      await pumpApp(tester, ShimmerWidget.circular(size: 50));

      // Assert
      expect(find.byType(ShimmerWidget), findsOneWidget);
    });

    testWidgets('özel renklerle çalışmalı', (tester) async {
      // Act
      await pumpApp(
        tester,
        ShimmerWidget(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(width: 100, height: 50, color: Colors.white),
        ),
      );

      // Assert
      expect(find.byType(ShimmerWidget), findsOneWidget);
    });

    testWidgets('farklı yönlerle çalışmalı', (tester) async {
      for (final direction in ShimmerDirection.values) {
        await pumpApp(
          tester,
          ShimmerWidget(
            direction: direction,
            child: Container(width: 100, height: 50, color: Colors.white),
          ),
        );

        expect(find.byType(ShimmerWidget), findsOneWidget);
      }
    });
  });

  group('ShimmerDirection', () {
    test('tüm yönler tanımlı olmalı', () {
      expect(ShimmerDirection.values, hasLength(4));
      expect(ShimmerDirection.values, contains(ShimmerDirection.leftToRight));
      expect(ShimmerDirection.values, contains(ShimmerDirection.rightToLeft));
      expect(ShimmerDirection.values, contains(ShimmerDirection.topToBottom));
      expect(ShimmerDirection.values, contains(ShimmerDirection.bottomToTop));
    });
  });
}
