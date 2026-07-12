import 'package:flutter_test/flutter_test.dart';
import 'package:q_auto_inventory/utils/date_formatter.dart';

void main() {
  group('DateFormatter', () {
    test('formatDate returns formatted date', () {
      final date = DateTime(2025, 3, 15);
      expect(DateFormatter.formatDate(date), 'Mar 15, 2025');
    });

    test('formatDate returns Not set for null', () {
      expect(DateFormatter.formatDate(null), 'Not set');
    });

    test('formatDateShort returns MM/dd/yyyy format', () {
      final date = DateTime(2025, 1, 5);
      expect(DateFormatter.formatDateShort(date), '01/05/2025');
    });

    test('formatDateShort returns N/A for null', () {
      expect(DateFormatter.formatDateShort(null), 'N/A');
    });

    test('formatDateTime returns Not set for null', () {
      expect(DateFormatter.formatDateTime(null), 'Not set');
    });

    test('formatDateTime includes time', () {
      final date = DateTime(2025, 6, 20, 14, 30);
      final result = DateFormatter.formatDateTime(date);
      expect(result, contains('Jun 20, 2025'));
      expect(result, contains('02:30 PM'));
    });

    test('formatTime returns empty for null', () {
      expect(DateFormatter.formatTime(null), '');
    });

    test('formatRelative returns Not set for null', () {
      expect(DateFormatter.formatRelative(null), 'Not set');
    });

    test('formatRelative returns Just now for recent times', () {
      final now = DateTime.now();
      expect(DateFormatter.formatRelative(now), 'Just now');
    });

    test('formatRelative returns minutes ago', () {
      final fiveMinAgo = DateTime.now().subtract(const Duration(minutes: 5));
      expect(DateFormatter.formatRelative(fiveMinAgo), '5 minutes ago');
    });

    test('formatRelative returns singular minute', () {
      final oneMinAgo = DateTime.now().subtract(const Duration(minutes: 1));
      expect(DateFormatter.formatRelative(oneMinAgo), '1 minute ago');
    });

    test('formatRelative returns hours ago', () {
      final threeHoursAgo = DateTime.now().subtract(const Duration(hours: 3));
      expect(DateFormatter.formatRelative(threeHoursAgo), '3 hours ago');
    });

    test('formatRelative returns singular hour', () {
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      expect(DateFormatter.formatRelative(oneHourAgo), '1 hour ago');
    });

    test('formatRelative returns Yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(DateFormatter.formatRelative(yesterday), 'Yesterday');
    });

    test('formatRelative returns days ago for recent past', () {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      expect(DateFormatter.formatRelative(threeDaysAgo), '3 days ago');
    });

    test('formatRelative returns formatted date for older than a week', () {
      final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));
      final result = DateFormatter.formatRelative(twoWeeksAgo);
      expect(result, isNot('Not set'));
      expect(result, isNot(contains('ago')));
    });
  });
}
