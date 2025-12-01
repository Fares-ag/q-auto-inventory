import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/services/item_service.dart';

/// Provider for managing items state
class ItemProvider extends ChangeNotifier {
  List<ItemModel> _items = [];
  bool _isLoading = false;
  String? _error;

  List<ItemModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ItemProvider() {
    _initializeStream();
  }

  void _initializeStream() {
    ItemService.getItemsStream().listen(
      (items) {
        _items = items;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> updateItem(ItemModel item) async {
    try {
      await ItemService.updateItem(item);
      // Stream will automatically update the list
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await ItemService.deleteItem(itemId);
      // Stream will automatically update the list
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}

