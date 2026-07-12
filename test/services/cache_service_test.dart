import 'package:flutter_test/flutter_test.dart';
import 'package:q_auto_inventory/services/cache_service.dart';

void main() {
  group('CacheService', () {
    late CacheService cache;

    setUp(() {
      cache = CacheService.instance;
      cache.clear();
    });

    test('set and get stores and retrieves values', () {
      cache.set('key1', 'hello');
      expect(cache.get<String>('key1'), 'hello');
    });

    test('get returns null for missing keys', () {
      expect(cache.get<String>('nonexistent'), isNull);
    });

    test('set overwrites existing value', () {
      cache.set('k', 1);
      cache.set('k', 2);
      expect(cache.get<int>('k'), 2);
    });

    test('remove deletes a key', () {
      cache.set('x', 'value');
      cache.remove('x');
      expect(cache.get<String>('x'), isNull);
    });

    test('clear removes all entries', () {
      cache.set('a', 1);
      cache.set('b', 2);
      cache.clear();
      expect(cache.size, 0);
    });

    test('size reflects number of entries', () {
      cache.set('a', 1);
      cache.set('b', 2);
      cache.set('c', 3);
      expect(cache.size, 3);
    });

    test('stores complex objects', () {
      final list = ['a', 'b', 'c'];
      cache.set('myList', list);
      expect(cache.get<List<String>>('myList'), list);
    });

    test('stores maps', () {
      final map = {'key': 'val', 'num': 42};
      cache.set('myMap', map);
      final retrieved = cache.get<Map<String, dynamic>>('myMap');
      expect(retrieved?['key'], 'val');
      expect(retrieved?['num'], 42);
    });
  });

  group('CacheKeys', () {
    test('items key includes department and category', () {
      expect(CacheKeys.items('dept1', 'cat1'), 'items_dept1_cat1');
    });

    test('items key uses all for null values', () {
      expect(CacheKeys.items(null, null), 'items_all_all');
    });

    test('item key includes id', () {
      expect(CacheKeys.item('abc'), 'item_abc');
    });

    test('static keys are set', () {
      expect(CacheKeys.departments, 'departments');
      expect(CacheKeys.categories, 'categories');
      expect(CacheKeys.staff, 'staff');
    });
  });
}
