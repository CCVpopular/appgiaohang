import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:vietmap_flutter_navigation/vietmap_flutter_navigation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

import '../../config/config.dart';
import '../../providers/auth_provider.dart';

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

  static const double STORE_PROXIMITY_THRESHOLD = 100; // meters
  static const double DESTINATION_PROXIMITY_THRESHOLD = 100; // meters
  bool _isNavigatingToStore = true;
  LatLng? _storeLatLng;
  LatLng? _customerLatLng;
  Timer? _locationCheckTimer;
  bool _showStartDeliveryButton = false;
  bool _showProximityOverlay = false;
  String _proximityMessage = '';

  @override
  void initState() {
    super.initState();
    initialize();
    _checkLocationPermission().then((_) async {
      await _initializeCoordinates();
      // Set navigation state based on order status
      setState(() {
        _isNavigatingToStore = widget.order['status'] != 'delivering';
      });
    });
  }

  Future<void> initialize() async {
    if (!mounted) return;

    _navigationOption = MapOptions(
      apiKey: Config.mapapi,
      mapStyle:
          "https://maps.vietmap.vn/api/maps/light/styles.json?apikey=${Config.mapapi}",
      simulateRoute: false,
      enableRefresh: true,
      isOptimized: true,
      voiceInstructionsEnabled: false,
      allowsUTurnAtWayPoints: true,
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
        double.parse(widget.order['store_longitude'].toString()));

    _customerLatLng = LatLng(double.parse(widget.order['latitude'].toString()),
        double.parse(widget.order['longitude'].toString()));

    // Get current position
    Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    final currentLatLng = LatLng(
      currentPosition.latitude,
      currentPosition.longitude,
    );

    // Show route based on order status
    if (widget.order['status'] == 'delivering') {
      await _showCustomerRoute(currentLatLng);
    } else {
      await _showStoreRoute(currentLatLng);
    }

    // Start location monitoring
    _startLocationMonitoring();
  }

  void _startLocationMonitoring() {
    _locationCheckTimer?.cancel();
    _locationCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      Position currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      double distanceToStore = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          _storeLatLng!.latitude,
          _storeLatLng!.longitude);

      double distanceToCustomer = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          _customerLatLng!.latitude,
          _customerLatLng!.longitude);

      setState(() {
        // Show store proximity alert only when near store
        if (distanceToStore <= DESTINATION_PROXIMITY_THRESHOLD && _isNavigatingToStore) {
          _showProximityOverlay = true;
          _proximityMessage = 'Bạn đang ở gần cửa hàng!';
        }
        // Show customer proximity alert only when near customer
        else if (distanceToCustomer <= DESTINATION_PROXIMITY_THRESHOLD && !_isNavigatingToStore) {
          _showProximityOverlay = true;
          _proximityMessage = 'Bạn đang ở gần địa điểm giao hàng!';
        }
        // Hide alerts when far from both locations
        else {
          _showProximityOverlay = false;
          _proximityMessage = '';
        }

        _showStartDeliveryButton =
            distanceToStore <= STORE_PROXIMITY_THRESHOLD &&
            _isNavigatingToStore &&
            widget.order['status'] == 'preparing';
      });
    });
  }

  void _showProximityAlert(String message) {
    if (mounted) {
      setState(() {
        _showProximityOverlay = true;
        _proximityMessage = message;
      });
    }
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
        desiredAccuracy: LocationAccuracy.high);

    final userLatLng = LatLng(
      currentPosition.latitude,
      currentPosition.longitude,
    );

    // Check order status to determine initial route
    if (widget.order['status'] == 'delivering') {
      await _showCustomerRoute(userLatLng);
    } else {
      await _showStoreRoute(userLatLng);
    }

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

  Future<void> _startDelivery() async {
    try {
      final shipperId = await AuthProvider.getUserId();
      if (shipperId == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse(
            '${Config.baseurl}/orders/${widget.order['id']}/start-delivery'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'shipperId': shipperId}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isNavigatingToStore = false;
          _showStartDeliveryButton = false;
        });
        _showCustomerRoute(LatLng(
          _storeLatLng!.latitude,
          _storeLatLng!.longitude,
        ));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã bắt đầu giao hàng')),
        );
      } else {
        final error = json.decode(response.body)['error'];
        throw Exception(error ?? 'Failed to start delivery');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đơn hàng #${widget.order['id']}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              _isNavigatingToStore
                  ? 'Đang đến cửa hàng'
                  : 'Đang đến khách hàng',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          NavigationView(
            mapOptions: _navigationOption,
            onMapCreated: (controller) {
              _navigationController = controller;
            },
            onMapRendered: () async {
              await _showStoreToCustomerRoute();
            },
            onRouteProgressChange: (RouteProgressEvent event) {
              setState(() {
                routeProgressEvent = event;
              });
              _setInstructionImage(
                  event.currentModifier, event.currentModifierType);
            },
          ),

          // Navigation instruction banner - Adjusted for AppBar
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
              ],
            ),
          ),

          // Add Start Delivery Button
          if (_showStartDeliveryButton)
            Positioned(
              left: 16,
              right: 16,
              bottom: 180, // Above the bottom panel
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delivery_dining),
                label: const Text('Đã nhận hàng giao'),
                onPressed: _startDelivery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 168, 255, 197),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

          // Add persistent proximity alert
          if (_showProximityOverlay)
            Positioned(
              top: 80, // Below AppBar
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _proximityMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
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
