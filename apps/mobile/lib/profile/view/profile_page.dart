import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/auth/bloc/auth_bloc.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF101922) : const Color(0xFFF6F7F8);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const primaryColor = Color(0xFF137FEC);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState.user;
        final userEmail = user?.email ?? 'user@example.com';
        final userName = _extractNameFromEmail(userEmail);

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: backgroundColor.withOpacity(0.9),
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: Text(
              'Account',
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                height: 1,
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Column(
                children: [
                  // Profile Header
                  _ProfileHeader(
                    userName: userName,
                    userEmail: userEmail,
                    isDark: isDark,
                    textColor: textColor,
                    subTextColor: subTextColor,
                    primaryColor: primaryColor,
                  ),

                  // Essentials Section
                  _buildSectionHeader('Essentials', subTextColor),
                  _buildSectionContainer(
                    context,
                    isDark,
                    surfaceColor,
                    [
                      _buildMenuItem(
                        context: context,
                        icon: Icons.directions_car,
                        title: 'My Vehicles',
                        onTap: () {
                          _showComingSoon(context);
                        },
                        isDark: isDark,
                        textColor: textColor,
                        primaryColor: primaryColor,
                      ),
                      _buildDivider(isDark),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.account_balance_wallet,
                        title: 'Payment Methods',
                        onTap: () {
                          _showComingSoon(context);
                        },
                        isDark: isDark,
                        textColor: textColor,
                        primaryColor: primaryColor,
                      ),
                      _buildDivider(isDark),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.history,
                        title: 'Parking History',
                        onTap: () {
                          _showComingSoon(context);
                        },
                        isDark: isDark,
                        textColor: textColor,
                        primaryColor: primaryColor,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Preferences Section
                  _buildSectionHeader('Preferences', subTextColor),
                  _buildSectionContainer(
                    context,
                    isDark,
                    surfaceColor,
                    [
                      _buildSwitchItem(
                        context: context,
                        icon: Icons.notifications,
                        title: 'Push Notifications',
                        value: true,
                        onChanged: (val) {
                          _showComingSoon(context);
                        },
                        isDark: isDark,
                        textColor: textColor,
                        primaryColor: primaryColor,
                      ),
                      _buildDivider(isDark),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.lock,
                        title: 'Security & Password',
                        onTap: () {
                          _showComingSoon(context);
                        },
                        isDark: isDark,
                        textColor: textColor,
                        primaryColor: primaryColor,
                      ),
                      _buildDivider(isDark),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.language,
                        title: 'Language',
                        trailingText: 'English',
                        onTap: () {
                          _showComingSoon(context);
                        },
                        isDark: isDark,
                        textColor: textColor,
                        primaryColor: primaryColor,
                        subTextColor: subTextColor,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Support Section
                  _buildSectionHeader('Support', subTextColor),
                  _buildSectionContainer(
                    context,
                    isDark,
                    surfaceColor,
                    [
                      _buildMenuItem(
                        context: context,
                        icon: Icons.help,
                        title: 'How to Park',
                        onTap: () {
                          _showComingSoon(context);
                        },
                        isDark: isDark,
                        textColor: textColor,
                        primaryColor: primaryColor,
                      ),
                      _buildDivider(isDark),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.bug_report,
                        title: 'Report a Problem',
                        onTap: () {
                          _showComingSoon(context);
                        },
                        isDark: isDark,
                        textColor: textColor,
                        primaryColor: primaryColor,
                      ),
                      _buildDivider(isDark),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.description,
                        title: 'Terms of Service',
                        onTap: () {
                          _showComingSoon(context);
                        },
                        isDark: isDark,
                        textColor: textColor,
                        primaryColor: primaryColor,
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Logout Section
                  _LogoutSection(
                    surfaceColor: surfaceColor,
                    isDark: isDark,
                    subTextColor: subTextColor,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  String _extractNameFromEmail(String email) {
    final localPart = email.split('@').first;
    // Convert dots and underscores to spaces and capitalize each word
    final words = localPart.split(RegExp(r'[._]'));
    return words.map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: SizedBox(
        width: double.infinity,
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContainer(
    BuildContext context,
    bool isDark,
    Color surfaceColor,
    List<Widget> children,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    required Color textColor,
    required Color primaryColor,
    String? trailingText,
    Color? subTextColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: subTextColor,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
    required Color textColor,
    required Color primaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? Colors.grey[700]!.withOpacity(0.5) : Colors.grey[100],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.userName,
    required this.userEmail,
    required this.isDark,
    required this.textColor,
    required this.subTextColor,
    required this.primaryColor,
  });

  final String userName;
  final String userEmail;
  final bool isDark;
  final Color textColor;
  final Color subTextColor;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(0.1),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.white,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _getInitials(userName),
                    style: GoogleFonts.inter(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userEmail,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: subTextColor,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(EditProfilePage.route());
            },
            style: TextButton.styleFrom(
              foregroundColor: primaryColor,
              textStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Edit Profile'),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words[0].isNotEmpty ? words[0][0].toUpperCase() : '?';
    }
    return '${words[0][0]}${words[words.length - 1][0]}'.toUpperCase();
  }
}

class _LogoutSection extends StatelessWidget {
  const _LogoutSection({
    required this.surfaceColor,
    required this.isDark,
    required this.subTextColor,
  });

  final Color surfaceColor;
  final bool isDark;
  final Color subTextColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showLogoutDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: surfaceColor,
                foregroundColor: Colors.red,
                elevation: 0,
                side: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Log Out',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ParkLocator v1.0.0',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: subTextColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Log Out',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            child: Text(
              'Log Out',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
