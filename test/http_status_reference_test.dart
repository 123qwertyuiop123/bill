import 'package:bill/tools/http_status_reference/http_status_reference_logic.dart';
import 'package:bill/tools/http_status_reference/http_status_reference_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('finds a status by code and Chinese scenario', () {
    expect(
      searchHttpStatuses('404', HttpStatusGroup.all).single.reason,
      'Not Found',
    );
    expect(searchHttpStatuses('限流', HttpStatusGroup.all).single.code, 429);
  });

  test('filters status classes and handles no result', () {
    final successes = searchHttpStatuses('', HttpStatusGroup.success);
    expect(successes, isNotEmpty);
    expect(successes.every((item) => item.code ~/ 100 == 2), isTrue);
    expect(searchHttpStatuses('不存在的关键词', HttpStatusGroup.all), isEmpty);
  });

  test('rejects an excessive query', () {
    expect(
      () => searchHttpStatuses('a' * 65, HttpStatusGroup.all),
      throwsFormatException,
    );
  });

  testWidgets('renders the selected HTTP status', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HttpStatusReferenceScreen()),
    );

    expect(find.text('404 Not Found'), findsOneWidget);
    expect(find.text('服务器找不到请求的资源。'), findsOneWidget);
    expect(find.text('离线参考，不会发送网络请求'), findsOneWidget);
  });
}
