import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile/api/api.dart' as api;
import 'package:mobile/notifications/bloc/notifications_bloc.dart';
import 'package:mobile/notifications/repository/notifications_repository.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (context) => NotificationsBloc(
          notificationsRepository: context.read<NotificationsRepository>(),
        )..add(NotificationsFetched()),
        child: const NotificationsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF101922) : const Color(0xFFF6F7F8);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const primaryColor = Color(0xFF137FEC);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<NotificationsBloc>().add(AllNotificationsMarkedAsRead());
            },
            child: Text(
              'Mark all as read',
              style: GoogleFonts.inter(
                color: primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          if (state.status == NotificationsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == NotificationsStatus.failure) {
            return Center(
              child: Text(
                'Failed to load notifications',
                style: GoogleFonts.inter(color: subTextColor),
              ),
            );
          }
          if (state.notifications.isEmpty) {
            return Center(
              child: Text(
                'No notifications',
                style: GoogleFonts.inter(color: subTextColor),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = state.notifications[index];
              return GestureDetector(
                onTap: () {
                  if (!item.isRead) {
                    context
                        .read<NotificationsBloc>()
                        .add(NotificationMarkedAsRead(item.id));
                  }
                },
                child: _buildNotificationCard(
                  context,
                  item,
                  surfaceColor,
                  textColor,
                  subTextColor,
                  isDark,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    api.Notification item,
    Color surfaceColor,
    Color textColor,
    Color subTextColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: !item.isRead
            ? (isDark ? const Color(0xFF1E293B) : Colors.white)
            : (isDark ? const Color(0xFF101922) : const Color(0xFFF6F7F8)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        boxShadow: !item.isRead
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIcon(item.type),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: !item.isRead ? FontWeight.bold : FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                    if (!item.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF137FEC),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.message,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: !item.isRead ? textColor.withOpacity(0.8) : subTextColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDate(item.createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: subTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }

  Widget _buildIcon(api.NotificationType type) {
    IconData iconData;
    Color color;
    Color bgColor;

    switch (type) {
      case api.NotificationType.success:
        iconData = Icons.check_circle;
        color = Colors.green;
        bgColor = Colors.green.withOpacity(0.1);
      case api.NotificationType.warning:
        iconData = Icons.warning_amber_rounded;
        color = Colors.orange;
        bgColor = Colors.orange.withOpacity(0.1);
      case api.NotificationType.error:
        iconData = Icons.error_outline;
        color = Colors.red;
        bgColor = Colors.red.withOpacity(0.1);
      case api.NotificationType.info:
      default:
        iconData = Icons.notifications;
        color = const Color(0xFF137FEC);
        bgColor = const Color(0xFF137FEC).withOpacity(0.1);
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: color,
        size: 20,
      ),
    );
  }
}
