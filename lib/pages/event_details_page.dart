/// ============================================================================
/// EVENT DETAILS PAGE
/// Displays full information about a specific drive or event.
/// ============================================================================
library;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:purramedics/models/event.dart';
import 'package:purramedics/theme/app_theme.dart';
import 'package:purramedics/widgets/widgets.dart';

class EventDetailsPage extends StatelessWidget {
  final Event event;

  const EventDetailsPage({super.key, required this.event});

  Future<void> _addToCalendar() async {
    final title = Uri.encodeComponent(event.title);
    final details = Uri.encodeComponent(event.description);
    final location = Uri.encodeComponent(event.location);
    final url = Uri.parse(
      'https://www.google.com/calendar/render?action=TEMPLATE&text=$title&details=$details&location=$location',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch calendar url');
    }
  }

  IconData _getIconFromName(String name) {
    switch (name) {
      case 'vaccine':
        return Icons.vaccines_rounded;
      case 'adoption':
        return Icons.pets_rounded;
      case 'checkup':
        return Icons.health_and_safety_rounded;
      case 'community':
        return Icons.people_rounded;
      case 'emergency':
        return Icons.warning_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventColor = Color(event.colorValue);
    final eventIcon = _getIconFromName(event.iconName);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: eventColor.withOpacity(0.12),
                  borderRadius: AppRadii.rXl,
                ),
                child: Center(
                  child: Icon(eventIcon, size: 80, color: eventColor),
                ),
              ),
              AppSpacing.vXxl,
              Text(event.title, style: AppTypography.displayMedium),
              AppSpacing.vLg,
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: AppRadii.rMd,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                    AppSpacing.hSm,
                    Text(event.date, style: AppTypography.titleSmall),
                  ],
                ),
              ),
              AppSpacing.vXxl,
              _buildDetailRow(
                title: 'Location',
                content: event.location,
                icon: Icons.location_on_rounded,
              ),
              AppSpacing.vLg,
              _buildDetailRow(
                title: 'About this event',
                content: event.description.isNotEmpty
                    ? event.description
                    : 'No additional details provided for this event.',
                icon: Icons.info_outline_rounded,
              ),
              AppSpacing.vHuge,
              PrimaryButton(
                label: 'Add to Calendar',
                icon: Icons.calendar_today_rounded,
                onPressed: _addToCalendar,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconAvatar(
          icon: icon,
          color: AppColors.textSecondary,
          background: AppColors.surfaceAlt,
        ),
        AppSpacing.hLg,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              AppSpacing.vXs,
              Text(
                content,
                style: AppTypography.bodyLarge.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
