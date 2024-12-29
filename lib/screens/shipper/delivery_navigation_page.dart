import 'package:flutter/material.dart';
import 'package:vietmap_flutter_navigation/vietmap_flutter_navigation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DeliveryNavigationPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const DeliveryNavigationPage({Key? key, required this.order})
      : super(key: key);

  @override
  _DeliveryNavigationPageState createState() => _DeliveryNavigationPageState();
}

class _DeliveryNavigationPageState extends State<DeliveryNavigationPage> {
  late MapOptions _navigationOption;
  final _vietmapNavigationPlugin = VietMapNavigationPlugin();
  MapNavigationViewController? _navigationController;

  Widget instructionImage = const SizedBox.shrink();
  Widget recenterButton = const SizedBox.shrink();
  RouteProgressEvent? routeProgressEvent;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    if (!mounted) return;
    _navigationOption = _vietmapNavigationPlugin.getDefaultOptions();
    _navigationOption.simulateRoute = false;
    _navigationOption.apiKey =
        '6e0f9ec74dcf745f6a0a071f50c2479030322f17f879d547';
    _navigationOption.mapStyle =
        "https://maps.vietmap.vn/api/maps/light/styles.json?apikey=6e0f9ec74dcf745f6a0a071f50c2479030322f17f879d547";

    _vietmapNavigationPlugin.setDefaultOptions(_navigationOption);

    // Delay navigation start
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkPermissionAndStartNavigation();
    });
  }

  Future<void> _checkPermissionAndStartNavigation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      final position = await Geolocator.getCurrentPosition();
      _buildRouteWithWaypoints(LatLng(position.latitude, position.longitude));
    }
  }

  Future<void> _addMarkers() async {
    final storeLatLng = LatLng(
      double.parse(widget.order['store_latitude'].toString()),
      double.parse(widget.order['store_longitude'].toString())
    );
    
    final destinationLatLng = LatLng(
      double.parse(widget.order['latitude'].toString()),
      double.parse(widget.order['longitude'].toString())
    );

    // Add store marker with red icon
    await _navigationController?.addImageMarkers([
      NavigationMarker(
        imagePath: 'assets/store_marker.png', // Add this image to assets
        latLng: storeLatLng,
        width: 48,
        height: 48,
      ),
      NavigationMarker(
        imagePath: 'assets/destination_marker.png', // Add this image to assets 
        latLng: destinationLatLng,
        width: 48,
        height: 48,
      ),
    ]);
  }

  void _buildRouteWithWaypoints(LatLng currentLocation) {
    final deliveryLatLng = LatLng(
        double.parse(widget.order['latitude'].toString()),
        double.parse(widget.order['longitude'].toString()));

    final storeLatLng = LatLng(
        double.parse(widget.order['store_latitude'].toString()),
        double.parse(widget.order['store_longitude'].toString()));

    _navigationController?.buildAndStartNavigation(
      waypoints: [currentLocation, deliveryLatLng, storeLatLng],
      profile: DrivingProfile.drivingTraffic,
    ).then((_) => _addMarkers());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          NavigationView(
            mapOptions: _navigationOption,
            onMapCreated: (controller) {
              _navigationController = controller;
            },
            onRouteProgressChange: (RouteProgressEvent event) {
              setState(() {
                routeProgressEvent = event;
              });
            },
            onMapRendered: () {
              setState(() {
                recenterButton = IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: () => _navigationController?.recenter(),
                );
              });
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: BannerInstructionView(
              routeProgressEvent: routeProgressEvent,
              instructionIcon: instructionImage,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomActionView(
              recenterButton: recenterButton,
              controller: _navigationController,
              routeProgressEvent: routeProgressEvent,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _navigationController?.onDispose();
    super.dispose();
  }
}
