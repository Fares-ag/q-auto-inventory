# Flutter Best Practices - Always Follow

## Core Principles

### 1. Resource Management
- ✅ **Always dispose controllers**: `TextEditingController`, `FocusNode`, `AnimationController`, `Timer`, `StreamSubscription`
- ✅ **Use `context.mounted`** before any async operations that use `context`
- ✅ **Dispose in `finally` blocks** or when widgets are disposed

### 2. Type Safety
- ✅ **Use proper function types**: `ValueChanged<T>`, `VoidCallback`, `Future<void> Function()` instead of `Function`
- ✅ **Avoid `dynamic`** - use proper types or generics
- ✅ **Use null safety** properly - avoid unnecessary `!` operators

### 3. Performance
- ✅ **Use `const` constructors** wherever possible
- ✅ **Memoize expensive computations** - don't recalculate in `build()` if data hasn't changed
- ✅ **Use `const` for static values** (colors, strings, lists that don't change)
- ✅ **Optimize lookups** - use Maps for O(1) access instead of O(n) `firstWhere`
- ✅ **Avoid unnecessary rebuilds** - use `const` widgets, `RepaintBoundary`, `ValueListenableBuilder`

### 4. Error Handling
- ✅ **Always check `context.mounted`** before using `context` after async operations
- ✅ **Use try-catch-finally** for proper cleanup
- ✅ **Log errors** with `debugPrint` for debugging
- ✅ **Provide user-friendly error messages**

### 5. Code Organization
- ✅ **Separate concerns** - widgets, services, models in separate files
- ✅ **Use private members** (`_private`) for internal state
- ✅ **Follow naming conventions** - `PascalCase` for classes, `camelCase` for variables
- ✅ **Keep widgets small** - extract complex widgets into separate classes

### 6. State Management
- ✅ **Use appropriate state management** - Provider, Riverpod, Bloc, etc.
- ✅ **Minimize state** - only store what's necessary
- ✅ **Use `setState` sparingly** - prefer immutable state updates

### 7. Platform Compatibility
- ✅ **Use platform-agnostic APIs** - `Platform.pathSeparator` instead of `/` or `\`
- ✅ **Check platform** with `kIsWeb`, `Platform.isAndroid`, etc. when needed
- ✅ **Test on multiple platforms**

### 8. Widget Best Practices
- ✅ **Use `const` widgets** when possible
- ✅ **Extract reusable widgets** into separate classes
- ✅ **Use `Builder` or `StatefulBuilder`** when local state is needed in dialogs
- ✅ **Prefer composition over inheritance**

### 9. Async Operations
- ✅ **Always check `context.mounted`** after `await`
- ✅ **Handle loading states** properly
- ✅ **Cancel operations** when widget is disposed (if applicable)
- ✅ **Use `FutureBuilder` or `StreamBuilder`** appropriately

### 10. Memory Management
- ✅ **Dispose all resources** in `dispose()` method
- ✅ **Cancel subscriptions** and timers
- ✅ **Clear listeners** from controllers
- ✅ **Avoid memory leaks** - don't hold references to disposed widgets

## Checklist for Every Code Change

Before submitting any code, verify:

- [ ] All controllers are disposed
- [ ] `context.mounted` checks are in place for async operations
- [ ] `const` constructors used where possible
- [ ] Proper error handling with try-catch-finally
- [ ] Type safety - no `Function` or unnecessary `dynamic`
- [ ] Performance optimizations applied
- [ ] Cross-platform compatibility considered
- [ ] Code is properly organized and readable
- [ ] No memory leaks
- [ ] Error logging in place

## Examples

### ✅ Good
```dart
class MyWidget extends StatefulWidget {
  const MyWidget({super.key});
  
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final _controller = TextEditingController();
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  Future<void> _doSomething() async {
    await someAsyncOperation();
    if (!context.mounted) return;
    // Use context safely
  }
}
```

### ❌ Bad
```dart
class MyWidget extends StatefulWidget {
  MyWidget(); // Missing const, missing super.key
  
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final _controller = TextEditingController();
  // Missing dispose()
  
  Future<void> _doSomething() async {
    await someAsyncOperation();
    ScaffoldMessenger.of(context).showSnackBar(...); // No context.mounted check!
  }
}
```

---

**Remember**: Always follow these practices in every code change. Quality over speed!

