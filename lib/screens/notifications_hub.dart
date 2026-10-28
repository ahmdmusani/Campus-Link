import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationsHub extends StatefulWidget {
  const NotificationsHub({super.key});

  @override
  State<NotificationsHub> createState() => _NotificationsHubState();
}

class _NotificationsHubState extends State<NotificationsHub> {
  final NotificationService _notificationService = NotificationService();

  static const Color _primary = Color(0xFF1A237E);
  static const Color _accent = Color(0xFF50C878);
  static const Color _bg = Color(0xFFFAFAFA);

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'request_created':
        return Icons.person_add_rounded;
      case 'request_accepted':
        return Icons.check_circle_rounded;
      case 'request_declined':
        return Icons.cancel_rounded;
      case 'ride_started':
        return Icons.directions_car_rounded;
      case 'ride_completed':
        return Icons.task_alt_rounded;
      case 'new_rating':
        return Icons.star_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'request_accepted':
      case 'ride_completed':
        return _accent;
      case 'request_declined':
        return Colors.redAccent;
      case 'new_rating':
        return Colors.amber.shade800;
      case 'ride_started':
      case 'request_created':
      default:
        return _primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications Hub',
          style: TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.streamUserNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: _primary));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading notifications: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                ),
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: ListView(
                children: [
                  const SizedBox(height: 100),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_off_rounded,
                              size: 48,
                              color: _primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Notifications',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primary),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'You do not have any notification alerts at this time.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black45, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                return _buildNotificationCard(n);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel n) {
    final icon = _getNotificationIcon(n.type);
    final color = _getNotificationColor(n.type);
    final timeStr =
        '${n.createdAt.day}/${n.createdAt.month} at ${n.createdAt.hour.toString().padLeft(2, '0')}:${n.createdAt.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () {
        if (!n.isRead) {
          _notificationService.markAsRead(n.notificationId);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: n.isRead ? Colors.white : _primary.withOpacity(0.03),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: n.isRead ? Colors.black.withOpacity(0.06) : _primary.withOpacity(0.25),
            width: n.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: n.isRead ? _primary : Colors.black87,
                          ),
                        ),
                      ),
                      if (!n.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: _accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.body,
                    style: const TextStyle(color: Colors.black87, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeStr,
                    style: const TextStyle(color: Colors.black45, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
