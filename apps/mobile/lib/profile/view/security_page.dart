import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const SecurityPage());
  }

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  bool _faceIdEnabled = true;
  bool _autoLockEnabled = false;

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
        backgroundColor: backgroundColor.withOpacity(0.9),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Security & Password',
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
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Column(
            children: [
              // Hero Section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.blue[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shield,
                        size: 40,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Protect your account',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your login details and review security settings to keep your parking account safe.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: subTextColor,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Sign-in & Authentication
              _buildSectionHeader('Sign-in & Authentication', subTextColor),
              _buildSectionContainer(
                isDark: isDark,
                surfaceColor: surfaceColor,
                children: [
                  _buildMenuItem(
                    icon: Icons.password,
                    title: 'Change Password',
                    subtitle: 'Last changed 3 months ago',
                    onTap: () {},
                    isDark: isDark,
                    textColor: textColor,
                    subTextColor: subTextColor,
                    primaryColor: primaryColor,
                  ),
                  _buildDivider(isDark),
                  _buildMenuItem(
                    icon: Icons.phonelink_lock,
                    title: 'Two-Factor Authentication',
                    subtitle: 'Recommended',
                    onTap: () {},
                    isDark: isDark,
                    textColor: textColor,
                    subTextColor: subTextColor,
                    primaryColor: primaryColor,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[700] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'OFF',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: subTextColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // App Access
              _buildSectionHeader('App Access', subTextColor),
              _buildSectionContainer(
                isDark: isDark,
                surfaceColor: surfaceColor,
                children: [
                  _buildSwitchItem(
                    icon: Icons.face,
                    title: 'Face ID',
                    subtitle: 'Use Face ID to sign in',
                    value: _faceIdEnabled,
                    onChanged: (v) => setState(() => _faceIdEnabled = v),
                    isDark: isDark,
                    textColor: textColor,
                    subTextColor: subTextColor,
                    primaryColor: primaryColor,
                  ),
                  _buildDivider(isDark),
                  _buildSwitchItem(
                    icon: Icons.timer,
                    title: 'Auto-Lock App',
                    subtitle: 'Lock after 5 mins of inactivity',
                    value: _autoLockEnabled,
                    onChanged: (v) => setState(() => _autoLockEnabled = v),
                    isDark: isDark,
                    textColor: textColor,
                    subTextColor: subTextColor,
                    primaryColor: primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Activity & Devices
              _buildSectionHeader('Activity & Devices', subTextColor),
              _buildSectionContainer(
                isDark: isDark,
                surfaceColor: surfaceColor,
                children: [
                  _buildMenuItem(
                    icon: Icons.history,
                    title: 'Recent Login Activity',
                    onTap: () {},
                    isDark: isDark,
                    textColor: textColor,
                    subTextColor: subTextColor,
                    primaryColor: primaryColor,
                  ),
                  _buildDivider(isDark),
                  _buildMenuItem(
                    icon: Icons.devices,
                    title: 'Trusted Devices',
                    onTap: () {},
                    isDark: isDark,
                    textColor: textColor,
                    subTextColor: subTextColor,
                    primaryColor: primaryColor,
                    trailing: Text(
                      '2 Active',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: subTextColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Footer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      'If you notice any suspicious activity, please contact support immediately.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: subTextColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Sign out of all devices',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildSectionContainer({
    required bool isDark,
    required Color surfaceColor,
    required List<Widget> children,
  }) {
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

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? Colors.grey[700]!.withOpacity(0.5) : Colors.grey[100],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required bool isDark,
    required Color textColor,
    required Color subTextColor,
    required Color primaryColor,
    Widget? trailing,
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
                color: isDark ? Colors.grey[700] : Colors.blue[50],
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: subTextColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              trailing,
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.chevron_right,
              color: subTextColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
    required Color textColor,
    required Color subTextColor,
    required Color primaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.blue[50],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: subTextColor,
                  ),
                ),
              ],
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
}
