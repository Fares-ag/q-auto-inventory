// lib/services/local_data_store.dart

// Import Flutter's material library for core UI components and classes like ChangeNotifier and Icons.
import 'package:flutter/material.dart';
// Import the data models used within this data store.
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/models/issue_model.dart';
import 'package:flutter_application_1/models/history_entry_model.dart';

// --- Data Models for User Management ---

/// A data model representing a role or a set of permissions.
class PermissionSet {
  String id; // Unique identifier for the permission set (e.g., 'admin').
  String name; // Display name for the role (e.g., 'Administrator').
  Map<String, bool>
      permissions; // A map of specific permissions to boolean values.

  PermissionSet(
      {required this.id, required this.name, required this.permissions});

  /// Creates a copy of this PermissionSet instance with updated fields.
  PermissionSet copyWith({
    String? id,
    String? name,
    Map<String, bool>? permissions,
  }) {
    return PermissionSet(
      id: id ?? this.id,
      name: name ?? this.name,
      permissions: permissions ?? this.permissions,
    );
  }
}

/// A data model representing a user within the local data store.
class LocalUser {
  final String id; // Unique ID for the user.
  final String email; // User's email address.
  String roleId; // The ID of the PermissionSet assigned to this user.
  bool isActive; // Flag to determine if the user account is active or disabled.

  LocalUser({
    required this.id,
    required this.email,
    required this.roleId,
    this.isActive = true, // User is active by default.
  });

  /// Creates a copy of this LocalUser instance with updated fields.
  LocalUser copyWith({String? roleId, bool? isActive}) {
    return LocalUser(
      id: this.id,
      email: this.email,
      roleId: roleId ?? this.roleId,
      isActive: isActive ?? this.isActive,
    );
  }
}

// --- Central Data Store ---

/// A class that manages the application's state and data locally.
/// It uses the Singleton pattern to ensure only one instance exists.
/// It extends ChangeNotifier to notify widgets when data changes.
class LocalDataStore extends ChangeNotifier {
  // --- Singleton Pattern Implementation ---

  // Private static instance of the class.
  static final LocalDataStore _instance = LocalDataStore._internal();

  // Factory constructor that returns the single instance.
  factory LocalDataStore() {
    return _instance;
  }

  // Private named constructor, called only once to create the instance.
  // It initializes the store with dummy data.
  LocalDataStore._internal() {
    _initDummyData();
  }

  // --- State Properties ---

  // Private lists to hold the application's data.
  final List<ItemModel> _items = [];
  final List<Issue> _issues = [];
  final List<HistoryEntry> _history = [];
  final List<LocalUser> _users = [];
  final List<PermissionSet> _permissionSets = [];

  // State for the currently logged-in user.
  late LocalUser _currentUser;
  // State for simulating network connectivity.
  bool _isOnline = true;
  // State for the application's theme (true = light, false = dark).
  bool _appTheme = true;

  // --- Getters ---
  // Public getters provide read-only access to the private state properties.

  List<ItemModel> get items => _items;
  List<Issue> get issues => _issues;
  List<HistoryEntry> get history => _history;
  List<LocalUser> get users => _users;
  List<PermissionSet> get permissionSets => _permissionSets;
  LocalUser get currentUser => _currentUser;
  // A computed getter that finds and returns the permissions for the current user.
  Map<String, bool> get currentPermissions => _permissionSets
      .firstWhere((set) => set.id == _currentUser.roleId)
      .permissions;
  bool get isOnline => _isOnline;
  bool get appTheme => _appTheme;

  // --- State Mutation Methods ---

  /// Toggles the simulated online/offline status of the app.
  void toggleConnectivity() {
    _isOnline = !_isOnline;
    notifyListeners(); // Notify listening widgets to rebuild.
  }

  /// Toggles the application theme between light and dark.
  void toggleTheme() {
    _appTheme = !_appTheme;
    notifyListeners(); // Notify listening widgets to rebuild.
  }

  /// Initializes the data store with hard-coded dummy data for testing and development.
  void _initDummyData() {
    // Create permission sets for different user roles.
    _permissionSets.addAll([
      PermissionSet(
        id: 'superAdmin',
        name: 'Super Admin',
        permissions: {
          'canViewFinancials': true,
          'canManageUsers': true,
          'canApproveItems': true,
          'canViewReports': true,
          'canManagePermissions': true,
          'canBulkImport': true,
          'canDeactivateUser': true,
        },
      ),
      PermissionSet(
        id: 'admin',
        name: 'Admin',
        permissions: {
          'canViewFinancials': true,
          'canManageUsers': true,
          'canApproveItems': true,
          'canViewReports': true,
          'canManagePermissions': false,
          'canBulkImport': false,
          'canDeactivateUser': true,
        },
      ),
      PermissionSet(
        id: 'operator',
        name: 'Operator',
        permissions: {
          'canViewFinancials': false,
          'canManageUsers': false,
          'canApproveItems': false,
          'canViewReports': true,
          'canManagePermissions': false,
          'canBulkImport': false,
          'canDeactivateUser': false,
        },
      ),
    ]);

    // Create a list of dummy users.
    _users.addAll([
      LocalUser(
          id: '1',
          email: 'super@admin.com',
          roleId: 'superAdmin',
          isActive: true),
      LocalUser(
          id: '2', email: 'admin@it.com', roleId: 'admin', isActive: true),
      LocalUser(
          id: '3',
          email: 'operator@ops.com',
          roleId: 'operator',
          isActive: false),
    ]);

    // Set the initial current user.
    _currentUser = _users.first;

    // Create a list of dummy inventory items.
    _items.addAll([
      ItemModel(
        id: "21252565",
        name: 'Macbook Pro 13"',
        category: "Laptop",
        itemType: ItemType.laptop,
        purchaseDate: DateTime(2023, 8, 1),
        variants: "2 Variants",
        supplier: "Apple Store",
        company: "Sawa Technologies",
        qrCodeId: "qr_12345",
        isTagged: true,
        isAvailable: false,
        department: "IT",
        assignedStaff: "Ali Bin Hamad",
        purchasePrice: 1500.0,
        currentValue: 1200.0,
        status: 'approved',
      ),
      ItemModel(
        id: "21252566",
        name: "Mechanical Keyboard",
        category: "Keyboard",
        itemType: ItemType.keyboard,
        purchaseDate: DateTime(2023, 7, 31),
        variants: "1 Variant",
        supplier: "PC Parts Co.",
        company: "Sawa Technologies",
        isTagged: false,
        isAvailable: true,
        department: "IT",
        purchasePrice: 150.0,
        currentValue: 130.0,
        status: 'pending',
      ),
      ItemModel(
        id: "21252567",
        name: 'Office Chair',
        category: "Furniture",
        itemType: ItemType.furniture,
        purchaseDate: DateTime(2022, 11, 10),
        variants: "1 Variant",
        supplier: "IKEA",
        company: "Sawa Technologies",
        qrCodeId: "qr_67890",
        isTagged: true,
        isAvailable: true,
        department: "Operations",
        purchasePrice: 500.0,
        currentValue: 350.0,
        status: 'approved',
      ),
    ]);

    // Create a dummy issue.
    _issues.add(
      Issue(
        issueId: "issue_1",
        itemId: "21252565",
        description: "Screen flickering on top left corner.",
        priority: IssuePriority.High,
        status: IssueStatus.Open,
        reporterId: "reporter_1",
        createdAt: DateTime(2023, 9, 1),
      ),
    );

    // Create dummy history entries.
    _history.add(HistoryEntry(
      title: "Item checked out",
      description: "Item 21252565 was checked out by Ali Bin Hamad.",
      timestamp: DateTime.now(),
      icon: Icons.assignment_return,
    ));
    _history.add(HistoryEntry(
      title: "New Item Submitted",
      description: "Item 21252566 was submitted for approval.",
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      icon: Icons.add_box_outlined,
    ));
  }

  // --- Public Methods for State Manipulation ---

  /// Switches the currently active user.
  void switchUser(LocalUser user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Adds a single new user to the user list.
  void addUser(LocalUser newUser) {
    _users.add(newUser);
    notifyListeners();
  }

  /// Adds a list of users in bulk.
  void addUsersBulk(List<LocalUser> newUsers) {
    _users.addAll(newUsers);
    notifyListeners();
  }

  /// Adds a list of items in bulk and creates a history entry.
  void addItemsBulk(List<ItemModel> newItems) {
    _items.addAll(newItems);
    _history.add(HistoryEntry(
      title: "Bulk Import",
      description: "${newItems.length} items were imported.",
      timestamp: DateTime.now(),
      icon: Icons.upload_file,
    ));
    notifyListeners();
  }

  /// Updates the role (permission set) of a specific user.
  void updateUserRole(String userId, String newRoleId) {
    final userIndex = _users.indexWhere((user) => user.id == userId);
    if (userIndex != -1) {
      // Use copyWith for an immutable update.
      _users[userIndex] = _users[userIndex].copyWith(roleId: newRoleId);
      notifyListeners();
    }
  }

  /// Toggles a user's active status between true and false.
  void toggleUserActivation(String userId) {
    final userIndex = _users.indexWhere((user) => user.id == userId);
    if (userIndex != -1) {
      _users[userIndex] =
          _users[userIndex].copyWith(isActive: !_users[userIndex].isActive);
      notifyListeners();
    }
  }

  /// Updates the permissions map for a specific role/PermissionSet.
  void updatePermissionSet(String roleId, Map<String, bool> permissions) {
    final index = _permissionSets.indexWhere((set) => set.id == roleId);
    if (index != -1) {
      _permissionSets[index] =
          _permissionSets[index].copyWith(permissions: permissions);
      notifyListeners();
    }
  }

  /// Adds a single new item and creates a history entry.
  void addItem(ItemModel newItem) {
    _items.add(newItem);
    _history.add(HistoryEntry(
      title: "New Item Submitted",
      description: "Item ${newItem.name} was submitted for approval.",
      timestamp: DateTime.now(),
      icon: Icons.add_box_outlined,
    ));
    notifyListeners();
  }

  /// Updates an existing item and creates a history entry.
  void updateItem(ItemModel updatedItem) {
    final index = _items.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _items[index] = updatedItem;
      _history.add(HistoryEntry(
        title: "Item Updated",
        description: "Item ${updatedItem.name} was updated.",
        timestamp: DateTime.now(),
        icon: Icons.update,
      ));
      notifyListeners();
    }
  }

  /// Marks an item as checked out to an assignee and creates a history entry.
  void checkoutItem(String itemId, String assignee) {
    final item = _items.firstWhere((i) => i.id == itemId);
    updateItem(item.copyWith(isAvailable: false, assignedStaff: assignee));
    _history.add(HistoryEntry(
      title: "Item Checked Out",
      description: "Item ${item.name} was checked out by $assignee.",
      timestamp: DateTime.now(),
      icon: Icons.shopping_cart_checkout_outlined,
    ));
    notifyListeners();
  }

  /// Marks an item as checked in (available) and creates a history entry.
  void checkinItem(String itemId) {
    final item = _items.firstWhere((i) => i.id == itemId);
    updateItem(item.copyWith(isAvailable: true, assignedStaff: null));
    _history.add(HistoryEntry(
      title: "Item Checked In",
      description: "Item ${item.name} was checked in.",
      timestamp: DateTime.now(),
      icon: Icons.assignment_return_outlined,
    ));
    notifyListeners();
  }

  /// Adds a new issue to the issues list and creates a history entry.
  void raiseIssue(Issue newIssue) {
    _issues.add(newIssue);
    _history.add(HistoryEntry(
      title: "New Issue Reported",
      description: "Issue ${newIssue.issueId} was reported.",
      timestamp: DateTime.now(),
      icon: Icons.report_problem_outlined,
    ));
    notifyListeners();
  }

  /// Approves a pending item and creates a history entry.
  void approveItem(String itemId) {
    final item = _items.firstWhere((i) => i.id == itemId);
    updateItem(item.copyWith(status: 'approved', isAvailable: true));
    _history.add(HistoryEntry(
      title: "Item Approved",
      description: "Item ${item.name} was approved.",
      timestamp: DateTime.now(),
      icon: Icons.check_circle_outline,
    ));
    notifyListeners();
  }

  /// Rejects a pending item and creates a history entry.
  void rejectItem(String itemId) {
    final item = _items.firstWhere((i) => i.id == itemId);
    updateItem(item.copyWith(status: 'rejected'));
    _history.add(HistoryEntry(
      title: "Item Rejected",
      description: "Item ${item.name} was rejected.",
      timestamp: DateTime.now(),
      icon: Icons.cancel_outlined,
    ));
    notifyListeners();
  }
}
