import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shimmer/shimmer.dart';
import 'package:purramedics/theme/app_theme.dart';
import 'package:purramedics/widgets/widgets.dart';

class SeasonalForecastWidget extends StatefulWidget {
  const SeasonalForecastWidget({super.key});

  @override
  State<SeasonalForecastWidget> createState() => _SeasonalForecastWidgetState();
}

class _SeasonalForecastWidgetState extends State<SeasonalForecastWidget> {
  final DateTime now = DateTime.now();

  bool _isLoading = true;
  double? _temperature;
  double? _apparentTemperature;
  int? _weatherCode;
  String _weatherDescription = 'Fetching…', _risk = '', _advice = '';
  Color _color = AppColors.info;
  IconData _icon = Icons.cloud_rounded;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    const lat = 16.4164;
    const lon = 120.5931;
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,apparent_temperature,weather_code&timezone=Asia%2FManila',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current'];
        setState(() {
          _temperature = (current['temperature_2m'] as num?)?.toDouble();
          _apparentTemperature = (current['apparent_temperature'] as num?)
              ?.toDouble();
          _weatherCode = current['weather_code'] as int?;
          _processWeatherData();
          _isLoading = false;
        });
      } else {
        _setFallbackData();
      }
    } catch (_) {
      _setFallbackData();
    }
  }

  void _setFallbackData() {
    setState(() {
      _isLoading = false;
      _temperature = null;
      _apparentTemperature = null;
      _weatherDescription = 'Weather unavailable';
      _processHistoricalData();
    });
  }

  void _processWeatherData() {
    switch (_weatherCode) {
      case 0:
        _weatherDescription = 'Clear Sky';
        break;
      case 1:
        _weatherDescription = 'Mainly Clear';
        break;
      case 2:
        _weatherDescription = 'Partly Cloudy';
        break;
      case 3:
        _weatherDescription = 'Overcast';
        break;
      case 45:
      case 48:
        _weatherDescription = 'Foggy';
        break;
      case 51:
      case 53:
      case 55:
        _weatherDescription = 'Drizzle';
        break;
      case 56:
      case 57:
        _weatherDescription = 'Freezing Drizzle';
        break;
      case 61:
        _weatherDescription = 'Slight Rain';
        break;
      case 63:
        _weatherDescription = 'Moderate Rain';
        break;
      case 65:
        _weatherDescription = 'Heavy Rain';
        break;
      case 66:
      case 67:
        _weatherDescription = 'Freezing Rain';
        break;
      case 71:
      case 73:
      case 75:
        _weatherDescription = 'Snowfall';
        break;
      case 77:
        _weatherDescription = 'Snow Grains';
        break;
      case 80:
      case 81:
      case 82:
        _weatherDescription = 'Rain Showers';
        break;
      case 85:
      case 86:
        _weatherDescription = 'Snow Showers';
        break;
      case 95:
      case 96:
      case 99:
        _weatherDescription = 'Thunderstorms';
        break;
      default:
        _weatherDescription = 'Varying Conditions';
    }

    if (_weatherCode! <= 3) {
      if (_temperature! > 24) {
        _risk = 'Heat Risk';
        _advice = 'Keep pets and humans hydrated. Avoid peak sun hours.';
        _color = AppColors.warning;
        _icon = Icons.wb_sunny_rounded;
      } else {
        _risk = 'Low Risk · Pleasant';
        _advice = 'Great weather for outdoor activities.';
        _color = AppColors.success;
        _icon = Icons.check_circle_rounded;
      }
    } else if (_weatherCode! >= 45 && _weatherCode! <= 48) {
      _risk = 'Mild Risk · Visibility';
      _advice = 'Ensure visibility near roads. Keep pets warm.';
      _color = AppColors.textSecondary;
      _icon = Icons.cloud_rounded;
    } else if ((_weatherCode! >= 51 && _weatherCode! <= 67) ||
        (_weatherCode! >= 80 && _weatherCode! <= 82)) {
      _risk = 'Rain Risk · Leptospirosis & Dengue';
      _advice = 'Warn about standing water. Lepto for pets, Dengue for humans.';
      _color = AppColors.info;
      _icon = Icons.water_drop_rounded;
    } else if (_weatherCode! >= 71 && _weatherCode! <= 77) {
      _risk = 'High Risk · Hypothermia';
      _advice = 'Provide warm bedding. Watch for joint pain.';
      _color = AppColors.primary;
      _icon = Icons.ac_unit_rounded;
    } else if (_weatherCode! >= 95) {
      _risk = 'High Risk · Storms';
      _advice = 'Keep pets inside. Use anxiety wraps if needed.';
      _color = AppColors.danger;
      _icon = Icons.thunderstorm_rounded;
    } else {
      _risk = 'Variable Risk';
      _advice = 'Monitor weather changes. Keep pets safe.';
      _color = AppColors.info;
      _icon = Icons.cloud_queue_rounded;
    }
  }

  void _processHistoricalData() {
    final int month = now.month;
    if (month >= 6 && month <= 10) {
      _weatherDescription = 'Rainy Season';
      _risk = 'High Risk · Leptospirosis & Dengue';
      _advice = 'Historical average: warn about standing water.';
      _color = AppColors.info;
      _icon = Icons.water_drop_rounded;
    } else if (month >= 11 || month <= 2) {
      _weatherDescription = 'Cold Season';
      _risk = 'High Risk · Respiratory';
      _advice = 'Historical average: relieve joint pain, prevent colds.';
      _color = AppColors.primary;
      _icon = Icons.ac_unit_rounded;
    } else {
      _weatherDescription = 'Dry Season';
      _risk = 'High Risk · Heatstroke';
      _advice = 'Historical average: keep cool and hydrated.';
      _color = AppColors.warning;
      _icon = Icons.wb_sunny_rounded;
    }
  }

  Map<String, String> _getMonthlyInsights() {
    final int month = now.month;
    String diseases = '';
    String stockUp = '';
    switch (month) {
      case 1:
      case 2:
        diseases = 'Canine Cough, Feline URI, Joint Pain (Seniors)';
        stockUp = 'Pet Sweaters, Vitamin C, Joint Supplements';
        break;
      case 3:
      case 4:
      case 5:
        diseases = 'Heatstroke, Rabies (Peak), Ticks & Fleas';
        stockUp = 'Hydration Salts, Tick/Flea Preventatives, Cooling Mats';
        break;
      case 6:
      case 7:
      case 8:
        diseases = 'Leptospirosis, Dengue, Parvovirus, Fungal Infections';
        stockUp = 'Anti-fungal Shampoos, Mosquito Repellents, Disinfectants';
        break;
      case 9:
      case 10:
      case 11:
        diseases = 'Leptospirosis (Typhoon), Gastrointestinal Issues';
        stockUp = 'Probiotics, Dewormers, First Aid Kits, Water Reserves';
        break;
      case 12:
        diseases = 'Stress/Anxiety (fireworks), Holiday Indigestion';
        stockUp = 'Calming Chews, Digestive Enzymes, Emergency Hotlines';
        break;
      default:
        diseases = 'General Routine Checkups';
        stockUp = 'Basic First Aid Supplies';
    }
    return {'diseases': diseases, 'stockUp': stockUp};
  }

  void _showForecastDetail() {
    final insights = _getMonthlyInsights();
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadii.rXl),
          backgroundColor: AppColors.surface,
          insetPadding: const EdgeInsets.all(AppSpacing.xxl),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconAvatar(icon: _icon, color: _color, size: 40),
                      AppSpacing.hMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _weatherDescription,
                              style: AppTypography.titleLarge,
                            ),
                            AppSpacing.vXs,
                            Text(
                              _temperature != null
                                  ? '${_temperature!.toStringAsFixed(1)}°C · Feels ${_apparentTemperature!.toStringAsFixed(1)}°C'
                                  : 'Local area',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vLg,
                  Text(
                    _risk,
                    style: AppTypography.titleSmall.copyWith(color: _color),
                  ),
                  AppSpacing.vSm,
                  Text(
                    _advice,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  AppSpacing.vXl,
                  const Divider(color: AppColors.divider, height: 1),
                  AppSpacing.vLg,
                  Text('This month', style: AppTypography.titleSmall),
                  AppSpacing.vSm,
                  Text(
                    'High-risk diseases',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  AppSpacing.vXs,
                  Text(insights['diseases']!, style: AppTypography.bodyMedium),
                  AppSpacing.vMd,
                  Text(
                    'Recommended stock',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  AppSpacing.vXs,
                  Text(insights['stockUp']!, style: AppTypography.bodyMedium),
                  AppSpacing.vLg,
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.infoSurface,
                      borderRadius: AppRadii.rMd,
                    ),
                    child: Text(
                      _temperature != null
                          ? 'Weather data from Open-Meteo for real-time risk assessment.'
                          : 'Unable to fetch live weather. Showing historical averages.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.info,
                        height: 1.5,
                      ),
                    ),
                  ),
                  AppSpacing.vLg,
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Close',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Shimmer.fromColors(
        baseColor: AppColors.surfaceAlt,
        highlightColor: AppColors.surface,
        child: Container(
          width: double.infinity,
          height: 140,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.rXl,
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadii.rXl,
      child: InkWell(
        borderRadius: AppRadii.rXl,
        onTap: _showForecastDetail,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_color.withOpacity(0.85), _color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppRadii.rXl,
            boxShadow: AppShadows.colored(_color),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_icon, color: Colors.white, size: 18),
                          ),
                          AppSpacing.hSm,
                          Flexible(
                            child: Text(
                              'CLINICAL FORECAST',
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _temperature != null
                          ? '${_temperature!.toStringAsFixed(1)}°C'
                          : '--',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                AppSpacing.vMd,
                Text(
                  _risk,
                  style: AppTypography.titleLarge.copyWith(color: Colors.white),
                ),
                AppSpacing.vSm,
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _advice,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          height: 1.4,
                        ),
                      ),
                    ),
                    AppSpacing.hSm,
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
