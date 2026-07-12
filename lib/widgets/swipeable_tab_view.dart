import 'package:flutter/material.dart';

/// A horizontally-swipeable tab view that:
///  - Snaps to the page boundary like a typical paginated swipe gesture
///  - Keeps each visited page alive (no rebuild when swiped back to)
///  - Lazily builds tabs as they're visited or peeked-at, so heavy screens
///    aren't constructed on first launch.
///
/// Sync with a [NavigationBar] (or any tab strip) by:
///   1. Holding a [PageController] in the parent widget.
///   2. Calling `controller.jumpToPage(i)` from the bar's onTap callback
///      (jump avoids building intermediate pages on far jumps).
///   3. Updating the bar's selectedIndex from [onPageChanged].
class SwipeableTabView extends StatefulWidget {
  const SwipeableTabView({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.itemBuilder,
    required this.onPageChanged,
    this.physics,
  });

  final PageController controller;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ValueChanged<int> onPageChanged;
  final ScrollPhysics? physics;

  @override
  State<SwipeableTabView> createState() => _SwipeableTabViewState();
}

class _SwipeableTabViewState extends State<SwipeableTabView> {
  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: widget.controller,
      itemCount: widget.itemCount,
      physics: widget.physics,
      onPageChanged: widget.onPageChanged,
      // Each child is wrapped in a keep-alive shell so its State survives
      // swipes off-screen — equivalent semantics to the old IndexedStack.
      itemBuilder: (context, index) {
        return _KeepAliveTab(
          key: ValueKey<int>(index),
          child: widget.itemBuilder(context, index),
        );
      },
    );
  }
}

class _KeepAliveTab extends StatefulWidget {
  const _KeepAliveTab({super.key, required this.child});

  final Widget child;

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
