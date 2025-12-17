import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/api/api.dart';
import 'package:mobile/venues/view/venue_search_page.dart';

class BookingExpiredPage extends StatelessWidget {
  const BookingExpiredPage({required this.reservation, super.key});

  final Reservation reservation;

  static Route<void> route({required Reservation reservation}) {
    return MaterialPageRoute<void>(
      builder: (_) => BookingExpiredPage(reservation: reservation),
      fullscreenDialog: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Status',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Icon
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.timer_off_outlined,
                            size: 48,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF6F7F8),
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFF137FEC),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.priority_high,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Title
                    const Text(
                      'Booking Expired',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Description
                    Text(
                      'Your reservation at ${reservation.venue?.name ?? 'Venue'} has expired because check-in was not completed by the grace period.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Ticket Card
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Stack(
                        children: [
                          // VOID Stamp
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Transform.rotate(
                              angle: 0.2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.1), width: 4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'VOID',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0F172A).withOpacity(0.1),
                                    letterSpacing: 4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey[300],
                                    image: reservation.venue?.imageUrl != null
                                        ? DecorationImage(
                                            image: NetworkImage(reservation.venue!.imageUrl!),
                                            fit: BoxFit.cover,
                                            colorFilter: const ColorFilter.mode(
                                              Colors.grey,
                                              BlendMode.saturation,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                // Details
                                Expanded(
                                  child: Opacity(
                                    opacity: 0.7,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE2E8F0),
                                            borderRadius: BorderRadius.circular(100),
                                          ),
                                          child: const Text(
                                            'EXPIRED',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${reservation.venue?.name ?? 'Venue'} - Slot ${reservation.spot?.spotNumber ?? '--'}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today, size: 16, color: Color(0xFF94A3B8)),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                '${DateFormat('MMM d').format(reservation.createdAt ?? DateTime.now())} • ${DateFormat('HH:mm').format(reservation.createdAt ?? DateTime.now())} - ${DateFormat('HH:mm').format(reservation.expiresAt)}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF64748B),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Policy Notice
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF137FEC).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, size: 20, color: Color(0xFF137FEC)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.5),
                                children: [
                                  TextSpan(
                                    text: 'No Refund Policy: ',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text: 'As per our no-show terms, missed reservations are non-refundable. ',
                                  ),
                                  TextSpan(
                                    text: 'Read Policy',
                                    style: TextStyle(
                                      color: Color(0xFF137FEC),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
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
            
            // Bottom Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close modal
                        Navigator.push(context, VenueSearchPage.route());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF137FEC),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Find New Parking',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: Implement rebook logic
                        Navigator.of(context).pop();
                        Navigator.push(context, VenueSearchPage.route());
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Rebook Same Spot',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      // TODO: Contact support
                    },
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                        children: [
                          TextSpan(text: 'Was this a mistake? '),
                          TextSpan(
                            text: 'Contact Support',
                            style: TextStyle(
                              color: Color(0xFF137FEC),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
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
