import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final LatLng _initialPosition = const LatLng(33.2075, -97.152613);
  final Set<Marker> _markers = {};
  BitmapDescriptor? _customIcon;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _loadCustomMarker();
    await _getUserLocation();
    await _loadMarkersFromJson();
  }

  Future<void> _loadCustomMarker() async {
    final ByteData byteData = await rootBundle.load('assets/trash-can.webp');
    final codec = await ui.instantiateImageCodec(
      byteData.buffer.asUint8List(),
      targetWidth: 64,
      targetHeight: 64,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final byteDataPng = await image.toByteData(format: ui.ImageByteFormat.png);
    final resizedBytes = byteDataPng!.buffer.asUint8List();

    _customIcon = BitmapDescriptor.fromBytes(resizedBytes);
  }

  Future<void> _getUserLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _markers.add(
          Marker(
            markerId: MarkerId("current_location"),
            position: _currentLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: InfoWindow(title: "You are here"),
          ),
        );
      });
    }
  }

  Future<void> _loadMarkersFromJson() async {
    final String jsonData = await rootBundle.loadString('assets/maps.json');
    final List<dynamic> bins = json.decode(jsonData);

    Set<Marker> loadedMarkers = bins.map((bin) {
      final lat = bin["Latitude"];
      final lng = bin["Longitude"];
      final name = bin["TrashCName"];
      final image = bin["Image"];
      final wasteType = bin["Waste-Stream"];
      final markerId = bin["S.N"].toString();

      final prefixEmoji = wasteType.toLowerCase().contains("recycle") ? "♻️" : "🗑️";
      final displayName = "$prefixEmoji $name";

      return Marker(
        markerId: MarkerId(markerId),
        position: LatLng(lat, lng),
        icon: _customIcon ?? BitmapDescriptor.defaultMarker,
        onTap: () {
          _showCustomInfoBottomSheet(context, displayName, wasteType, image, LatLng(lat, lng));
        },
      );
    }).toSet();

    setState(() {
      _markers.addAll(loadedMarkers);
    });
  }

  void _showCustomInfoBottomSheet(
      BuildContext context,
      String title,
      String wasteType,
      String imageUrl,
      LatLng binLocation,
      ) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        height: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(wasteType, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _showImageBottomSheet(context, imageUrl, title);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Text("📸 Click here to view image",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    Spacer(),
                    Icon(Icons.open_in_new),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: Icon(Icons.directions),
              label: Text("Get Directions"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                if (_currentLocation != null) {
                  final url = Uri.parse(
                    'https://www.google.com/maps/dir/?api=1'
                        '&origin=${_currentLocation!.latitude},${_currentLocation!.longitude}'
                        '&destination=${binLocation.latitude},${binLocation.longitude}'
                        '&travelmode=walking',
                  );
                  launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Current location unavailable")),
                  );
                }
              },
            )
          ],
        ),
      ),
    );
  }

  void _showImageBottomSheet(
      BuildContext context, String imageUrl, String title) {
    final filename = Uri.parse(imageUrl).pathSegments.last;
    final localPath = 'assets/maps/$filename.jpg';

    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  localPath,
                  width: MediaQuery.of(context).size.width,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 40),
                        SizedBox(height: 8),
                        Text("⚠️ Local image not found"),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Closest Recycle Bin")),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _currentLocation ?? _initialPosition,
          zoom: 15.0,
        ),
        myLocationEnabled: _currentLocation != null,
        myLocationButtonEnabled: true,
        markers: _markers,
      ),
    );
  }
}
