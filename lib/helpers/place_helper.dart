import 'dart:convert';
import 'package:http/http.dart' as http;

class Place {
  final String name;
  final double lat;
  final double lon;

  Place({required this.name, required this.lat, required this.lon});
}

class PlaceHelper {
  final double lat;
  final double lon;
  final String keyword;
  final Function(List<Place>?) callback;

  PlaceHelper({
    required this.lat,
    required this.lon,
    required this.keyword,
    required this.callback,
  });

  Future<void> fetchNearbyPlaces() async {
    try {
      final url =
          "https://nominatim.openstreetmap.org/search?format=json&q=${keyword}+near+$lat,$lon&limit=10";

      final response = await http.get(
        Uri.parse(url),
        headers: {"User-Agent": "SafeHerApp"},
      );

      final jsonArray = jsonDecode(response.body);

      List<Place> list = [];

      for (var obj in jsonArray) {
        list.add(
          Place(
            name: obj["display_name"] ?? "Unknown",
            lat: double.parse(obj["lat"]),
            lon: double.parse(obj["lon"]),
          ),
        );
      }

      callback(list);
    } catch (e) {
      callback(null);
    }
  }
}
