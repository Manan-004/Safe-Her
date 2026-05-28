import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:permission_handler/permission_handler.dart';

class SafePlacesPage extends StatefulWidget {
  const SafePlacesPage({super.key});

  @override
  State<SafePlacesPage> createState() => _SafePlacesPageState();
}

class _SafePlacesPageState extends State<SafePlacesPage> {
  late MapController mapController;

  double currentLat = 0.0;
  double currentLon = 0.0;

  @override
  void initState() {
    super.initState();

    mapController = MapController(
      initPosition: GeoPoint(
        latitude: 0,
        longitude: 0,
      ),
    );

    requestLocationPermission();
  }

  Future<void> requestLocationPermission() async {
    var status = await Permission.location.request();

    if (status.isGranted) {
      liveLocation();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission denied")),
      );
    }
  }

  Future<void> liveLocation() async {
    try {
      GeoPoint userLocation = await mapController.myLocation();

      currentLat = userLocation.latitude;
      currentLon = userLocation.longitude;

      await mapController.changeLocation(
        GeoPoint(latitude: currentLat, longitude: currentLon),
      );

      await mapController.setZoom(zoomLevel: 15);

      await mapController.addMarker(
        GeoPoint(latitude: currentLat, longitude: currentLon),
        markerIcon: const MarkerIcon(
          iconWidget: Icon(
            Icons.my_location,
            size: 48,
            color: Colors.blue,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          OSMFlutter(
            controller: mapController,
            osmOption: OSMOption(
              showDefaultInfoWindow: true,
              zoomOption: const ZoomOption(initZoom: 12),
              enableRotationByGesture: true,
              userLocationMarker: UserLocationMaker(
                personMarker: MarkerIcon(
                  icon: Icon(
                    Icons.person_pin_circle,
                    color: Colors.blue.shade700,
                    size: 48,
                  ),
                ),
                directionArrowMarker: const MarkerIcon(
                  icon: Icon(
                    Icons.navigation,
                    size: 48,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ),

          // TOP HEADER
          Container(
            height: 56,
            width: double.infinity,
            color: const Color(0xFFFFC3D7),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: const Icon(Icons.arrow_back, size: 28),
                  ),
                ),
                const Spacer(),
                const Text(
                  "Safe",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF69B4)),
                ),
                const SizedBox(width: 4),
                const Text(
                  "Places",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE6E6FA)),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
