import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/models/history_entry_model.dart';
import 'package:flutter_application_1/models/issue_model.dart';
import 'package:flutter_application_1/services/item_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/services/firebase_service.dart';

/// Provider for managing app-wide state including items, history, and issues
class AppStateProvider extends ChangeNotifier {
  List<ItemModel> _items = [];
  List<HistoryEntry> _allHistory = [];
  List<Issue> _allIssues = [];
  bool _isLoading = false;
  String? _error;

  List<ItemModel> get items => _items;
  List<HistoryEntry> get allHistory => _allHistory;
  List<Issue> get allIssues => _allIssues;
  List<Issue> get openIssues => _allIssues.where((issue) => 
    issue.status == 'Open' || issue.status == 'In Progress').toList();
  List<HistoryEntry> get recentHistory => _allHistory
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  bool get isLoading => _isLoading;
  String? get error => _error;

  AppStateProvider() {
    _initializeStreams();
  }

  void _initializeStreams() {
    // Listen to items stream
    ItemService.getItemsStream().listen(
      (items) {
        _items = items;
        notifyListeners();
        // When items change, update history and issues
        _loadAllHistory();
        _loadAllIssues();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  /// Load all history entries from all items
  /// Optimized: Loads only recent entries (last 100) for better performance
  Future<void> _loadAllHistory() async {
    try {
      _isLoading = true;
      notifyListeners();

      final List<HistoryEntry> allHistoryEntries = [];
      
      // Get all items first
      final itemsSnapshot = await FirebaseService.firestore
          .collection('items')
          .get();

      // Use Future.wait for parallel loading
      final futures = itemsSnapshot.docs.map((itemDoc) async {
        final historySnapshot = await FirebaseService.firestore
            .collection('items')
            .doc(itemDoc.id)
            .collection('history')
            .orderBy('timestamp', descending: true)
            .limit(10) // Reduced limit per item for better performance
            .get();

        return historySnapshot.docs.map((historyDoc) {
          final data = historyDoc.data();
          return HistoryEntry(
            title: data['title'] ?? '',
            description: data['description'] ?? '',
            timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            icon: _getIconFromTitle(data['title'] ?? ''),
          );
        }).toList();
      }).toList();

      // Wait for all futures and flatten the results
      final results = await Future.wait(futures);
      for (var historyList in results) {
        allHistoryEntries.addAll(historyList);
      }

      // Sort by timestamp (most recent first) and limit to 100 most recent
      allHistoryEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      _allHistory = allHistoryEntries.take(100).toList();
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load all issues from all items
  /// Optimized: Uses parallel loading for better performance
  Future<void> _loadAllIssues() async {
    try {
      final List<Issue> allIssuesList = [];
      
      // Get all items first
      final itemsSnapshot = await FirebaseService.firestore
          .collection('items')
          .get();

      // Use Future.wait for parallel loading
      final futures = itemsSnapshot.docs.map((itemDoc) async {
        final issuesSnapshot = await FirebaseService.firestore
            .collection('items')
            .doc(itemDoc.id)
            .collection('issues')
            .get();

        return issuesSnapshot.docs.map((issueDoc) {
          final data = issueDoc.data();
          return Issue(
            issueId: issueDoc.id,
            description: data['description'] ?? '',
            priority: data['priority'] ?? 'None',
            status: data['status'] ?? 'Open',
            reporter: data['reporter'] ?? '',
            createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        }).toList();
      }).toList();

      // Wait for all futures and flatten the results
      final results = await Future.wait(futures);
      for (var issuesList in results) {
        allIssuesList.addAll(issuesList);
      }

      // Sort by priority and creation date
      allIssuesList.sort((a, b) {
        const priorityOrder = {'Critical': 0, 'High': 1, 'Medium': 2, 'Low': 3, 'None': 4};
        final aPriority = priorityOrder[a.priority] ?? 4;
        final bPriority = priorityOrder[b.priority] ?? 4;
        if (aPriority != bPriority) {
          return aPriority.compareTo(bPriority);
        }
        return b.createdAt.compareTo(a.createdAt);
      });
      
      _allIssues = allIssuesList;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await Future.wait([
      _loadAllHistory(),
      _loadAllIssues(),
    ]);
  }

  /// Helper to get icon from history title
  IconData? _getIconFromTitle(String title) {
    final titleLower = title.toLowerCase();
    if (titleLower.contains('created') || titleLower.contains('added')) {
      return Icons.add_circle_outline;
    } else if (titleLower.contains('updated') || titleLower.contains('modified')) {
      return Icons.edit_outlined;
    } else if (titleLower.contains('assigned') || titleLower.contains('checkout')) {
      return Icons.person_add_alt_1;
    } else if (titleLower.contains('issue') || titleLower.contains('problem')) {
      return Icons.warning_amber;
    } else if (titleLower.contains('comment')) {
      return Icons.comment;
    } else if (titleLower.contains('attachment')) {
      return Icons.attachment;
    } else if (titleLower.contains('tagged') || titleLower.contains('qr')) {
      return Icons.qr_code;
    } else if (titleLower.contains('information')) {
      return Icons.info_outline;
    }
    return Icons.history;
  }
}

