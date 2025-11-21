import 'dart:io';
import 'package:flutter/foundation.dart';

/// Utility class for network-related operations
class NetworkUtils {
  /// Check if device has internet connection
  static Future<bool> hasInternetConnection() async {
    if (kIsWeb) {
      // Web doesn't have a reliable way to check connectivity
      // Assume connected if on web
      return true;
    }

    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      debugPrint('No internet connection: $e');
      return false;
    }
  }

  /// Check if error is network-related
  static bool isNetworkError(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('socket') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('no internet');
  }

  /// Get user-friendly error message
  static String getErrorMessage(Object error) {
    if (isNetworkError(error)) {
      return 'Network error. Please check your internet connection and try again.';
    }

    final errorString = error.toString();
    if (errorString.contains('permission')) {
      return 'You do not have permission to perform this action.';
    }

    if (errorString.contains('not found')) {
      return 'The requested item was not found.';
    }

    if (errorString.contains('already exists')) {
      return 'This item already exists.';
    }

    return 'An error occurred. Please try again.';
  }
}

