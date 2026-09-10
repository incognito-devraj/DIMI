import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

class NotificationDetectorScreen extends StatefulWidget {
  const NotificationDetectorScreen({super.key});
  @override State<NotificationDetectorScreen> createState() => _NotificationDetectorScreenState();
}

class _NotificationDetectorScreenState extends State<NotificationDetectorScreen> {
  static const channel = MethodChannel('com.dimi.dimi_app/transaction_detection');
  Timer? _timer;
  List<Map<String, dynamic>> _events = const [];
  bool _connected = false;

  @override void initState() { super.initState(); _refresh(); _timer = Timer.periodic(const Duration(seconds: 1), (_) => _refresh()); }
  @override void dispose() { _timer?.cancel(); super.dispose(); }
  Future<void> _refresh() async {
    final connected = await channel.invokeMethod<bool>('isNotificationAccessEnabled') ?? false;
    final raw = await channel.invokeMethod<List<dynamic>>('getNotificationFeed') ?? const [];
    if (!mounted) return;
    setState(() { _connected = connected; _events = raw.map((item) => Map<String, dynamic>.from(item as Map)).toList().reversed.toList(); });
  }

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('Notification Detector'), actions: [IconButton(tooltip: 'Clear history', icon: const Icon(Icons.delete_outline), onPressed: () async { await channel.invokeMethod<void>('clearNotificationFeed'); _refresh(); })]),
    body: Column(children: [
      ListTile(leading: Icon(_connected ? Icons.check_circle : Icons.cancel, color: _connected ? Colors.green : Colors.red), title: Text(_connected ? 'Notification Access CONNECTED' : 'Notification Access NOT CONNECTED'), trailing: _connected ? null : FilledButton(onPressed: () => channel.invokeMethod<void>('openNotificationAccessSettings'), child: const Text('Enable'))),
      const Divider(height: 1),
      Expanded(child: _events.isEmpty ? const Center(child: Text('No notifications received yet. Keep this screen open and send a test notification.')) : ListView.builder(itemCount: _events.length, itemBuilder: (_, index) { final event = _events[index]; final time = DateTime.fromMillisecondsSinceEpoch((event['timestamp'] as num?)?.toInt() ?? 0); return ListTile(dense: true, leading: const Icon(Icons.notifications_none), title: Text(event['sourcePackage'] as String? ?? 'Unknown app'), subtitle: Text('${event['title'] ?? ''}\n${event['body'] ?? event['bigText'] ?? ''}\n${time.toLocal()}'), isThreeLine: true); }))
    ]),
  );
}
