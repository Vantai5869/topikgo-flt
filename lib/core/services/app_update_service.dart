import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  /// Check for app updates and show dialog if available
  ///
  /// [forceUpdate] - If true, user must update to continue using app (Immediate Update)
  /// [forceUpdate] - If false, user can skip and update later (Flexible Update)
  Future<void> checkForUpdate(BuildContext context, {bool forceUpdate = false}) async {
    try {
      // Check if update is available
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        if (forceUpdate) {
          // Immediate update - user must update to continue
          await _performImmediateUpdate(context);
        } else {
          // Flexible update - user can choose to update or skip
          await _showUpdateDialog(context, updateInfo);
        }
      }
    } catch (e) {
      debugPrint('Error checking for update: $e');
    }
  }

  /// Show update dialog with flexible update option
  Future<void> _showUpdateDialog(BuildContext context, AppUpdateInfo updateInfo) async {
    if (!context.mounted) return;

    final shouldUpdate = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật mới có sẵn'),
        content: const Text(
          'Phiên bản mới của ứng dụng đã có sẵn. '
          'Bạn có muốn cập nhật ngay bây giờ không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );

    if (shouldUpdate == true && context.mounted) {
      await _performFlexibleUpdate(context);
    }
  }

  /// Perform flexible update (user can use app while downloading)
  Future<void> _performFlexibleUpdate(BuildContext context) async {
    try {
      await InAppUpdate.startFlexibleUpdate();

      // Listen for download completion
      InAppUpdate.completeFlexibleUpdate().then((_) {
        if (context.mounted) {
          _showUpdateCompleteDialog(context);
        }
      });
    } catch (e) {
      debugPrint('Error performing flexible update: $e');
      if (context.mounted) {
        _showUpdateErrorDialog(context);
      }
    }
  }

  /// Perform immediate update (user must update to continue)
  Future<void> _performImmediateUpdate(BuildContext context) async {
    try {
      await InAppUpdate.performImmediateUpdate();
    } catch (e) {
      debugPrint('Error performing immediate update: $e');
      if (context.mounted) {
        _showUpdateErrorDialog(context);
      }
    }
  }

  /// Show dialog when update is complete
  void _showUpdateCompleteDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật hoàn tất'),
        content: const Text(
          'Ứng dụng đã được cập nhật thành công. '
          'Vui lòng khởi động lại ứng dụng để áp dụng thay đổi.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Restart app (user can manually close and reopen)
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show error dialog when update fails
  void _showUpdateErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi cập nhật'),
        content: const Text(
          'Không thể cập nhật ứng dụng. '
          'Vui lòng thử lại sau hoặc cập nhật thủ công từ Google Play Store.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
