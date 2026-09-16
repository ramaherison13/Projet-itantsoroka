import 'dart:convert';
import 'dart:io' show File, Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class WeatherService {
  // Region coordinates for Madagascar (Chef-lieu coordinates for each region)
  static const Map<String, Map<String, double>> regionCoordinates = {
    'Analamanga': {'lat': -18.8792, 'lon': 47.5079},
    'Vakinankaratra': {'lat': -19.8659, 'lon': 47.0333},
    'Itasy': {'lat': -19.0000, 'lon': 46.9167},
    'Bongolava': {'lat': -18.7667, 'lon': 46.0500},
    'Atsinanana': {'lat': -18.1492, 'lon': 49.4023},
    'Analanjirofo': {'lat': -17.3500, 'lon': 49.4167},
    'Alaotra-Mangoro': {'lat': -17.8333, 'lon': 48.4167},
    'Boeny': {'lat': -15.7167, 'lon': 46.3167},
    'Sofia': {'lat': -14.8796, 'lon': 47.9875},
    'Betsiboka': {'lat': -16.9500, 'lon': 46.8333},
    'Melaky': {'lat': -18.0667, 'lon': 44.0167},
    'Diana': {'lat': -12.2787, 'lon': 49.2917},
    'Sava': {'lat': -14.2667, 'lon': 50.1667},
    'Haute Matsiatra': {'lat': -21.4527, 'lon': 47.0858},
    'Amoron\'i Mania': {'lat': -20.5333, 'lon': 47.2500},
    'Vatovavy': {'lat': -21.2333, 'lon': 48.3333},
    'Fitovinany': {'lat': -22.1500, 'lon': 48.0167},
    'Atsimo-Atsinanana': {'lat': -22.8167, 'lon': 47.8333},
    'Ihorombe': {'lat': -22.4000, 'lon': 46.1167},
    'Menabe': {'lat': -20.2833, 'lon': 44.2833},
    'Atsimo-Andrefana': {'lat': -23.3500, 'lon': 43.6667},
    'Androy': {'lat': -25.1833, 'lon': 46.0833},
    'Anosy': {'lat': -25.0333, 'lon': 46.9833},
  };

  // Find nearest Madagascar region for given lat & lon
  static String getNearestRegionName(double lat, double lon) {
    double minDistance = double.infinity;
    String nearestRegion = 'Analamanga';
    regionCoordinates.forEach((region, coords) {
      final double rLat = coords['lat']!;
      final double rLon = coords['lon']!;
      final double dist = (lat - rLat) * (lat - rLat) + (lon - rLon) * (lon - rLon);
      if (dist < minDistance) {
        minDistance = dist;
        nearestRegion = region;
      }
    });
    return nearestRegion;
  }

  // Try to read API key from environment or .env file in project root
  static Future<String?> _readApiKey() async {
    try {
      if (!kIsWeb) {
        final envKey = Platform.environment['OPENWEATHER_API_KEY'];
        if (envKey != null && envKey.isNotEmpty) return envKey;
        final envFile = File('.env');
        if (await envFile.exists()) {
          final lines = await envFile.readAsLines();
          for (final l in lines) {
            final parts = l.split('=');
            if (parts.length >= 2 && parts[0].trim() == 'OPENWEATHER_API_KEY') {
              return parts.sublist(1).join('=').trim();
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  // Fallback IP geolocation if device GPS is not available
  static Future<Map<String, dynamic>?> ipGeolocation() async {
    try {
      final res = await http.get(Uri.parse('https://ipapi.co/json')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) return json.decode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    try {
      final res2 = await http.get(Uri.parse('https://ipinfo.io/json')).timeout(const Duration(seconds: 4));
      if (res2.statusCode == 200) return json.decode(res2.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  // WMO Weather code descriptions in French
  static String getWeatherDescription(int code) {
    switch (code) {
      case 0:
        return 'Ciel dégagé';
      case 1:
        return 'Ensoleillé';
      case 2:
        return 'Partiellement nuageux';
      case 3:
        return 'Ciel couvert';
      case 45:
      case 48:
        return 'Brouillard';
      case 51:
      case 53:
      case 55:
        return 'Bruine légère';
      case 56:
      case 57:
        return 'Bruine verglacée';
      case 61:
        return 'Pluie légère';
      case 63:
        return 'Pluie modérée';
      case 65:
        return 'Pluie forte';
      case 66:
      case 67:
        return 'Pluie verglaçante';
      case 71:
      case 73:
      case 75:
      case 77:
        return 'Neige';
      case 80:
      case 81:
      case 82:
        return 'Averses de pluie';
      case 85:
      case 86:
        return 'Averses de neige';
      case 95:
        return 'Orage';
      case 96:
      case 99:
        return 'Orage avec grêle';
      default:
        return 'Ensoleillé';
    }
  }

  // Main weather fetcher (Uses Open-Meteo free API with OpenWeather fallback)
  static Future<Map<String, dynamic>?> getWeatherForCoords(double lat, double lon) async {
    // 1. Try Open-Meteo (Free, No Key Required)
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,wind_direction_10m,surface_pressure'
        '&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset'
        '&timezone=auto'
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final current = data['current'] as Map<String, dynamic>? ?? {};
        final daily = data['daily'] as Map<String, dynamic>? ?? {};

        final code = (current['weather_code'] as num?)?.toInt() ?? 0;
        final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 0.0;
        final humidity = (current['relative_humidity_2m'] as num?)?.toInt() ?? 0;
        final windSp = (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0;
        final windDeg = (current['wind_direction_10m'] as num?)?.toInt() ?? 0;
        final pressure = (current['surface_pressure'] as num?)?.round() ?? 1013;

        final maxTempList = (daily['temperature_2m_max'] as List?) ?? [];
        final minTempList = (daily['temperature_2m_min'] as List?) ?? [];
        final sunriseList = (daily['sunrise'] as List?) ?? [];
        final sunsetList = (daily['sunset'] as List?) ?? [];

        final maxTemp = maxTempList.isNotEmpty ? (maxTempList.first as num).toDouble() : temp;
        final minTemp = minTempList.isNotEmpty ? (minTempList.first as num).toDouble() : temp;

        String sunriseStr = '06:00';
        if (sunriseList.isNotEmpty && sunriseList.first != null) {
          final s = sunriseList.first.toString();
          if (s.contains('T')) sunriseStr = s.split('T').last;
        }

        String sunsetStr = '18:00';
        if (sunsetList.isNotEmpty && sunsetList.first != null) {
          final s = sunsetList.first.toString();
          if (s.contains('T')) sunsetStr = s.split('T').last;
        }
        final weatherDesc = getWeatherDescription(code);

        final timeList = (daily['time'] as List?) ?? [];
        final codeList = (daily['weather_code'] as List?) ?? [];

        List<Map<String, dynamic>> forecast7Days = [];
        final dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

        for (int i = 0; i < 7; i++) {
          DateTime dt;
          if (i < timeList.length && timeList[i] != null) {
            dt = DateTime.tryParse(timeList[i].toString()) ?? DateTime.now().add(Duration(days: i));
          } else {
            dt = DateTime.now().add(Duration(days: i));
          }
          final String dLabel = dayNames[dt.weekday - 1];
          final int maxT = (i < maxTempList.length && maxTempList[i] != null) ? (maxTempList[i] as num).round() : (temp.round() + (i % 3 == 0 ? 2 : (i % 2 == 0 ? -1 : 1)));
          final int minT = (i < minTempList.length && minTempList[i] != null) ? (minTempList[i] as num).round() : (temp.round() - 4);
          final int wCode = (i < codeList.length && codeList[i] != null) ? (codeList[i] as num).toInt() : code;

          forecast7Days.add({
            'day': dLabel,
            'max': maxT,
            'min': minT,
            'code': wCode,
            'desc': getWeatherDescription(wCode),
          });
        }

        return {
          'source': 'open-meteo',
          'temp': temp.round(),
          'temp_exact': temp,
          'temp_min': minTemp.round(),
          'temp_max': maxTemp.round(),
          'humidity': humidity,
          'wind_speed': windSp.round(),
          'wind_deg': windDeg,
          'pressure': pressure,
          'weather_code': code,
          'weather_desc': weatherDesc,
          'sunrise': sunriseStr,
          'sunset': sunsetStr,
          'forecast7Days': forecast7Days,
          'current': {
            'temp': temp.round(),
            'humidity': humidity,
            'wind_speed': windSp.round(),
            'wind_deg': windDeg,
            'pressure': pressure,
            'sunrise': sunriseStr,
            'sunset': sunsetStr,
            'visibility': 10000,
            'weather': [
              {'description': weatherDesc, 'main': weatherDesc}
            ],
          },
          'daily': [
            {
              'temp': {'min': minTemp.round(), 'max': maxTemp.round()},
              'sunrise': sunriseStr,
              'sunset': sunsetStr,
              'moonrise': 'N/A',
              'moonset': 'N/A',
            }
          ]
        };
      }
    } catch (_) {}

    // 2. OpenWeather Fallback if key available
    final key = await _readApiKey();
    if (key != null && key.isNotEmpty) {
      final uri = Uri.https('api.openweathermap.org', '/data/2.5/onecall', {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'exclude': 'minutely,hourly,alerts',
        'units': 'metric',
        'appid': key,
        'lang': 'fr',
      });
      try {
        final res = await http.get(uri).timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          final data = json.decode(res.body) as Map<String, dynamic>;
          final current = data['current'] as Map<String, dynamic>? ?? {};
          final daily = (data['daily'] as List?) ?? [];
          return {
            'source': 'open-weather',
            'current': current,
            'daily': daily,
            'raw': data,
          };
        }
      } catch (_) {}
    }

    return null;
  }
}
