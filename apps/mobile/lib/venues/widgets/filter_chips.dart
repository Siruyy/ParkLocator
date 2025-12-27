import 'package:flutter/material.dart';

class FilterChips extends StatelessWidget {
  const FilterChips({
    required this.selectedFilter,
    required this.onSelected,
    super.key,
  });

  final String selectedFilter;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _FilterChip(
            label: 'Nearest',
            icon: Icons.near_me,
            isSelected: selectedFilter == 'Nearest',
            onTap: () => onSelected('Nearest'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Cheapest',
            isSelected: selectedFilter == 'Cheapest',
            onTap: () => onSelected('Cheapest'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Covered',
            isSelected: selectedFilter == 'Covered',
            onTap: () => onSelected('Covered'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: '24/7',
            isSelected: selectedFilter == '24/7',
            onTap: () => onSelected('24/7'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.onTap,
    this.icon,
    this.isSelected = false,
  });

  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF137FEC) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: isSelected ? null : Border.all(color: Colors.grey[300]!),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF137FEC).withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
