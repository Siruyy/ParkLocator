import 'package:flutter/material.dart';
import 'package:mobile/venues/models/venue.dart';
import 'package:mobile/venues/view/booking_type_page.dart';

class VenueCard extends StatelessWidget {
  const VenueCard({required this.venue, super.key});

  final Venue venue;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: venue.imageUrl != null
                      ? Image.network(
                          venue.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: Colors.grey[300]),
                        )
                      : Container(color: Colors.grey[300]),
                ),
              ),
              // Status Badge
              Positioned(
                top: 12,
                left: 12,
                child: _StatusBadge(status: venue.status),
              ),
              // Price (Reservation Fee)
              Positioned(
                bottom: 12,
                right: 12,
                child: Text(
                  '₱${venue.pricePerHour.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                  ),
                ),
              ),
            ],
          ),
          // Info Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            venue.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${venue.address} • ${venue.distanceFormatted}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _SpotsLeftBadge(
                      spots: venue.availableSpots,
                      status: venue.status,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (venue.hasCoveredParking) ...[
                          const Icon(Icons.roofing, color: Colors.grey, size: 20),
                          const SizedBox(width: 8),
                        ],
                        if (venue.hasCCTV)
                          const Icon(Icons.videocam, color: Colors.grey, size: 20),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        BookingTypePage.navigateToBooking(context, venue);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF137FEC,
                        ), // Primary color
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        venue.status == VenueStatus.full
                            ? 'Notify Me'
                            : 'Book Now',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final VenueStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case VenueStatus.available:
        color = Colors.green;
        text = 'Available';
      case VenueStatus.fillingFast:
        color = Colors.orange;
        text = 'Filling Fast';
      case VenueStatus.full:
        color = Colors.red;
        text = 'Full';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotsLeftBadge extends StatelessWidget {
  const _SpotsLeftBadge({required this.spots, required this.status});

  final int spots;
  final VenueStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bgColor;

    switch (status) {
      case VenueStatus.available:
        color = Colors.green;
        bgColor = Colors.green.withValues(alpha: 0.1);
      case VenueStatus.fillingFast:
        color = Colors.orange;
        bgColor = Colors.orange.withValues(alpha: 0.1);
      case VenueStatus.full:
        color = Colors.red;
        bgColor = Colors.red.withValues(alpha: 0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$spots spots left',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
