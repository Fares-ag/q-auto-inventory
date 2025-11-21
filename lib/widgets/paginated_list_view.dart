import 'package:flutter/material.dart';

/// A paginated list view that loads items in batches
class PaginatedListView<T> extends StatefulWidget {
  const PaginatedListView({
    super.key,
    required this.itemBuilder,
    required this.loadItems,
    this.pageSize = 20,
    this.emptyWidget,
    this.loadingWidget,
    this.errorWidget,
    this.onError,
  });

  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Future<List<T>> Function(int page, int pageSize) loadItems;
  final int pageSize;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final void Function(Object error)? onError;

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final List<T> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newItems = await widget.loadItems(_currentPage, widget.pageSize);

      if (!mounted) return;

      setState(() {
        _items.addAll(newItems);
        _hasMore = newItems.length == widget.pageSize;
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e;
      });

      widget.onError?.call(e);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _currentPage = 0;
      _hasMore = true;
      _error = null;
    });
    await _loadNextPage();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _items.isEmpty) {
      return widget.errorWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading items: $_error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refresh,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
    }

    if (_items.isEmpty && !_isLoading) {
      return widget.emptyWidget ??
          const Center(
            child: Text('No items found'),
          );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            // Load more trigger
            if (_hasMore && !_isLoading) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadNextPage();
              });
            }
            return widget.loadingWidget ??
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
          }

          return widget.itemBuilder(context, _items[index], index);
        },
      ),
    );
  }
}

