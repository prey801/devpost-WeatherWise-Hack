import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  final DateTime? lastUpdated;
  final bool isExpired;

  const OfflineBanner({
    Key? key,
    this.lastUpdated,
    this.isExpired = false,
  }) : super(key: key);

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isExpired ? Colors.orange[700] : Colors.orange[600];
    final timeString = lastUpdated != null ? _formatTime(lastUpdated!) : 'Unknown';

    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isExpired
                  ? 'Offline • Cached data (older than 2 hours)'
                  : 'Offline • Last updated $timeString',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
