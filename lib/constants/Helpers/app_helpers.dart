// utils/geo_helpers.dart
import 'dart:math';

double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
  const earthRadius = 6371; // Earth radius in kilometers

  double dLat = _toRadians(lat2 - lat1);
  double dLng = _toRadians(lng2 - lng1);

  double a = sin(dLat / 2) * sin(dLat / 2) + cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLng / 2) * sin(dLng / 2);

  double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadius * c;
}

double _toRadians(double degrees) {
  return degrees * pi / 180;
}

String formatDistance(double km) {
  if (km < 1) return '${(km * 1000).round()} m';
  return '${km.toStringAsFixed(1)} km';
}

String formatPrice(dynamic price, {String currencySymbol = '\$', int decimalDigits = 2}) {
  if (price == null || price.toString().isEmpty) return '$currencySymbol 0.00';

  final amount = (price is num) ? price : (num.tryParse(price.toString())) ?? 0;
  final fixed = amount.toStringAsFixed(decimalDigits);

  // Simplified formatting without regex
  final parts = fixed.split('.');
  String integerPart = parts[0];
  final decimalPart = parts.length > 1 ? parts[1] : '00';

  // Add thousands separators
  final buffer = StringBuffer();
  for (int i = 0; i < integerPart.length; i++) {
    if (i > 0 && (integerPart.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(integerPart[i]);
  }

  return '$currencySymbol${buffer.toString()}.$decimalPart';
}
