import 'package:flutter/material.dart';
import 'package:itantsoroka/l10n/app_localization.dart';

class ModernWeatherCard extends StatelessWidget {
  final Map<String, dynamic>? weatherData;
  final Map<String, dynamic> regionalFallback;
  final String selectedRegion;
  final List<String> availableRegions;
  final ValueChanged<String> onRegionChanged;
  final VoidCallback onGpsPressed;
  final VoidCallback onRefreshPressed;
  final bool isLoading;
  final String locationLabel;

  const ModernWeatherCard({
    super.key,
    required this.weatherData,
    required this.regionalFallback,
    required this.selectedRegion,
    required this.availableRegions,
    required this.onRegionChanged,
    required this.onGpsPressed,
    required this.onRefreshPressed,
    this.isLoading = false,
    this.locationLabel = '',
  });

  IconData _getWeatherIcon(dynamic weatherCode, String desc) {
    if (weatherCode is int) {
      if (weatherCode == 0 || weatherCode == 1) return Icons.wb_sunny_rounded;
      if (weatherCode == 2) return Icons.wb_cloudy_rounded;
      if (weatherCode == 3) return Icons.cloud_rounded;
      if (weatherCode >= 45 && weatherCode <= 48) return Icons.cloud_outlined;
      if (weatherCode >= 51 && weatherCode <= 67) return Icons.grain_outlined;
      if (weatherCode >= 80 && weatherCode <= 82) return Icons.water_drop_rounded;
      if (weatherCode >= 95) return Icons.thunderstorm_rounded;
    }
    final d = desc.toLowerCase();
    if (d.contains('pluie') || d.contains('averse') || d.contains('bruine')) return Icons.water_drop_rounded;
    if (d.contains('nuage') || d.contains('couvert')) return Icons.cloud_rounded;
    if (d.contains('orage')) return Icons.thunderstorm_rounded;
    if (d.contains('vent') || d.contains('brise')) return Icons.air_rounded;
    return Icons.wb_sunny_rounded;
  }

  String _formatWeatherSentence(String desc) {
    final d = desc.trim();
    if (d.isEmpty) return "Le temps est ensoleillé";
    final lower = d.toLowerCase();
    if (lower.startsWith('le temps est') || lower.startsWith('ciel')) {
      return d[0].toUpperCase() + d.substring(1);
    }
    return "Le temps est $lower";
  }

  List<Map<String, dynamic>> _getForecastList(num currentTemp, dynamic rawForecast) {
    if (rawForecast is List && rawForecast.isNotEmpty) {
      return rawForecast.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    // Generer un tableau 7 jours par défaut si pas encore de données de prévision
    final dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final now = DateTime.now();
    final baseTemp = currentTemp.toInt();
    final offsets = [0, 2, -1, 2, 1, 0, 2];

    return List.generate(7, (i) {
      final dt = now.add(Duration(days: i));
      return {
        'day': dayNames[dt.weekday - 1],
        'max': baseTemp + offsets[i % offsets.length],
        'min': baseTemp - 4,
        'code': 0,
        'desc': 'Ensoleillé',
      };
    });
  }

  @override
  Widget build(BuildContext context) {

    // Extrait les valeurs météo
    num tempNum = 24;
    String weatherDesc = regionalFallback['weather']?.toString() ?? 'Ensoleillé';
    String hum = regionalFallback['humi']?.toString() ?? '65%';
    String wind = regionalFallback['wind']?.toString() ?? '14 km/h';
    String pressure = '1013 hPa';
    String sunrise = '06:00';
    String sunset = '18:00';
    dynamic weatherCode;
    dynamic forecastData;

    if (weatherData != null) {
      if (weatherData!.containsKey('temp')) {
        tempNum = (weatherData!['temp'] as num?) ?? tempNum;
      }
      if (weatherData!.containsKey('weather_desc')) {
        weatherDesc = weatherData!['weather_desc']?.toString() ?? weatherDesc;
      }
      if (weatherData!.containsKey('humidity')) hum = '${weatherData!['humidity']}%';
      if (weatherData!.containsKey('wind_speed')) wind = '${weatherData!['wind_speed']} km/h';
      if (weatherData!.containsKey('pressure')) pressure = '${weatherData!['pressure']} hPa';
      if (weatherData!.containsKey('sunrise')) sunrise = weatherData!['sunrise']?.toString() ?? sunrise;
      if (weatherData!.containsKey('sunset')) sunset = weatherData!['sunset']?.toString() ?? sunset;
      if (weatherData!.containsKey('weather_code')) weatherCode = weatherData!['weather_code'];
      if (weatherData!.containsKey('forecast7Days')) forecastData = weatherData!['forecast7Days'];
    }

    final weatherIcon = _getWeatherIcon(weatherCode, weatherDesc);
    final forecastList = _getForecastList(tempNum, forecastData);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1E5298),
            Color(0xFF3B7BBF),
            Color(0xFF5A9BE0),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E5298).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Décoration d'arrière-plan avec nuages doux
            Positioned(
              top: -20,
              right: -30,
              child: Icon(
                Icons.cloud_rounded,
                size: 200,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -40,
              child: Icon(
                Icons.cloud_rounded,
                size: 220,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(isMobile ? 18.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // En-tête : Titre + Sélecteur de région (Responsive sans débordement)
                  isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          context.tr('meteo_du_jour'),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 0.3,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.my_location_rounded, color: Colors.amberAccent, size: 20),
                                      tooltip: context.tr('tooltip_gps'),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                      onPressed: onGpsPressed,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                                      tooltip: context.tr('tooltip_refresh'),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                      onPressed: onRefreshPressed,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: availableRegions.contains(selectedRegion) ? selectedRegion : availableRegions.first,
                                  dropdownColor: const Color(0xFF1E293B),
                                  isExpanded: true,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 20),
                                  items: availableRegions
                                      .map(
                                        (reg) => DropdownMenuItem<String>(
                                          value: reg,
                                          child: Text(
                                            reg,
                                            style: const TextStyle(color: Colors.white, fontSize: 13),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) onRegionChanged(v);
                                  },
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        context.tr('meteo_du_jour'),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (locationLabel.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      locationLabel,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.75),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: availableRegions.contains(selectedRegion) ? selectedRegion : availableRegions.first,
                                      dropdownColor: const Color(0xFF1E293B),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
                                      items: availableRegions
                                          .map(
                                            (reg) => DropdownMenuItem<String>(
                                              value: reg,
                                              child: Text(
                                                reg,
                                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) {
                                        if (v != null) onRegionChanged(v);
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  icon: const Icon(Icons.my_location_rounded, color: Colors.amberAccent, size: 20),
                                  tooltip: context.tr('tooltip_gps'),
                                  onPressed: onGpsPressed,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                                  tooltip: context.tr('tooltip_refresh'),
                                  onPressed: onRefreshPressed,
                                ),
                              ],
                            ),
                          ],
                        ),

                  const SizedBox(height: 20),

                  // Affichage principal de la météo (Grandes dimensions style moderne)
                  if (isLoading)
                    const SizedBox(
                      height: 140,
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    )
                  else
                    Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Température
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${tempNum.round()}',
                                  style: TextStyle(
                                    fontSize: isMobile ? 54 : 64,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1.0,
                                  ),
                                ),
                                Text(
                                  '°',
                                  style: TextStyle(
                                    fontSize: isMobile ? 36 : 44,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            // Subtitle "Aujourd'hui"
                            Text(
                              "Aujourd'hui",
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),

                            // Weather sentence "Le temps est ..."
                            Text(
                              _formatWeatherSentence(weatherDesc),
                              style: TextStyle(
                                fontSize: isMobile ? 22 : 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),

                        // Icone Météo illustrée sur la droite
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                            child: Icon(
                              weatherIcon,
                              size: isMobile ? 48 : 64,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // CARTE : Prévision météo à 7 jours avec courbe fluide
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Prévision météo à 7 jours",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Graphique Sparkline des températures sur 7 jours
                        SizedBox(
                          height: 54,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: WeatherSparklinePainter(
                              temps: forecastList.map((e) => (e['max'] as num).toDouble()).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Jours et températures sous le graphique
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: forecastList.map((f) {
                            return Expanded(
                              child: Column(
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      f['day']?.toString() ?? '',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withValues(alpha: 0.85),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '${f['max']}°',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Ligne de détails secondaires (Humidité, Vent, Pression, Levé/Couché)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _WeatherDetailItem(
                            icon: Icons.water_drop_outlined,
                            label: context.tr('humidite'),
                            value: hum,
                          ),
                        ),
                        Expanded(
                          child: _WeatherDetailItem(
                            icon: Icons.air_rounded,
                            label: context.tr('vent'),
                            value: wind,
                          ),
                        ),
                        Expanded(
                          child: _WeatherDetailItem(
                            icon: Icons.compress_rounded,
                            label: context.tr('pression'),
                            value: pressure,
                          ),
                        ),
                        Expanded(
                          child: _WeatherDetailItem(
                            icon: Icons.wb_twilight_rounded,
                            label: 'Soleil',
                            value: '$sunrise / $sunset',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Emplacement bas : "Region Name, Madagascar"
                  Center(
                    child: Text(
                      "$selectedRegion, Madagascar",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 0.5,
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

class _WeatherDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WeatherDetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// CustomPainter pour tracer la courbe fluide et élégante de la prévision météo à 7 jours
class WeatherSparklinePainter extends CustomPainter {
  final List<double> temps;

  WeatherSparklinePainter({required this.temps});

  @override
  void paint(Canvas canvas, Size size) {
    if (temps.isEmpty) return;

    final double minT = temps.reduce((a, b) => a < b ? a : b);
    final double maxT = temps.reduce((a, b) => a > b ? a : b);
    final double range = (maxT - minT) == 0 ? 1 : (maxT - minT);

    final double paddingY = 8.0;
    final double availHeight = size.height - (paddingY * 2);
    final double stepX = size.width / (temps.length - 1);

    List<Offset> points = [];
    for (int i = 0; i < temps.length; i++) {
      final x = i * stepX;
      // Inverser Y pour que la temp maximale soit en haut
      final normY = (temps[i] - minT) / range;
      final y = size.height - paddingY - (normY * availHeight);
      points.add(Offset(x, y));
    }

    // Trace la ligne avec des segments lisses
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // Peinture de la ligne de courbe
    final strokePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);

    // Dessine les nœuds (points)
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final dotOutlinePaint = Paint()
      ..color = const Color(0xFF1E5298)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final p in points) {
      canvas.drawCircle(p, 4.0, dotPaint);
      canvas.drawCircle(p, 4.0, dotOutlinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant WeatherSparklinePainter oldDelegate) {
    return oldDelegate.temps != temps;
  }
}
