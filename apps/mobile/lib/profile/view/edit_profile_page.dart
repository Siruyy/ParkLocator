import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/auth/bloc/auth_bloc.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const EditProfilePage());
  }

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.user;
    _nameController = TextEditingController(text: _extractNameFromEmail(user?.email ?? ''));
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: ''); // Phone not in user model yet
  }

  String _extractNameFromEmail(String email) {
    if (email.isEmpty) return '';
    final localPart = email.split('@').first;
    final words = localPart.split(RegExp('[._]'));
    return words.map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
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
        backgroundColor: backgroundColor.withOpacity(0.9),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edit Profile',
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Profile Photo Section
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 128,
                                height: 128,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
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
                                  image: const DecorationImage(
                                    image: NetworkImage(
                                      'https://lh3.googleusercontent.com/aida-public/AB6AXuBbGmIMINAmYGEtlWv7tystTGOFe1UA8Jb5JWZl9cALNxHZh3HFNXrl3t0foX3dHM3dGAC-JNFMgLYUZvMbNEQE7JqOTiIKCw-8xd6kpTqnwUxr7EY_eY4XHi2xkRHyjafG6RuFANvjBnhh-3v1Pld0VHlvflUPEY_imoBB9k4vRk6U3rT3rLx_kCKflaEUjpVMmQa0iCHZAsXDexfpFrqJoL0HZGv9-JD7lgXs2_6Q8w-5Bq7oSRo3tliOarhhwdjy3906FrMrvC_C',
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: backgroundColor,
                                      width: 4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: primaryColor,
                              textStyle: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('Change Profile Photo'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Form Fields
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person,
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                      textColor: textColor,
                      subTextColor: subTextColor,
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.mail,
                      inputType: TextInputType.emailAddress,
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                      textColor: textColor,
                      subTextColor: subTextColor,
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.call,
                      inputType: TextInputType.phone,
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                      textColor: textColor,
                      subTextColor: subTextColor,
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'This information will be used for your parking reservations and receipts. Your email is visible to parking operators only when you make a booking.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: subTextColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
          // Bottom Save Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                ),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement save logic
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: primaryColor.withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save Changes',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required Color surfaceColor,
    required Color textColor,
    required Color subTextColor,
    required Color primaryColor,
    TextInputType inputType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: subTextColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
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
          child: TextField(
            controller: controller,
            keyboardType: inputType,
            style: GoogleFonts.inter(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: subTextColor,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              hintStyle: GoogleFonts.inter(
                color: subTextColor.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
