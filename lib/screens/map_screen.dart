import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final LatLng _initialPosition =
      const LatLng(32.7304, -97.1152); // UTA default location

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
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
        initialCameraPosition: const CameraPosition(
          target: LatLng(33.253801237793695, -97.15260379334741),
          zoom: 15.0,
        ),
        markers: {
          const Marker(
            markerId: MarkerId("recycle_bin_1"),
            position: LatLng(33.2107, -97.1473),
            infoWindow: InfoWindow(
              title: "UNT Union Test Recycle Bin",
              snippet: "♻️ Bin Size: Large | Accepts: Plastic (Separate)",
            ),
          ),
        },
      ),
    );
  }
}
