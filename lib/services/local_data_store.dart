// lib/services/local_data_store.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/models/issue_model.dart';
import 'package:flutter_application_1/models/history_entry_model.dart';
import 'package:flutter_application_1/models/reminder_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'local_data_store.g.dart';

// --- Data Models for System Management ---

class Department {
  String id;
  String name;
  bool isActive;
  Department({required this.id, required this.name, this.isActive = true});
}

class Category {
  String id;
  String name;
  bool isActive;
  Category({required this.id, required this.name, this.isActive = true});
}

class PermissionSet {
  String id;
  String name;
  Map<String, bool> permissions;
  PermissionSet(
      {required this.id, required this.name, required this.permissions});
  PermissionSet copyWith(
      {String? id, String? name, Map<String, bool>? permissions}) {
    return PermissionSet(
        id: id ?? this.id,
        name: name ?? this.name,
        permissions: permissions ?? this.permissions);
  }
}

@HiveType(typeId: 2)
class LocalUser extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String email;
  @HiveField(2)
  String roleId;
  @HiveField(3)
  bool isActive;
  @HiveField(4)
  final String department;
  @HiveField(5)
  String name;

  LocalUser({
    required this.id,
    required this.name,
    required this.email,
    required this.roleId,
    required this.department,
    this.isActive = true,
  });

  LocalUser copyWith(
      {String? name, String? roleId, bool? isActive, String? department}) {
    return LocalUser(
      id: this.id,
      name: name ?? this.name,
      email: this.email,
      roleId: roleId ?? this.roleId,
      isActive: isActive ?? this.isActive,
      department: department ?? this.department,
    );
  }
}

// --- Central Data Store ---

class LocalDataStore extends ChangeNotifier {
  static final LocalDataStore _instance = LocalDataStore._internal();
  factory LocalDataStore() => _instance;
  LocalDataStore._internal() {
    _initDummyData();
  }

  Future<void> loadItemsFromHive() async {
    var box = Hive.box<ItemModel>('items');
    _items.clear();
    _items.addAll(box.values);
    notifyListeners();
  }

  Future<void> loadUsersFromHive() async {
    var box = Hive.box<LocalUser>('users');
    _users.clear();
    _users.addAll(box.values);
    if (_users.isEmpty) {
      _initDummyUsers();
    } else {
      _currentUser = _users.first;
    }
    notifyListeners();
  }

  final List<ItemModel> _items = [];
  final List<Issue> _issues = [];
  final List<HistoryEntry> _history = [];
  final List<LocalUser> _users = [];
  final List<PermissionSet> _permissionSets = [];
  final List<Department> _departments = [];
  final List<Category> _categories = [];
  final List<Reminder> _reminders = [];
  final List<Comment> _comments = [];

  late LocalUser _currentUser;
  bool _isOnline = true;
  bool _appTheme = true;

  List<ItemModel> get items => _items;
  List<Issue> get issues => _issues;
  List<HistoryEntry> get history => _history;
  List<LocalUser> get users => _users;
  List<PermissionSet> get permissionSets => _permissionSets;
  List<Department> get departments => _departments;
  List<Category> get categories => _categories;
  List<Reminder> get reminders => _reminders;
  List<Comment> get comments => _comments;
  LocalUser get currentUser => _currentUser;
  Map<String, bool> get currentPermissions => _permissionSets
      .firstWhere((set) => set.id == _currentUser.roleId)
      .permissions;
  bool get isOnline => _isOnline;
  bool get appTheme => _appTheme;

  void _initDummyData() {
    _initDummyPermissions();
    _initDummyUsers();
    _initDummyDepartments();
    _initDummyCategories();
    _initDummyItems();
    _initDummyIssuesAndHistory();
    _initDummyRemindersAndComments();
  }

  void addHistoryEntry({
    required String title,
    required String description,
    required IconData icon,
    required String actorEmail,
    required String actorId,
    String? targetId,
    Uint8List? assigneeSignature,
    Uint8List? operatorSignature,
  }) {
    _history.insert(
      0,
      HistoryEntry(
        title: title,
        description: description,
        timestamp: DateTime.now(),
        icon: icon,
        actorId: actorId,
        actorEmail: actorEmail,
        targetId: targetId,
        assigneeSignature: assigneeSignature,
        operatorSignature: operatorSignature,
      ),
    );
  }

  void _initDummyPermissions() {
    _permissionSets.clear();
    _permissionSets.addAll([
      PermissionSet(id: 'superAdmin', name: 'Super Admin', permissions: {
        'canViewFinancials': true,
        'canManageUsers': true,
        'canApproveItems': true,
        'canViewReports': true,
        'canManagePermissions': true,
        'canBulkImport': true,
        'canDeactivateUser': true
      }),
      PermissionSet(id: 'admin', name: 'Admin', permissions: {
        'canViewFinancials': true,
        'canManageUsers': true,
        'canApproveItems': true,
        'canViewReports': true,
        'canManagePermissions': false,
        'canBulkImport': false,
        'canDeactivateUser': true
      }),
      PermissionSet(id: 'operator', name: 'Operator', permissions: {
        'canViewFinancials': false,
        'canManageUsers': false,
        'canApproveItems': false,
        'canViewReports': true,
        'canManagePermissions': false,
        'canBulkImport': false,
        'canDeactivateUser': false
      }),
    ]);
  }

  void _initDummyUsers() {
    _users.clear();
    _users.addAll([
      LocalUser(
          id: '1',
          name: 'Super Admin',
          email: 'super@admin.com',
          roleId: 'superAdmin',
          department: 'Management',
          isActive: true),
      LocalUser(
          id: '2',
          name: 'IT Admin',
          email: 'admin@it.com',
          roleId: 'admin',
          department: 'IT',
          isActive: true),
      LocalUser(
          id: '3',
          name: 'Ops Operator',
          email: 'operator@ops.com',
          roleId: 'operator',
          department: 'Operations',
          isActive: true),
      LocalUser(
          id: '4',
          name: 'Ali Hamad',
          email: 'ali.hamad@company.com',
          roleId: 'operator',
          department: 'IT',
          isActive: true),
      LocalUser(
          id: '5',
          name: 'Fatima Ahmed',
          email: 'fatima.a@company.com',
          roleId: 'operator',
          department: 'Operations',
          isActive: true),
    ]);
    _currentUser = _users.first;
    var box = Hive.box<LocalUser>('users');
    if (box.isEmpty) {
      for (var user in _users) {
        box.put(user.id, user);
      }
    }
  }

  void _initDummyDepartments() {
    _departments.clear();
    _departments.addAll([
      Department(id: 'dept_1', name: 'IT'),
      Department(id: 'dept_2', name: 'Operations'),
      Department(id: 'dept_3', name: 'Marketing'),
      Department(id: 'dept_4', name: 'HR'),
      Department(id: 'dept_5', name: 'Management', isActive: false),
    ]);
  }

  void _initDummyCategories() {
    _categories.clear();
    _categories.addAll([
      Category(id: 'cat_1', name: 'Laptop'),
      Category(id: 'cat_2', name: 'Keyboard'),
      Category(id: 'cat_3', name: 'Furniture'),
      Category(id: 'cat_4', name: 'Monitor', isActive: false),
    ]);
  }

  void _initDummyItems() {
    _items.clear();
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
          isTagged: true,
          isAvailable: false,
          department: "IT",
          assignedStaff: "ali.hamad@company.com",
          purchasePrice: 1500.0,
          currentValue: 1200.0,
          status: 'approved',
          nextMaintenanceDate: DateTime.now().add(const Duration(days: 5)),
          customFields: {
            'Serial Number': 'C02XF0G8JGH8',
            'Warranty Expiration': '2025-08-01'
          }),
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
          status: 'pending'),
      ItemModel(
          id: "21252567",
          name: 'Office Chair',
          category: "Furniture",
          itemType: ItemType.furniture,
          purchaseDate: DateTime(2022, 11, 10),
          variants: "1 Variant",
          supplier: "IKEA",
          company: "Sawa Technologies",
          isTagged: true,
          isAvailable: true,
          department: "Operations",
          purchasePrice: 500.0,
          currentValue: 350.0,
          status: 'approved'),
    ]);
  }

  void _initDummyIssuesAndHistory() {
    _issues.clear();
    _history.clear();
    _issues.add(Issue(
        issueId: "issue_1",
        itemId: "21252565",
        description: "Screen flickering on top left corner.",
        priority: IssuePriority.High,
        status: IssueStatus.Open,
        reporterId: "reporter_1",
        createdAt: DateTime(2023, 9, 1)));
    _history.add(HistoryEntry(
        title: "Item checked out",
        description: "Item 21252565 was checked out by Ali Bin Hamad.",
        timestamp: DateTime.now(),
        icon: Icons.assignment_return,
        actorId: '1',
        actorEmail: 'super@admin.com',
        targetId: '21252565'));
  }

  void _initDummyRemindersAndComments() {
    _reminders.add(Reminder(
      id: 'rem_1',
      itemId: '21252565',
      name: 'Check warranty status',
      dateTime: DateTime.now().add(const Duration(days: 7)),
      repeat: RepeatFrequency.monthly,
    ));
    _comments.add(Comment(
      id: 'com_1',
      itemId: '21252565',
      description: 'Initial setup completed by the IT department.',
      authorEmail: 'admin@it.com',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
    ));
  }

  void addReminder(Reminder newReminder) {
    _reminders.add(newReminder);
    notifyListeners();
  }

  void addComment(Comment newComment) {
    _comments.add(newComment);
    notifyListeners();
  }

  void updateIssueStatus(String issueId, IssueStatus newStatus) {
    final index = _issues.indexWhere((issue) => issue.issueId == issueId);
    if (index != -1) {
      _issues[index].status = newStatus;
      addHistoryEntry(
        title: 'Issue Status Updated',
        description:
            '${_currentUser.email} updated issue $issueId to ${newStatus.name}.',
        icon: Icons.task_alt,
        actorId: _currentUser.id,
        actorEmail: _currentUser.email,
        targetId: _issues[index].itemId,
      );
      notifyListeners();
    }
  }

  void toggleConnectivity() {
    _isOnline = !_isOnline;
    notifyListeners();
  }

  void toggleTheme() {
    _appTheme = !_appTheme;
    notifyListeners();
  }

  void addDepartment(String name) {
    final newDept = Department(
        id: 'dept_${DateTime.now().millisecondsSinceEpoch}', name: name);
    _departments.add(newDept);
    addHistoryEntry(
        title: 'Department Created',
        description: '${_currentUser.email} created department "$name".',
        icon: Icons.add_business_outlined,
        actorId: _currentUser.id,
        actorEmail: _currentUser.email,
        targetId: newDept.id);
    notifyListeners();
  }

  void updateDepartment(String id, String newName, bool isActive) {
    final index = _departments.indexWhere((d) => d.id == id);
    if (index != -1) {
      _departments[index].name = newName;
      _departments[index].isActive = isActive;
      addHistoryEntry(
          title: 'Department Updated',
          description: '${_currentUser.email} updated department "$newName".',
          icon: Icons.edit_outlined,
          actorId: _currentUser.id,
          actorEmail: _currentUser.email,
          targetId: id);
      notifyListeners();
    }
  }

  void addCategory(String name) {
    final newCategory = Category(
        id: 'cat_${DateTime.now().millisecondsSinceEpoch}', name: name);
    _categories.add(newCategory);
    addHistoryEntry(
        title: 'Category Created',
        description: '${_currentUser.email} created category "$name".',
        icon: Icons.category_outlined,
        actorId: _currentUser.id,
        actorEmail: _currentUser.email,
        targetId: newCategory.id);
    notifyListeners();
  }

  void updateCategory(String id, String newName, bool isActive) {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index != -1) {
      _categories[index].name = newName;
      _categories[index].isActive = isActive;
      addHistoryEntry(
          title: 'Category Updated',
          description: '${_currentUser.email} updated category "$newName".',
          icon: Icons.edit_outlined,
          actorId: _currentUser.id,
          actorEmail: _currentUser.email,
          targetId: id);
      notifyListeners();
    }
  }

  void switchUser(LocalUser user) {
    _currentUser = user;
    notifyListeners();
  }

  void addUser(LocalUser newUser) {
    _users.add(newUser);
    var box = Hive.box<LocalUser>('users');
    box.put(newUser.id, newUser);
    addHistoryEntry(
        title: 'User Created',
        description:
            '${_currentUser.email} created a new user: ${newUser.email}.',
        icon: Icons.person_add_alt_1_outlined,
        actorId: _currentUser.id,
        actorEmail: _currentUser.email,
        targetId: newUser.id);
    notifyListeners();
  }

  void addUsersBulk(List<LocalUser> newUsers) {
    _users.addAll(newUsers);
    var box = Hive.box<LocalUser>('users');
    for (var user in newUsers) {
      box.put(user.id, user);
    }
    addHistoryEntry(
        title: 'Bulk User Import',
        description: '${_currentUser.email} imported ${newUsers.length} users.',
        icon: Icons.group_add_outlined,
        actorId: _currentUser.id,
        actorEmail: _currentUser.email);
    notifyListeners();
  }

  void addItemsBulk(List<ItemModel> newItems) {
    _items.addAll(newItems);
    var box = Hive.box<ItemModel>('items');
    for (var item in newItems) {
      box.put(item.id, item);
    }
    addHistoryEntry(
      title: "Bulk Import",
      description: "${_currentUser.email} imported ${newItems.length} items.",
      icon: Icons.upload_file,
      actorId: _currentUser.id,
      actorEmail: _currentUser.email,
    );
    notifyListeners();
  }

  void updateUserRole(String userId, String newRoleId) {
    final userIndex = _users.indexWhere((user) => user.id == userId);
    if (userIndex != -1) {
      final targetUser = _users[userIndex];
      _users[userIndex] = _users[userIndex].copyWith(roleId: newRoleId);
      var box = Hive.box<LocalUser>('users');
      box.put(userId, _users[userIndex]);
      addHistoryEntry(
          title: 'User Role Changed',
          description:
              '${_currentUser.email} changed role for ${targetUser.email} to "$newRoleId".',
          icon: Icons.manage_accounts_outlined,
          actorId: _currentUser.id,
          actorEmail: _currentUser.email,
          targetId: targetUser.id);
      notifyListeners();
    }
  }

  void toggleUserActivation(String userId) {
    final userIndex = _users.indexWhere((user) => user.id == userId);
    if (userIndex != -1) {
      final targetUser = _users[userIndex];
      final newStatus = !targetUser.isActive;
      _users[userIndex] = _users[userIndex].copyWith(isActive: newStatus);
      var box = Hive.box<LocalUser>('users');
      box.put(userId, _users[userIndex]);
      addHistoryEntry(
          title: 'User Status Changed',
          description:
              '${_currentUser.email} set user ${targetUser.email} to ${newStatus ? "Active" : "Inactive"}.',
          icon:
              newStatus ? Icons.toggle_on_outlined : Icons.toggle_off_outlined,
          actorId: _currentUser.id,
          actorEmail: _currentUser.email,
          targetId: targetUser.id);
      notifyListeners();
    }
  }

  void updatePermissionSet(String roleId, Map<String, bool> permissions) {
    final index = _permissionSets.indexWhere((set) => set.id == roleId);
    if (index != -1) {
      _permissionSets[index] =
          _permissionSets[index].copyWith(permissions: permissions);
      addHistoryEntry(
          title: 'Permissions Updated',
          description:
              '${_currentUser.email} updated permissions for the "$roleId" role.',
          icon: Icons.security_outlined,
          actorId: _currentUser.id,
          actorEmail: _currentUser.email,
          targetId: roleId);
      notifyListeners();
    }
  }

  void addItem(ItemModel newItem) {
    _items.add(newItem);
    var box = Hive.box<ItemModel>('items');
    box.put(newItem.id, newItem);
    addHistoryEntry(
        title: "New Item Submitted",
        description:
            "${_currentUser.email} submitted item '${newItem.name}' for approval.",
        icon: Icons.add_box_outlined,
        actorId: _currentUser.id,
        actorEmail: _currentUser.email,
        targetId: newItem.id);
    notifyListeners();
  }

  void updateItem(ItemModel updatedItem) {
    final index = _items.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _items[index] = updatedItem;
      var box = Hive.box<ItemModel>('items');
      box.put(updatedItem.id, updatedItem);
      addHistoryEntry(
          title: "Item Updated",
          description:
              "${_currentUser.email} updated item '${updatedItem.name}'.",
          icon: Icons.update,
          actorId: _currentUser.id,
          actorEmail: _currentUser.email,
          targetId: updatedItem.id);
      notifyListeners();
    }
  }

  void checkoutItem(String itemId, String assignee,
      {Uint8List? assigneeSignature, Uint8List? operatorSignature}) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      final item = _items[index];
      final updatedItem =
          item.copyWith(isAvailable: false, assignedStaff: assignee);
      _items[index] = updatedItem;
      var box = Hive.box<ItemModel>('items');
      box.put(updatedItem.id, updatedItem);
      addHistoryEntry(
          title: "Item Checked Out",
          description:
              "${currentUser.email} checked out '${item.name}' to $assignee.",
          icon: Icons.shopping_cart_checkout_outlined,
          actorId: _currentUser.id,
          actorEmail: _currentUser.email,
          targetId: item.id,
          assigneeSignature: assigneeSignature,
          operatorSignature: operatorSignature);
      notifyListeners();
    }
  }

  void deleteItem(String itemId) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      var removedItem = _items.removeAt(index);
      var box = Hive.box<ItemModel>('items');
      box.delete(itemId);
      addHistoryEntry(
          title: "Item Deleted",
          description:
              "${_currentUser.email} deleted item '${removedItem.name}'.",
          icon: Icons.delete_outline,
          actorId: _currentUser.id,
          actorEmail: _currentUser.email,
          targetId: removedItem.id);
      notifyListeners();
    }
  }

  void checkinItem(String itemId,
      {Uint8List? assigneeSignature, Uint8List? operatorSignature}) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      final item = _items[index];
      final updatedItem = item.copyWith(isAvailable: true, assignedStaff: null);
      _items[index] = updatedItem;
      var box = Hive.box<ItemModel>('items');
      box.put(updatedItem.id, updatedItem);
      addHistoryEntry(
          title: "Item Checked In",
          description: "${currentUser.email} checked in item '${item.name}'.",
          icon: Icons.assignment_return_outlined,
          actorId: _currentUser.id,
          actorEmail: _currentUser.email,
          targetId: item.id,
          assigneeSignature: assigneeSignature,
          operatorSignature: operatorSignature);
      notifyListeners();
    }
  }

  void raiseIssue(Issue newIssue) {
    _issues.add(newIssue);
    addHistoryEntry(
        title: "New Issue Reported",
        description:
            "${_currentUser.email} reported an issue for item ID ${newIssue.itemId}.",
        icon: Icons.report_problem_outlined,
        actorId: _currentUser.id,
        actorEmail: _currentUser.email,
        targetId: newIssue.itemId);
    notifyListeners();
  }

  void approveItem(String itemId) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      final item = _items[index];
      final updatedItem = item.copyWith(status: 'approved', isAvailable: true);
      _items[index] = updatedItem;
      var box = Hive.box<ItemModel>('items');
      box.put(updatedItem.id, updatedItem);
      addHistoryEntry(
          title: "Item Approved",
          description: "${_currentUser.email} approved item '${item.name}'.",
          icon: Icons.check_circle_outline,
          actorId: _currentUser.id,
          actorEmail: _currentUser.email,
          targetId: item.id);
      notifyListeners();
    }
  }

  void rejectItem(String itemId) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      final item = _items[index];
      final updatedItem = item.copyWith(status: 'rejected');
      _items[index] = updatedItem;
      var box = Hive.box<ItemModel>('items');
      box.put(updatedItem.id, updatedItem);
      addHistoryEntry(
          title: "Item Rejected",
          description: "${_currentUser.email} rejected item '${item.name}'.",
          icon: Icons.cancel_outlined,
          actorId: _currentUser.id,
          actorEmail: _currentUser.email,
          targetId: item.id);
      notifyListeners();
    }
  }

  void bulkCheckoutItems(List<String> itemIds, String assignee) {
    var box = Hive.box<ItemModel>('items');
    for (final itemId in itemIds) {
      final itemIndex = _items.indexWhere((i) => i.id == itemId);
      if (itemIndex != -1) {
        final item = _items[itemIndex];
        _items[itemIndex] =
            item.copyWith(isAvailable: false, assignedStaff: assignee);
        box.put(itemId, _items[itemIndex]);
        addHistoryEntry(
          title: "Item Checked Out (Bulk)",
          description:
              "${_currentUser.email} checked out '${item.name}' to $assignee.",
          icon: Icons.inventory_2_outlined,
          actorId: _currentUser.id,
          actorEmail: _currentUser.email,
          targetId: item.id,
        );
      }
    }
    notifyListeners();
  }
}
