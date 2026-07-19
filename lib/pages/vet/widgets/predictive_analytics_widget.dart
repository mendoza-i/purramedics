import 'package:flutter/material.dart';
import 'package:purramedics/services/firestore_service.dart';
import 'package:purramedics/theme/app_theme.dart';
import 'package:purramedics/utils/linear_regression.dart';
import 'package:purramedics/widgets/widgets.dart';

class PredictiveAnalyticsWidget extends StatefulWidget {
  const PredictiveAnalyticsWidget({super.key});

  @override
  State<PredictiveAnalyticsWidget> createState() => _PredictiveAnalyticsWidgetState();
}

class _PredictiveAnalyticsWidgetState extends State<PredictiveAnalyticsWidget> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<double> _historicalCounts = [];
  LinearRegression? _model;
  List<double> _forecastCounts = [];

  @override
  void initState() {
    super.initState();
    _processData();
  }

  Future<void> _processData() async {
    // Fetch all appointments
    _firestoreService.getAllAppointmentsStream().listen((appointments) {
      if (!mounted) return;

      // Map dates to counts for the last 30 days
      final now = DateTime.now();
      final Map<String, int> dailyCounts = {};

      // Initialize last 30 days with 0
      for (int i = 29; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        final dateStr = "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
        dailyCounts[dateStr] = 0;
      }

      // Count appointments for those days
      for (var appt in appointments) {
        final date = appt['date'] as String?;
        if (date != null && dailyCounts.containsKey(date)) {
          // We can count all appointments or just confirmed ones. Let's count all non-declined/non-cancelled.
          final status = appt['status']?.toString() ?? '';
          if (status != 'Declined' && status != 'Cancelled') {
            dailyCounts[date] = dailyCounts[date]! + 1;
          }
        }
      }

      // Extract y values (counts) in chronological order
      final yValues = dailyCounts.values.map((e) => e.toDouble()).toList();
      // Extract x values (days 1 to 30)
      final xValues = List.generate(yValues.length, (index) => (index + 1).toDouble());

      // Train model
      final model = LinearRegression.calculate(xValues, yValues);

      // Forecast next 7 days (days 31 to 37)
      final forecast = <double>[];
      for (int i = 31; i <= 37; i++) {
        // Ensure we don't predict negative patients
        double prediction = model.predict(i.toDouble());
        if (prediction < 0) prediction = 0;
        forecast.add(prediction);
      }

      setState(() {
        _historicalCounts = yValues;
        _model = model;
        _forecastCounts = forecast;
        _isLoading = false;
      });
    });
  }

  void _showModelTester() {
    showDialog(
      context: context,
      builder: (ctx) => _ModelTesterDialog(
        historicalCounts: _historicalCounts,
        model: _model,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.rXl,
          boxShadow: AppShadows.sm,
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final tomorrowForecast = _forecastCounts.isNotEmpty ? _forecastCounts.first.round() : 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.rXl,
        boxShadow: AppShadows.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: const BoxDecoration(
                      color: AppColors.primarySurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.insights_rounded, color: AppColors.primary, size: 20),
                  ),
                  AppSpacing.hMd,
                  Text(
                    'Predictive Analytics',
                    style: AppTypography.titleMedium,
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _showModelTester,
                icon: const Icon(Icons.science_rounded, size: 16),
                label: const Text('Test Model'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: AppTypography.labelMedium,
                ),
              ),
            ],
          ),
          AppSpacing.vLg,
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$tomorrowForecast',
                style: AppTypography.displayMedium.copyWith(color: AppColors.primary),
              ),
              AppSpacing.hSm,
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Patients forecasted tomorrow',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          AppSpacing.vLg,
          Text(
            '7-Day Forecast Trend',
            style: AppTypography.labelMedium.copyWith(color: AppColors.textTertiary),
          ),
          AppSpacing.vSm,
          // Simple Bar Chart visualization
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final count = _forecastCounts[index];
              // Normalize height (max 50, arbitrary scale for UI)
              final maxCount = _forecastCounts.reduce((a, b) => a > b ? a : b);
              final height = maxCount == 0 ? 10.0 : (count / maxCount) * 60.0;
              
              final now = DateTime.now();
              final futureDate = now.add(Duration(days: index + 1));
              final dayLabel = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][futureDate.weekday - 1];

              return Column(
                children: [
                  Text(
                    count.round().toString(),
                    style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                  ),
                  AppSpacing.vXs,
                  Container(
                    width: 32,
                    height: height < 10 ? 10 : height,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  AppSpacing.vXs,
                  Text(
                    dayLabel,
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ModelTesterDialog extends StatefulWidget {
  final List<double> historicalCounts;
  final LinearRegression? model;

  const _ModelTesterDialog({required this.historicalCounts, required this.model});

  @override
  State<_ModelTesterDialog> createState() => _ModelTesterDialogState();
}

class _ModelTesterDialogState extends State<_ModelTesterDialog> {
  final TextEditingController _customDayCtrl = TextEditingController(text: '31');
  double? _customPrediction;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadii.rXl),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.science_rounded, color: AppColors.primary),
                  AppSpacing.hMd,
                  Expanded(
                    child: Text('Model Tester', style: AppTypography.titleLarge),
                  ),
                ],
              ),
              AppSpacing.vLg,
              Text(
                'How does this work?',
                style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
              ),
              AppSpacing.vSm,
              Text(
                '1. We took your appointment data from the last 30 days and mapped it on a graph.\n'
                '2. The algorithm then calculated a "line of best fit" through those points to find the trend.\n'
                '3. Using the equation of that line (y = mx + b), we can predict future days!',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.5),
              ),
              AppSpacing.vLg,
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: AppRadii.rMd,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Calculated Formula:', style: AppTypography.labelLarge),
                    AppSpacing.vSm,
                    Text('Future Patients = (Slope × Day) + Intercept', style: AppTypography.bodyMedium.copyWith(fontFamily: 'monospace', color: AppColors.primary)),
                    AppSpacing.vMd,
                    Text('• Slope (m): ${widget.model?.slope.toStringAsFixed(4)}', style: AppTypography.bodyMedium),
                    Text('  (Traffic is changing by this many patients per day)', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
                    AppSpacing.vSm,
                    Text('• Intercept (b): ${widget.model?.intercept.toStringAsFixed(4)}', style: AppTypography.bodyMedium),
                    Text('  (The starting baseline of the graph)', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
                  ],
                ),
              ),
              AppSpacing.vLg,
              Text('Try it yourself!', style: AppTypography.labelLarge),
              AppSpacing.vSm,
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customDayCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Enter Future Day (e.g. 31)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  AppSpacing.hMd,
                  ElevatedButton(
                    onPressed: () {
                      final day = double.tryParse(_customDayCtrl.text);
                      if (day != null && widget.model != null) {
                        setState(() {
                          _customPrediction = widget.model!.predict(day);
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Calculate'),
                  ),
                ],
              ),
              if (_customPrediction != null) ...[
                AppSpacing.vMd,
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: AppRadii.rMd,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.success),
                      AppSpacing.hMd,
                      Expanded(
                        child: Text(
                          'Prediction for Day ${_customDayCtrl.text}: ${_customPrediction!.toStringAsFixed(2)} patients (Rounded: ${_customPrediction!.round()})',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              AppSpacing.vLg,
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
