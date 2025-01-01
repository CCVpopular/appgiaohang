import 'package:flutter/material.dart';
import 'package:vietmap_flutter_navigation/vietmap_flutter_navigation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';

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

  // Add new state variables
  static const double STORE_PROXIMITY_THRESHOLD = 100; // meters
  bool _isNavigatingToStore = true;
  LatLng? _storeLatLng;
  LatLng? _customerLatLng;
  Timer? _locationCheckTimer;

  @override
  void initState() {
    super.initState();
    initialize();
    _checkLocationPermission().then((_) {
      _initializeCoordinates();
    });
  }

  Future<void> initialize() async {
    if (!mounted) return;

    _navigationOption = MapOptions(
      apiKey: '6e0f9ec74dcf745f6a0a071f50c2479030322f17f879d547',
      mapStyle: "https://maps.vietmap.vn/api/maps/light/styles.json?apikey=6e0f9ec74dcf745f6a0a071f50c2479030322f17f879d547",
      simulateRoute: false, 
      enableRefresh: true,
      isOptimized: true,
    );
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }
  }

  Future<void> _initializeCoordinates() async {
    _storeLatLng = LatLng(
      double.parse(widget.order['store_latitude'].toString()),
      double.parse(widget.order['store_longitude'].toString())
    );
    
    _customerLatLng = LatLng(
      double.parse(widget.order['latitude'].toString()),
      double.parse(widget.order['longitude'].toString())
    );

    // Start location monitoring
    _startLocationMonitoring();
  }

  void _startLocationMonitoring() {
    _locationCheckTimer?.cancel();
    _locationCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!_isNavigatingToStore) return; // Only check while navigating to store
      
      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      double distanceToStore = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        _storeLatLng!.latitude,
        _storeLatLng!.longitude
      );

      if (distanceToStore <= STORE_PROXIMITY_THRESHOLD) {
        _isNavigatingToStore = false;
        _showCustomerRoute(LatLng(currentPosition.latitude, currentPosition.longitude));
      }
    });
  }

  Future<void> _addMarkers(LatLng storeLatLng, LatLng customerLatLng) async {
    await _navigationController?.addImageMarkers([
      NavigationMarker(
        imagePath: 'assets/store_marker.png',
        latLng: storeLatLng,
        width: 48,
        height: 48,
      ),
      NavigationMarker(
        imagePath: 'assets/customer_marker.png',
        latLng: customerLatLng, 
        width: 48,
        height: 48,
      ),
    ]);
  }

  Future<void> _showStoreToCustomerRoute() async {
    Position currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );
    
    final userLatLng = LatLng(
      currentPosition.latitude,
      currentPosition.longitude,
    );

    // Initially show route to store
    await _showStoreRoute(userLatLng);
    
    // Add markers for both destinations
    if (_storeLatLng != null && _customerLatLng != null) {
      await _addMarkers(_storeLatLng!, _customerLatLng!);
    }
  }

  Future<void> _showStoreRoute(LatLng userLatLng) async {
    if (_storeLatLng == null) return;
    
    await _navigationController?.buildAndStartNavigation(
      waypoints: [
        userLatLng,
        _storeLatLng!,
      ],
      profile: DrivingProfile.motorcycle,
    );
  }

  Future<void> _showCustomerRoute(LatLng currentLocation) async {
    if (_customerLatLng == null) return;
    
    await _navigationController?.buildAndStartNavigation(
      waypoints: [
        currentLocation,
        _customerLatLng!,
      ],
      profile: DrivingProfile.motorcycle,
    );
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
            onMapRendered: () async {
              // Show store to customer route when map is ready 
              await _showStoreToCustomerRoute();
            },
            onRouteProgressChange: (RouteProgressEvent event) {
              setState(() {
                routeProgressEvent = event;
              });
              _setInstructionImage(event.currentModifier, event.currentModifierType);
            },
          ),

          // Navigation instruction banner
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: BannerInstructionView(
              routeProgressEvent: routeProgressEvent,
              instructionIcon: instructionImage,
            ),
          ),

          // Control buttons
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'recenter',
                  onPressed: () => _navigationController?.recenter(),
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'overview',
                  onPressed: () => _navigationController?.overview(),
                  child: const Icon(Icons.map_outlined), 
                ),
              ],
            ),
          ),

          // Navigation info panel
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

  void _setInstructionImage(String? modifier, String? type) {
    if (modifier != null && type != null) {
      List<String> data = [
        type.replaceAll(' ', '_'),
        modifier.replaceAll(' ', '_')
      ];
      String path = 'assets/navigation_symbol/${data.join('_')}.svg';
      setState(() {
        instructionImage = SvgPicture.asset(path, color: Colors.white);
      });
    }
  }

  @override
  void dispose() {
    _locationCheckTimer?.cancel();
    _navigationController?.onDispose();
    super.dispose();
  }
}
