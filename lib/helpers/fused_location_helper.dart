import 'package:geolocator/geolocator.dart';

class FusedLocationHelper {
  Future<Position?> getCurrentLocation() async {
    bool permissionAllowed = await _checkPermission();
    if (!permissionAllowed) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<bool> _checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}
