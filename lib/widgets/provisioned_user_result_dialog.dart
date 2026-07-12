import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/user_provisioning_service.dart';

Future<void> showProvisionedUserResultDialog(
  BuildContext context,
  UserProvisioningResult result, {
  required String email,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Account Created'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Login email: $email'),
          const SizedBox(height: 8),
          SelectableText('User ID: ${result.uid}'),
          if (result.temporaryPassword != null) ...[
            const SizedBox(height: 12),
            const Text(
              'Temporary password (share securely):',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            SelectableText(result.temporaryPassword!),
          ],
        ],
      ),
      actions: [
        if (result.temporaryPassword != null)
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: result.temporaryPassword!),
              );
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Password copied')),
              );
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy password'),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Done'),
        ),
      ],
    ),
  );
}
