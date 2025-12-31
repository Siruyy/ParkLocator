import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/venues/models/venue.dart';
import 'package:mobile/venues/view/book_for_later_page.dart';
import 'package:mobile/venues/view/venue_detail_page.dart';

class BookingTypePage extends StatelessWidget {
  const BookingTypePage({required this.venue, super.key});

  final Venue venue;

  static Route<void> route({required Venue venue}) {
    return MaterialPageRoute<void>(
      builder: (_) => BookingTypePage(venue: venue),
    );
  }

  /// Smart navigation - skips this page if only one booking option is available
  static void navigateToBooking(BuildContext context, Venue venue) {
    final isFull = venue.status == VenueStatus.full;
    final canBookNow = venue.supportsRealTimeBooking && !isFull;
    final canBookLater = venue.supportsFutureBooking;

    // If only Book Now is available, go directly to venue detail
    if (canBookNow && !canBookLater) {
      Navigator.of(context).push(VenueDetailPage.route(venueId: venue.id));
      return;
    }

    // If only Book for Later is available, go directly to book for later
    if (!canBookNow && canBookLater) {
      Navigator.of(context).push(BookForLaterPage.route(venue: venue));
      return;
    }

    // If both or neither are available, show selection page
    Navigator.of(context).push(BookingTypePage.route(venue: venue));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF101922)
        : const Color(0xFFF6F7F8);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    const primaryColor = Color(0xFF137FEC);

    final isFull = venue.status == VenueStatus.full;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor.withOpacity(0.95),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Select Booking Type',
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Venue Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[300],
                        image: venue.imageUrl != null
                            ? DecorationImage(
                                image: NetworkImage(venue.imageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            venue.name,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: subTextColor,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  venue.address,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: subTextColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₱${venue.pricePerHour.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Header
              Text(
                'When do you want to park?',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Choose how you'd like to reserve your spot.",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: subTextColor,
                ),
              ),
              const SizedBox(height: 24),

              // Book Now Button - only show if venue supports real-time booking
              if (venue.supportsRealTimeBooking)
                _BookingOptionCard(
                  title: isFull ? 'Full Now' : 'Book Now',
                  description: isFull
                      ? 'This venue is currently full. Please check back later or book for a future time.'
                      : 'Start parking immediately. Your timer begins once you enter the facility. Best for current trips.',
                  icon: Icons.timer,
                  iconColor: isFull ? Colors.grey : primaryColor,
                  iconBgColor: isFull
                      ? (isDark ? Colors.grey[800]! : Colors.grey[200]!)
                      : (isDark
                            ? Colors.blue[900]!.withOpacity(0.3)
                            : Colors.blue[50]!),
                  isRecommended: !isFull && venue.supportsFutureBooking,
                  enabled: !isFull,
                  onTap: () {
                    Navigator.of(context).push(
                      VenueDetailPage.route(venueId: venue.id),
                    );
                  },
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  primaryColor: primaryColor,
                ),
              if (venue.supportsRealTimeBooking && venue.supportsFutureBooking)
                const SizedBox(height: 16),

              // Book for Later Button - only show if venue supports future booking
              if (venue.supportsFutureBooking)
                _BookingOptionCard(
                  title: 'Book for Later',
                  description:
                      'Reserve a specific date and time slot in advance. Secure your spot for future appointments or events.',
                  icon: Icons.calendar_month,
                  iconColor: Colors.purple,
                  iconBgColor: isDark
                      ? Colors.purple[900]!.withOpacity(0.3)
                      : Colors.purple[50]!,
                  isRecommended: false,
                  onTap: () {
                    Navigator.of(context).push(
                      BookForLaterPage.route(venue: venue),
                    );
                  },
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  primaryColor: primaryColor,
                ),

              const SizedBox(height: 32),

              // Info Note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey[800]!.withOpacity(0.5)
                      : Colors.grey[100]!.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: subTextColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Reservations are held for ${venue.configuration?.entryGracePeriod ?? 15} minutes past the start time. Cancellations made less than 1 hour before booking may incur a fee.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: subTextColor,
                          height: 1.5,
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
}

class _BookingOptionCard extends StatelessWidget {
  const _BookingOptionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.isRecommended,
    required this.onTap,
    required this.isDark,
    required this.surfaceColor,
    required this.textColor,
    required this.subTextColor,
    required this.primaryColor,
    this.enabled = true,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final bool isRecommended;
  final VoidCallback onTap;
  final bool isDark;
  final Color surfaceColor;
  final Color textColor;
  final Color subTextColor;
  final Color primaryColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRecommended
                  ? primaryColor.withOpacity(0.3)
                  : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
              width: isRecommended ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                  if (enabled)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: Colors.transparent,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: subTextColor,
                  height: 1.5,
                ),
              ),
              if (isRecommended) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Recommended',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
