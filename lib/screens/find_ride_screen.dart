import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'ride_details_screen.dart';
import 'widgets/bottom_nav.dart';

/// ------------ HELPER: FORMAT SHORT, CLEAN ADDRESS ------------
String formatShortAddress(Map<String, dynamic> json) {
  final address = json['address'] as Map<String, dynamic>?;

  if (address != null) {
    String? place =
        address['road'] ??
        address['pedestrian'] ??
        address['footway'] ??
        address['neighbourhood'] ??
        address['suburb'] ??
        address['hamlet'];

    String? city =
        address['city'] ??
        address['town'] ??
        address['village'] ??
        address['municipality'] ??
        address['county'];

    String? country = address['country'];

    final parts = <String>[
      if (place != null && place.isNotEmpty) place,
      if (city != null && city.isNotEmpty) city,
      if (country != null && country.isNotEmpty) country,
    ];

    if (parts.isNotEmpty) {
      return parts.join(', ');
    }
  }

  final display = (json['display_name'] ?? '') as String;
  if (display.isEmpty) return '';
  final segments = display.split(',').map((e) => e.trim()).toList();
  if (segments.length <= 3) return display;
  return segments.sublist(0, 3).join(', ');
}

// ---------- MODEL FOR LOCATION SUGGESTIONS ----------
class LocationSuggestion {
  final String displayName;
  final double lat;
  final double lon;

  LocationSuggestion({
    required this.displayName,
    required this.lat,
    required this.lon,
  });

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    return LocationSuggestion(
      displayName: formatShortAddress(json),
      lat: double.tryParse(json['lat'] ?? '0') ?? 0.0,
      lon: double.tryParse(json['lon'] ?? '0') ?? 0.0,
    );
  }
}

// ---------- SERVICE FOR NOMINATIM SEARCH / REVERSE ----------
class LocationSearchService {
  static const _searchBaseUrl = 'https://nominatim.openstreetmap.org/search';
  static const _reverseBaseUrl = 'https://nominatim.openstreetmap.org/reverse';

  // Search by text (English only, limited to Bahrain + Khobar area)
  static Future<List<LocationSuggestion>> search(String query) async {
    if (query.trim().length < 3) return [];

    final normalized = query.toLowerCase().trim();

    // Manual AUBH suggestion to be extra safe in the demo
    final List<LocationSuggestion> manual = [];
    if (normalized.contains('american university') ||
        normalized.contains('aubh')) {
      manual.add(
        LocationSuggestion(
          displayName: 'American University of Bahrain, Riffa, Bahrain',
          lat: 26.10,
          lon: 50.56,
        ),
      );
    }

    // Viewbox roughly around Bahrain + Al Khobar region (lon/lat)
    const viewbox = '49.8,26.8,50.8,25.5';

    final uri = Uri.parse(
      '$_searchBaseUrl'
      '?q=${Uri.encodeQueryComponent(query)}'
      '&format=json'
      '&addressdetails=1'
      '&limit=5'
      '&accept-language=en'
      '&countrycodes=bh,sa'
      '&viewbox=$viewbox'
      '&bounded=1',
    );

    final response = await http.get(
      uri,
      headers: {
        'User-Agent':
            'uniride_app/1.0 (student project; contact: example@uniride.app)',
      },
    );

    if (response.statusCode != 200) return manual;

    final List data = json.decode(response.body) as List;
    final apiResults = data.map((e) => LocationSuggestion.fromJson(e)).toList();

    return [...manual, ...apiResults];
  }

  // Reverse geocode LatLng → human readable address (English only)
  static Future<String?> reverse(LatLng point) async {
    final uri = Uri.parse(
      '$_reverseBaseUrl'
      '?lat=${point.latitude}'
      '&lon=${point.longitude}'
      '&format=json'
      '&addressdetails=1'
      '&accept-language=en',
    );

    final response = await http.get(
      uri,
      headers: {
        'User-Agent':
            'uniride_app/1.0 (student project; contact: example@uniride.app)',
      },
    );

    if (response.statusCode != 200) return null;

    final data = json.decode(response.body) as Map<String, dynamic>;
    final short = formatShortAddress(data);
    if (short.isNotEmpty) return short;
    return data['display_name'] as String?;
  }
}

class FindRideScreen extends StatefulWidget {
  final LatLng? initialPickupLocation;
  final String? initialPickupAddress;
  
  const FindRideScreen({
    super.key,
    this.initialPickupLocation,
    this.initialPickupAddress,
  });

  @override
  State<FindRideScreen> createState() => _FindRideScreenState();
}

class _FindRideScreenState extends State<FindRideScreen> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  final FocusNode _pickupFocusNode = FocusNode();

  TimeOfDay? startTime;
  TimeOfDay? endTime;

  // Autocomplete state
  Timer? _debounce;
  List<LocationSuggestion> _suggestions = [];
  bool _isSearchingLocations = false;
  
  // Pickup location for radius filtering
  LatLng? _pickupLocation;
  static const double _searchRadiusKm = 10.0;

  // UniRide colors
  static const Color kScreenTeal = Color(0xFFE0F9FB);
  static const Color kUniRideTeal2 = Color(0xFF009DAE);

  @override
  void initState() {
    super.initState();
    
    // Set initial pickup location if provided
    if (widget.initialPickupLocation != null) {
      _pickupLocation = widget.initialPickupLocation;
      if (widget.initialPickupAddress != null) {
        _pickupController.text = widget.initialPickupAddress!;
      }
    }

    _pickupFocusNode.addListener(() {
      if (_pickupFocusNode.hasFocus &&
          _pickupController.text.trim().length >= 3) {
        _onPickupChanged(_pickupController.text);
      }
    });
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dateController.dispose();
    _pickupFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------- LOCATION PERMISSION + CURRENT LOCATION ---------------
  Future<LatLng?> _getCurrentLocation() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      _showMessage("Please enable location services.");
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showMessage("UniRide works best with your location enabled.");
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showMessage("Location permission denied. Enable it in Settings.");
      return null;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return LatLng(pos.latitude, pos.longitude);
  }

  // ---------------- AUTOCOMPLETE HANDLING ----------------
  void _onPickupChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (value.trim().length < 3) {
        setState(() {
          _suggestions = [];
        });
        return;
      }

      setState(() => _isSearchingLocations = true);

      final results = await LocationSearchService.search(value);

      if (!mounted) return;

      setState(() {
        _suggestions = results;
        _isSearchingLocations = false;
      });
    });
  }

  void _selectSuggestion(LocationSuggestion suggestion) {
    setState(() {
      _pickupController.text = suggestion.displayName;
      _pickupLocation = LatLng(suggestion.lat, suggestion.lon);
      _suggestions = [];
    });
    FocusScope.of(context).unfocus();
  }

  // ---------------- MAP PICKER FOR PICKUP ----------------
  Future<void> _openPickupMapPicker() async {
    LatLng? selectedPoint;

    LatLng initialCenter = const LatLng(26.0667, 50.5577); // Bahrain fallback
    final current = await _getCurrentLocation();
    if (current != null) {
      initialCenter = current;
      selectedPoint = current; // pin on current location by default
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: initialCenter,
                      zoom: 13,
                    ),
                    markers: selectedPoint != null
                        ? {
                            Marker(
                              markerId: const MarkerId('selected'),
                              position: selectedPoint!,
                              infoWindow: const InfoWindow(title: 'Selected'),
                            ),
                          }
                        : {},
                    onTap: (LatLng point) {
                      setStateSheet(() {
                        selectedPoint = point;
                      });
                    },
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kUniRideTeal2,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: selectedPoint == null
                          ? null
                          : () async {
                              final address =
                                  await LocationSearchService.reverse(
                                    selectedPoint!,
                              );

                              setState(() {
                                _pickupController.text =
                                    address ??
                                    "${selectedPoint!.latitude}, ${selectedPoint!.longitude}";
                                _pickupLocation = selectedPoint;
                                _suggestions = [];
                              });

                              Navigator.pop(context);
                            },
                      child: const Text(
                        "Confirm Pickup Location",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------- BOTTOM SHEET BLUE CALENDAR ----------------
  void _openCalendar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          child: Column(
            children: [
              const Text(
                "Select a Date",
                style: TextStyle(
                  color: kUniRideTeal2,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: kUniRideTeal2,
                      onPrimary: Colors.white,
                      onSurface: Colors.black87,
                    ),
                  ),
                  child: CalendarDatePicker(
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                    onDateChanged: (picked) {
                      _dateController.text =
                          "${picked.day}/${picked.month}/${picked.year}";
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------- AM/PM TIME PICKER ----------------
  void _openTimePicker({required bool isStart}) {
    final hours = List.generate(12, (i) => i + 1); // 1–12
    final minutes = List.generate(60, (i) => i.toString().padLeft(2, "0"));
    final ampm = ["AM", "PM"];

    int selectedHour = 0;
    int selectedMinute = 0;
    int selectedAmPm = 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 330,
          child: Column(
            children: [
              const Text(
                "Select Time",
                style: TextStyle(
                  color: kUniRideTeal2,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 32,
                        scrollController: FixedExtentScrollController(
                          initialItem: 0,
                        ),
                        onSelectedItemChanged: (i) {
                          selectedHour = i;
                        },
                        children: hours
                            .map((h) => Center(child: Text(h.toString())))
                            .toList(),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 32,
                        scrollController: FixedExtentScrollController(
                          initialItem: 0,
                        ),
                        onSelectedItemChanged: (i) {
                          selectedMinute = i;
                        },
                        children: minutes
                            .map((m) => Center(child: Text(m)))
                            .toList(),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 32,
                        scrollController: FixedExtentScrollController(
                          initialItem: 0,
                        ),
                        onSelectedItemChanged: (i) {
                          selectedAmPm = i;
                        },
                        children: ampm
                            .map((p) => Center(child: Text(p)))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kUniRideTeal2,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  int hour = hours[selectedHour] % 12;
                  if (selectedAmPm == 1) hour += 12;

                  TimeOfDay finalTime = TimeOfDay(
                    hour: hour,
                    minute: selectedMinute,
                  );

                  setState(() {
                    if (isStart) {
                      startTime = finalTime;
                    } else {
                      endTime = finalTime;
                    }
                  });

                  Navigator.pop(context);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                  child: Text(
                    "Confirm",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return "--:--";
    return time.format(context);
  }

  // ---------------- DISTANCE CALCULATION ----------------
  double _calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    ) / 1000; // Convert meters to kilometers
  }

  // Use this method to filter rides when loading from database
  // Example: rides.where((ride) => _isWithinRadius(ride.pickupLocation)).toList()
  bool _isWithinRadius(LatLng rideLocation) {
    if (_pickupLocation == null) return true; // Show all if no pickup selected
    final distance = _calculateDistance(_pickupLocation!, rideLocation);
    return distance <= _searchRadiusKm;
  }

  // ---------------- SUGGESTIONS LIST ----------------
  Widget _buildLocationSuggestions() {
    if (_suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final s = _suggestions[index];
          return ListTile(
            leading: const Icon(
              Icons.location_on_outlined,
              color: kUniRideTeal2,
            ),
            title: Text(
              s.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _selectSuggestion(s),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScreenTeal,
      appBar: AppBar(
        backgroundColor: kScreenTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: kUniRideTeal2,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Find a Ride",
          style: TextStyle(
            color: kUniRideTeal2,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Enter your details to search for available rides.",
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 20),

              // PICKUP
              _pickupField(),
              if (_isSearchingLocations)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              _buildLocationSuggestions(),
              
              // Search radius indicator
              if (_pickupLocation != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_searching,
                        size: 16,
                        color: kUniRideTeal2,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Searching within ${_searchRadiusKm.toStringAsFixed(0)}km radius",
                        style: TextStyle(
                          color: kUniRideTeal2,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // DATE
              GestureDetector(
                onTap: _openCalendar,
                child: AbsorbPointer(
                  child: _inputField(
                    controller: _dateController,
                    icon: Icons.calendar_today_outlined,
                    hint: "Date (dd/mm/yyyy)",
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // START TIME
              GestureDetector(
                onTap: () => _openTimePicker(isStart: true),
                child: _timeField(
                  label: "Start Time",
                  value: _formatTime(startTime),
                ),
              ),
              const SizedBox(height: 16),

              // END TIME
              GestureDetector(
                onTap: () => _openTimePicker(isStart: false),
                child: _timeField(
                  label: "End Time",
                  value: _formatTime(endTime),
                ),
              ),

              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Available Rides",
                    style: TextStyle(
                      color: kUniRideTeal2,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_pickupLocation != null)
                    Text(
                      "Within ${_searchRadiusKm.toStringAsFixed(0)}km",
                      style: TextStyle(
                        color: kUniRideTeal2.withOpacity(0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              _rideCard(
                name: "Talal AlHamer",
                rating: "4.8",
                pickup: "AUBH Campus",
                destination: "City Center",
                time: "2:00 PM",
                seats: "2 seats",
                price: "BD 2.0",
              ),
              const SizedBox(height: 12),
              _rideCard(
                name: "Renad Ibrahim",
                rating: "4.9",
                pickup: "Manama",
                destination: "Riffa",
                time: "4:00 PM",
                seats: "3 seats",
                price: "BD 3.0",
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNav(currentIndex: 1),
    );
  }

  // -------- PICKUP FIELD WITH MAP ICON --------
  Widget _pickupField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kUniRideTeal2.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: _pickupController,
        focusNode: _pickupFocusNode,
        onChanged: _onPickupChanged,
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.location_on_outlined,
            color: kUniRideTeal2,
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.map_outlined, color: kUniRideTeal2),
            onPressed: _openPickupMapPicker,
          ),
          hintText: "Pickup location (search or pick on map)",
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  // -------- GENERIC TEXT INPUT FIELD --------
  Widget _inputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kUniRideTeal2.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: kUniRideTeal2),
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  // -------- TIME FIELD --------
  Widget _timeField({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kUniRideTeal2.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$label:",
            style: const TextStyle(color: Colors.black54, fontSize: 15),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // -------- RIDE CARD --------
  Widget _rideCard({
    required String name,
    required String rating,
    required String pickup,
    required String destination,
    required String time,
    required String seats,
    required String price,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RideDetailsScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: kUniRideTeal2,
              child: Text(
                name[0],
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              rating,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "$pickup → $destination",
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(time, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                      Text(
                        seats,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: kUniRideTeal2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
