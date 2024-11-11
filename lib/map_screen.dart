import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart'
    as cluster_manager;

// Custom class implementing ClusterItem
class MyClusterItem with cluster_manager.ClusterItem {
  final LatLng _location;

  MyClusterItem(this._location);

  @override
  LatLng get location =>
      this._location; // Provide the location getter for clustering
}

class MapSample extends StatefulWidget {
  const MapSample({super.key});

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  late cluster_manager.ClusterManager _clusterManager;
  final List<MyClusterItem> _items = []; // Using custom class for cluster items

  // Initial camera position focused on Alberta, Canada
  static const CameraPosition _kAlberta = CameraPosition(
    target: LatLng(53.9333, -116.5765), // Approximate center of Alberta, Canada
    zoom: 5.0,
  );

  @override
  void initState() {
    super.initState();
    _generateClusterItems();
    _clusterManager = cluster_manager.ClusterManager<MyClusterItem>(
        _items, _updateMarkers,
        markerBuilder: _markerBuilder);
  }

  // Function to generate random cluster items around Alberta
  void _generateClusterItems() {
    final Random random = Random();
    const double minLat = 48.0; // Southern border of Alberta
    const double maxLat = 60.0; // Northern border of Alberta
    const double minLng = -120.0; // Western border of Alberta
    const double maxLng = -110.0; // Eastern border of Alberta

    for (int i = 0; i < 1000; i++) {
      final double randomLat = minLat + random.nextDouble() * (maxLat - minLat);
      final double randomLng = minLng + random.nextDouble() * (maxLng - minLng);

      _items.add(MyClusterItem(
          LatLng(randomLat, randomLng))); // Use custom class for ClusterItem
    }
  }

  // Function to build a cluster marker or a single marker
  Future<Marker> Function(dynamic) get _markerBuilder =>
      (dynamic cluster) async {
        final clusterTyped = cluster as cluster_manager.Cluster<MyClusterItem>;

        return Marker(
          markerId: MarkerId(clusterTyped.isMultiple
              ? 'cluster_${clusterTyped.count}'
              : 'marker_${clusterTyped.items.first.location.toString()}'),
          position: clusterTyped.location,
          infoWindow: clusterTyped.isMultiple
              ? InfoWindow(title: 'Cluster with ${clusterTyped.count} markers')
              : InfoWindow(
                  title:
                      'Marker at ${clusterTyped.location.latitude}, ${clusterTyped.location.longitude}'),
          icon: await _getMarkerIcon(
              clusterTyped.isMultiple ? clusterTyped.count.toString() : '1',
              Colors.blue),
        );
      };

  // Function to update markers on the map
  void _updateMarkers(Set<Marker> markers) {
    setState(() {
      _markers = markers;
    });
  }

  // Function to create a custom marker icon for clusters
  Future<BitmapDescriptor> _getMarkerIcon(String text, Color color) async {
    // Generate a custom marker icon based on text (e.g., number of items in cluster)
    // For simplicity, return the default marker icon. You can customize this with images or text.
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
  }

  Set<Marker> _markers = {}; // Set to hold the markers

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map Sample with Marker Clustering')),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _kAlberta,
        markers: _markers, // Display the clustered markers
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
          _clusterManager
              .setMapId(controller.mapId); // Link cluster manager to the map
        },
        onCameraMove:
            _clusterManager.onCameraMove, // Update clusters on camera move
        onCameraIdle:
            _clusterManager.updateMap, // Update clusters on camera idle
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(home: MapSample()));
}
