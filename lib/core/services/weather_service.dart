import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../di/injection.dart';

class WeatherInfo {
  final double maxTemp;
  final double minTemp;
  final String description;
  final String icon;
  final bool isRainy;

  WeatherInfo({
    required this.maxTemp,
    required this.minTemp,
    required this.description,
    required this.icon,
    required this.isRainy,
  });
}

class WeatherService {
  final Dio _dio;

  WeatherService({Dio? dio}) : _dio = dio ?? getIt<Dio>();

  /// Belirtilen koordinat ve tarihler için günlük hava durumu verilerini getirir.
  Future<Map<DateTime, WeatherInfo>> getForecastForDates({
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final formatter = DateFormat('yyyy-MM-dd');
      final startStr = formatter.format(startDate);
      final endStr = formatter.format(endDate);

      const url = 'https://api.open-meteo.com/v1/forecast';
      final response = await _dio.get(url, queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'start_date': startStr,
        'end_date': endStr,
        'daily': 'weathercode,temperature_2m_max,temperature_2m_min',
        'timezone': 'auto',
      });

      if (response.statusCode == 200 && response.data != null) {
        final daily = response.data['daily'];
        if (daily != null) {
          final times = List<String>.from(daily['time'] ?? []);
          final codes = List<num>.from(daily['weathercode'] ?? []);
          final maxTemps = List<num>.from(daily['temperature_2m_max'] ?? []);
          final minTemps = List<num>.from(daily['temperature_2m_min'] ?? []);

          final Map<DateTime, WeatherInfo> result = {};
          for (int i = 0; i < times.length; i++) {
            final date = DateTime.parse(times[i]);
            final code = codes[i].toInt();
            final maxT = maxTemps[i].toDouble();
            final minT = minTemps[i].toDouble();

            result[DateTime(date.year, date.month, date.day)] = _mapWeatherCode(code, maxT, minT);
          }
          return result;
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Hava durumu servisi hatası: $e');
    }

    // Hata durumunda veya verinin olmadığı durumlarda simüle edilmiş veriler dön (farklı günlerde güneşli/yağmurlu)
    return _generateFallbackForecast(startDate, endDate);
  }

  WeatherInfo _mapWeatherCode(int code, double maxTemp, double minTemp) {
    String description = 'Açık';
    String icon = '☀️';
    bool isRainy = false;

    switch (code) {
      case 0:
        description = 'Açık';
        icon = '☀️';
        break;
      case 1:
      case 2:
      case 3:
        description = 'Parçalı Bulutlu';
        icon = '⛅';
        break;
      case 45:
      case 48:
        description = 'Sisli';
        icon = '🌫️';
        break;
      case 51:
      case 53:
      case 55:
        description = 'Çiseleme';
        icon = '🌧️';
        isRainy = true;
        break;
      case 61:
      case 63:
      case 65:
        description = 'Yağmurlu';
        icon = '🌧️';
        isRainy = true;
        break;
      case 71:
      case 73:
      case 75:
        description = 'Karlı';
        icon = '❄️';
        break;
      case 80:
      case 81:
      case 82:
        description = 'Sağanak Yağışlı';
        icon = '🌦️';
        isRainy = true;
        break;
      case 95:
      case 96:
      case 99:
        description = 'Gök Gürültülü Fırtına';
        icon = '⛈️';
        isRainy = true;
        break;
      default:
        description = 'Açık';
        icon = '☀️';
    }

    return WeatherInfo(
      maxTemp: maxTemp,
      minTemp: minTemp,
      description: description,
      icon: icon,
      isRainy: isRainy,
    );
  }

  Map<DateTime, WeatherInfo> _generateFallbackForecast(DateTime start, DateTime end) {
    final Map<DateTime, WeatherInfo> fallback = {};
    DateTime current = DateTime(start.year, start.month, start.day);
    final stop = DateTime(end.year, end.month, end.day);

    while (current.isBefore(stop) || current.isAtSameMomentAs(stop)) {
      // Simülasyon: Geliştiricinin yağmur senaryolarını da test edebilmesi için her 4. gün yağmurlu döner
      final bool isRainyDay = (current.day % 4 == 0);
      fallback[current] = WeatherInfo(
        maxTemp: isRainyDay ? 17.0 : 25.0,
        minTemp: isRainyDay ? 11.0 : 16.0,
        description: isRainyDay ? 'Yağmurlu' : 'Güneşli',
        icon: isRainyDay ? '🌧️' : '☀️',
        isRainy: isRainyDay,
      );
      current = current.add(const Duration(days: 1));
    }
    return fallback;
  }
}
