import 'package:flutter/material.dart';
import 'package:safeskies/models/alert.dart';

class AlertCard extends StatelessWidget {
  final Alert alert;
  final VoidCallback? onTap;

  const AlertCard({
    Key? key,
    required this.alert,
    this.onTap,
  }) : super(key: key);

  Color _getRiskColor() {
    switch (alert.label.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getRiskColor();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 8,
          height: 56,
          color: color,
        ),
        title: Text(
          alert.message,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Radius: ${alert.radiusKm.toStringAsFixed(1)}km • Issued ${_formatTime(alert.issuedAt)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          alert.label.toUpperCase(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
