import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

import 'passenger_ride_details_screen.dart';
import 'widgets/bottom_nav.dart';
import 'package:uniride_app/services/rating_service.dart';

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

  static Future<List<LocationSuggestion>> search(String query) async {
    if (query.trim().length < 3) return [];

    final normalized = query.toLowerCase().trim();
    final List<LocationSuggestion> manual = [];

    if (normalized.contains('aubh') ||
        normalized.contains('american university')) {
      manual.add(
        LocationSuggestion(
          displayName: 'American University of Bahrain, Riffa, Bahrain',
          lat: 26.10,
          lon: 50.56,
        ),
      );
    }

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
      headers: {'User-Agent': 'uniride_app/1.0 (student project)'},
    );

    if (response.statusCode != 200) return manual;

    final List data = json.decode(response.body);
    final mapped = data.map((e) => LocationSuggestion.fromJson(e)).toList();

    return [...manual, ...mapped];
  }

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
      headers: {'User-Agent': 'uniride_app/1.0 (student project)'},
    );

    if (response.statusCode != 200) return null;

    final data = json.decode(response.body);
    final short = formatShortAddress(data);
    if (short.isNotEmpty) return short;
    return data['display_name'];
  }
}

// ------------------------------------------------------

class PassengerFindRideScreen extends StatefulWidget {
  final LatLng? initialPickupLocation;
  final String? initialPickupAddress;

  const PassengerFindRideScreen({
    super.key,
    this.initialPickupLocation,
    this.initialPickupAddress,
  });

  @override
  State<PassengerFindRideScreen> createState() => _PassengerFindRideScreenState();
}

class _PassengerFindRideScreenState extends State<PassengerFindRideScreen> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  final FocusNode _pickupFocusNode = FocusNode();

  TimeOfDay? startTime;
  TimeOfDay? endTime;

  Timer? _debounce;
  List<LocationSuggestion> _suggestions = [];
  bool _isSearchingLocations = false;

  LatLng? _pickupLocation;
  static const double _searchRadiusKm = 10.0;

  static const Color kScreenTeal = Color(0xFFE0F9FB);
  static const Color kUniRideTeal2 = Color(0xFF009DAE);

  @override
  void initState() {
    super.initState();

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

  // ---------------- VALIDATION HELPER ----------------
  bool _isEndAfterStart(TimeOfDay start, TimeOfDay end) {
    final s = start.hour * 60 + start.minute;
    final e = end.hour * 60 + end.minute;
    return e > s;
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------- DISTANCE CALCULATION ----------------
  double _toRad(double degree) => degree * (pi / 180);

  double _calculateDistance(LatLng p1, LatLng p2) {
    const R = 6371;
    final dLat = _toRad(p2.latitude - p1.latitude);
    final dLon = _toRad(p2.longitude - p1.longitude);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(p1.latitude)) *
            cos(_toRad(p2.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  bool _isWithinRadius(LatLng center, LatLng point) {
    return _calculateDistance(center, point) <= _searchRadiusKm;
  }

  // ---------------- AUTOCOMPLETE ----------------
  void _onPickupChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (value.trim().length < 3) {
        setState(() => _suggestions = []);
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

  // ---------------- MAP PICKER (WITH FIX) ----------------
  Future<void> _openPickupMapPicker() async {
    LatLng? selectedPoint;

    LatLng initialCenter = const LatLng(26.0667, 50.5577);
    final current = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    initialCenter = LatLng(current.latitude, current.longitude);
    selectedPoint = initialCenter;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setStateSheet) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: initialCenter,
                      zoom: 13,
                    ),

                    // ⭐ Allow dragging/panning in bottom sheet
                    gestureRecognizers: {
                      Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                      ),
                    },

                    markers: selectedPoint != null
                        ? {
                            Marker(
                              markerId: const MarkerId('selected'),
                              position: selectedPoint!,
                            ),
                          }
                        : {},

                    onTap: (LatLng point) {
                      setStateSheet(() => selectedPoint = point);
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

                              Navigator.of(sheetContext).pop();
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

  // ---------------- CALENDAR ----------------
  void _openCalendar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
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
              Expanded(
                child: CalendarDatePicker(
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                  onDateChanged: (picked) {
                    _dateController.text =
                        "${picked.day}/${picked.month}/${picked.year}";
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------- TIME PICKER (WITH FIX) ----------------
  void _openTimePicker({required bool isStart}) {
    final hours = List.generate(12, (i) => i + 1);
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
      builder: (sheetContext) {
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

              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 32,
                        onSelectedItemChanged: (i) => selectedHour = i,
                        children: hours
                            .map((h) => Center(child: Text(h.toString())))
                            .toList(),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 32,
                        onSelectedItemChanged: (i) => selectedMinute = i,
                        children: minutes
                            .map((m) => Center(child: Text(m)))
                            .toList(),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 32,
                        onSelectedItemChanged: (i) => selectedAmPm = i,
                        children: ampm
                            .map((p) => Center(child: Text(p)))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),

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

                  final picked = TimeOfDay(hour: hour, minute: selectedMinute);

                  setState(() {
                    if (isStart) {
                      startTime = picked;

                      if (endTime != null &&
                          !_isEndAfterStart(startTime!, endTime!)) {
                        endTime = null;
                      }
                    } else {
                      if (startTime != null &&
                          !_isEndAfterStart(startTime!, picked)) {
                        _showMessage("End time must be after the start time.");
                        return; // DO NOT POP SCREEN
                      }

                      endTime = picked;
                    }
                  });

                  Navigator.of(sheetContext).pop(); // only close bottom sheet
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

  // ---------------- UI WIDGETS + FIREBASE LISTENERS ----------------
  Widget _buildLocationSuggestions() {
    if (_suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: Colors.black12),
        itemBuilder: (context, i) {
          final s = _suggestions[i];
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

  // ---------------- MAIN BUILD ----------------
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

              GestureDetector(
                onTap: () => _openTimePicker(isStart: true),
                child: _timeField(
                  label: "Start Time",
                  value: _formatTime(startTime),
                ),
              ),
              const SizedBox(height: 16),

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

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('rides')
                    .where('status', isEqualTo: 'active')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(color: kUniRideTeal2),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 60,
                              color: Colors.black26,
                            ),
                            SizedBox(height: 16),
                            Text(
                              "No rides available",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final allRides = snapshot.data!.docs;
                  final filtered = _pickupLocation != null
                      ? allRides.where((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          final lat = d['fromLat'];
                          final lng = d['fromLng'];
                          if (lat == null || lng == null) return true;
                          return _isWithinRadius(
                            _pickupLocation!,
                            LatLng(lat, lng),
                          );
                        }).toList()
                      : allRides;

                  return Column(
                    children: filtered.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _rideCard(
                          rideId: doc.id,
                          name: d['driverName'] ?? "Driver",
                          pickup: d['from'] ?? "",
                          destination: d['to'] ?? "",
                          time: d['time'] ?? "",
                          seats: "${d['seatsAvailable'] ?? 0} seats",
                          price: "BD ${d['price'] ?? '0.0'}",
                          data: d,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNav(currentIndex: 1),
    );
  }

  // ---------------- INPUT WIDGETS ----------------
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
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 15),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ---------------- RIDE CARD ----------------
  Widget _rideCard({
    required String rideId,
    required String name,
    required String pickup,
    required String destination,
    required String time,
    required String seats,
    required String price,
    required Map<String, dynamic> data,
  }) {
    final driverId = data['driverId'] ?? "";

    // Read REAL seatsAvailable
    final int seatsAvailable = data['seatsAvailable'] is int
        ? data['seatsAvailable']
        : int.tryParse("${data['seatsAvailable']}") ?? 0;

    final bool isFull = seatsAvailable <= 0;

    return GestureDetector(
      onTap: () {
        // Option C: allow open, but notify if full
        if (isFull) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "This ride is currently full. You can still view details.",
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PassengerRideDetailsScreen(rideId: rideId, rideData: data),
          ),
        );
      },
      child: Opacity(
        opacity: isFull ? 0.7 : 1.0, // slightly dim when FULL
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
                  name.isNotEmpty ? name[0] : "?",
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

                        // Driver Rating
                        FutureBuilder<double>(
                          future: RatingService.getAverageRating(driverId),
                          builder: (context, snap) {
                            final r = snap.data ?? 0.0;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: r > 0
                                    ? Colors.orange.shade300
                                    : Colors.grey.shade300,
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
                                    r > 0 ? r.toStringAsFixed(1) : "—",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "$pickup → $destination",
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
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

                        // FULL / seats available badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isFull
                                ? Colors.red.shade400
                                : Colors.green.shade400,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isFull ? "FULL" : "$seatsAvailable seats",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        Text(
                          price,
                          style: const TextStyle(
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
      ),
    );
  }
}
