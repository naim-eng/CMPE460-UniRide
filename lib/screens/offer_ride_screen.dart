import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'ride_published_screen.dart';
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

  // Search by text
  static Future<List<LocationSuggestion>> search(String query) async {
    if (query.trim().length < 3) return [];

    final normalized = query.toLowerCase().trim();

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

  // Reverse geocode LatLng → human readable address
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

class OfferRideScreen extends StatefulWidget {
  const OfferRideScreen({super.key});

  @override
  State<OfferRideScreen> createState() => _OfferRideScreenState();
}

class _OfferRideScreenState extends State<OfferRideScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _seatsController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  final FocusNode _fromFocusNode = FocusNode();
  final FocusNode _toFocusNode = FocusNode();

  final _formKey = GlobalKey<FormState>();

  Timer? _debounce;
  List<LocationSuggestion> _suggestions = [];
  bool _isSearchingLocations = false;
  String? _activeLocationField;

  LatLng? _fromPoint;
  LatLng? _toPoint;
  double? _distanceKm;
  int? _durationMinutes;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // Colors
  static const Color kScreenTeal = Color(0xFFE0F9FB);
  static const Color kUniRideTeal2 = Color(0xFF009DAE);
  static const Color kUniRideYellow = Color(0xFFFFC727);

  @override
  void initState() {
    super.initState();

    _fromFocusNode.addListener(() {
      if (_fromFocusNode.hasFocus) {
        setState(() => _activeLocationField = 'from');
        if (_fromController.text.isNotEmpty) {
          _onLocationChanged('from', _fromController.text);
        }
      }
    });

    _toFocusNode.addListener(() {
      if (_toFocusNode.hasFocus) {
        setState(() => _activeLocationField = 'to');
        if (_toController.text.isNotEmpty) {
          _onLocationChanged('to', _toController.text);
        }
      }
    });
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _seatsController.dispose();
    _priceController.dispose();
    _fromFocusNode.dispose();
    _toFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---- ROUTE INFO ----
  void _updateRouteInfo() {
    if (_fromPoint == null || _toPoint == null) {
      setState(() {
        _distanceKm = null;
        _durationMinutes = null;
      });
      return;
    }

    // Simple distance calculation
    final distance = _calculateDistance(_fromPoint!, _toPoint!);
    final minutes = (distance / 45 * 60).round().clamp(1, 999);

    setState(() {
      _distanceKm = distance;
      _durationMinutes = minutes;
    });
  }

  // Simple distance calculation using Haversine
  double _calculateDistance(LatLng p1, LatLng p2) {
    const R = 6371; // Earth's radius in km
    final dLat = _toRad(p2.latitude - p1.latitude);
    final dLon = _toRad(p2.longitude - p1.longitude);
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_toRad(p1.latitude)) * cos(_toRad(p2.latitude)) * sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRad(double degree) => degree * (3.14159265359 / 180);

  // ---- LOCATION PERMISSION ----
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

  // ---- AUTOCOMPLETE ----
  void _onLocationChanged(String fieldId, String value) {
    setState(() {
      _activeLocationField = fieldId;
    });

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
      if (_activeLocationField == 'from') {
        _fromController.text = suggestion.displayName;
        _fromPoint = LatLng(suggestion.lat, suggestion.lon);
      } else if (_activeLocationField == 'to') {
        _toController.text = suggestion.displayName;
        _toPoint = LatLng(suggestion.lat, suggestion.lon);
      }
      _suggestions = [];
    });

    _updateRouteInfo();
    FocusScope.of(context).unfocus();
  }

  // ---- MAP PICKER ----
  Future<void> _openMapPicker(
    TextEditingController controller, {
    required String fieldId,
  }) async {
    LatLng? selectedPoint;

    LatLng initialCenter = const LatLng(26.0667, 50.5577);
    final current = await _getCurrentLocation();
    if (current != null) {
      initialCenter = current;
      selectedPoint = current;
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
                                controller.text =
                                    address ??
                                    "${selectedPoint!.latitude}, ${selectedPoint!.longitude}";

                                if (fieldId == 'from') {
                                  _fromPoint = selectedPoint;
                                } else {
                                  _toPoint = selectedPoint;
                                }
                              });

                              _updateRouteInfo();
                              Navigator.pop(context);
                            },
                      child: const Text(
                        "Confirm Location",
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

  // ---- DATE PICKER ----
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
                    ),
                  ),
                  child: CalendarDatePicker(
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    onDateChanged: (date) {
                      setState(() {
                        _selectedDate = date;
                        _dateController.text =
                            "${date.day}/${date.month}/${date.year}";
                      });
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

  // ---- TIME PICKER ----
  void _openTimePicker() {
    final hours = List.generate(12, (i) => i + 1);
    final minutes = List.generate(60, (i) => i.toString().padLeft(2, "0"));
    final ampm = ["AM", "PM"];

    int selectedHour = _selectedTime.hourOfPeriod;
    int selectedMinute = _selectedTime.minute;
    int selectedAmPm = _selectedTime.period == DayPeriod.am ? 0 : 1;

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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 32,
                        scrollController: FixedExtentScrollController(
                          initialItem: selectedHour,
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
                          initialItem: selectedMinute,
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
                          initialItem: selectedAmPm,
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

                  setState(() {
                    _selectedTime = TimeOfDay(
                      hour: hour,
                      minute: selectedMinute,
                    );
                    _timeController.text =
                        "${hours[selectedHour]}:${minutes[selectedMinute]} ${ampm[selectedAmPm]}";
                  });

                  Navigator.pop(context);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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

  // ---- AUTOCOMPLETE LIST ----
  Widget _buildLocationSuggestions() {
    if (_suggestions.isEmpty || _activeLocationField == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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

  // ---- ROUTE PREVIEW MAP ----
  Widget _buildRoutePreview() {
    if (_fromPoint == null || _toPoint == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_distanceKm != null && _durationMinutes != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, top: 4),
            child: Text(
              "Approx. ${_distanceKm!.toStringAsFixed(1)} km • ~$_durationMinutes min by car",
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _fromPoint!,
                zoom: 13,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('from'),
                  position: _fromPoint!,
                  infoWindow: const InfoWindow(title: 'From'),
                ),
                Marker(
                  markerId: const MarkerId('to'),
                  position: _toPoint!,
                  infoWindow: const InfoWindow(title: 'To'),
                ),
              },
              polylines: {
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: [_fromPoint!, _toPoint!],
                  color: kUniRideTeal2,
                  width: 4,
                ),
              },
              zoomControlsEnabled: false,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          "Offer a Ride",
          style: TextStyle(color: kUniRideTeal2, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Share your ride with other UniRide students.",
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildLocationField(
                        controller: _fromController,
                        label: "From",
                        icon: Icons.location_on_outlined,
                        focusNode: _fromFocusNode,
                        fieldId: 'from',
                      ),
                      _buildLocationField(
                        controller: _toController,
                        label: "To",
                        icon: Icons.flag_outlined,
                        focusNode: _toFocusNode,
                        fieldId: 'to',
                      ),
                      if (_isSearchingLocations)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      _buildLocationSuggestions(),
                      _buildRoutePreview(),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              controller: _dateController,
                              label: "Date",
                              icon: Icons.calendar_today,
                              readOnly: true,
                              onTap: _openCalendar,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              controller: _timeController,
                              label: "Time",
                              icon: Icons.access_time,
                              readOnly: true,
                              onTap: _openTimePicker,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              controller: _seatsController,
                              label: "Seats",
                              icon: Icons.event_seat,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              controller: _priceController,
                              label: "Price (BD)",
                              icon: Icons.attach_money,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RidePublishedScreen(
                                    from: _fromController.text,
                                    to: _toController.text,
                                    date: _dateController.text,
                                    time: _timeController.text,
                                    price: _priceController.text,
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kUniRideYellow,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "Publish Ride",
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNav(currentIndex: 2),
    );
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required FocusNode focusNode,
    required String fieldId,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.text,
        onChanged: (value) => _onLocationChanged(fieldId, value),
        validator: (value) =>
            value == null || value.isEmpty ? "Required" : null,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(icon, color: kUniRideTeal2),
          suffixIcon: IconButton(
            icon: const Icon(Icons.map_outlined, color: kUniRideTeal2),
            onPressed: () => _openMapPicker(controller, fieldId: fieldId),
          ),
          labelText: "$label (search or pick on map)",
          labelStyle: const TextStyle(color: Colors.black54),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: kUniRideTeal2.withOpacity(0.4),
              width: 1.2,
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: kUniRideTeal2, width: 1.8),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        validator: (value) =>
            value == null || value.isEmpty ? "Required" : null,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(icon, color: kUniRideTeal2),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: kUniRideTeal2.withOpacity(0.4),
              width: 1.2,
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: kUniRideTeal2, width: 1.8),
          ),
        ),
      ),
    );
  }
}
