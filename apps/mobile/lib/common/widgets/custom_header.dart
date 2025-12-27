import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/notifications/view/notifications_page.dart';

class CustomHeader extends StatelessWidget {
  const CustomHeader({
    required this.title,
    super.key,
    this.showBackButton = false,
    this.onNotificationTap,
  });

  final String title;
  final bool showBackButton;
  final VoidCallback? onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A); // slate-900

    return Container(
      color: isDark ? const Color(0xFF101922) : const Color(0xFFF6F7F8),
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (showBackButton && Navigator.canPop(context))
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: textColor),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: onNotificationTap ??
                      () {
                        Navigator.of(context).push(NotificationsPage.route());
                      },
                  color: const Color(0xFF475569), // slate-600
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
