import 'package:flutter/material.dart';

import 'dimi_action_dialog.dart';

Future<bool> showDimiDeleteConfirmation(
  BuildContext context, {
  required String itemLabel,
}) async {
  return await showDimiActionDialog<bool>(
        context,
        title: 'Are you sure?',
        message: 'Delete this $itemLabel permanently?',
        actions: const [
          DimiDialogAction(label: 'Cancel', value: false),
          DimiDialogAction(label: 'Delete', value: true, primary: true),
        ],
      ) ??
      false;
}
