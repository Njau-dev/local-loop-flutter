// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:local_loop/models/event_model.dart';
import 'package:local_loop/services/auth_service.dart';
import 'package:local_loop/services/event_service.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventService = EventService();
  late final AuthService _authService;

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxVolunteersController = TextEditingController(text: '50');
  final _locationAutocompleteController = TextEditingController();

  // Form state
  String _selectedCategory = 'community';
  DateTime _startTime = DateTime.now().add(const Duration(hours: 1));
  DateTime _endTime = DateTime.now().add(const Duration(hours: 3));
  double _selectedLatitude = -1.2921; // Default to Nairobi
  double _selectedLongitude = 36.8219;
  bool _isLoading = false;
  bool _isLocationSelected = false;

  // Map controller
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  // Google Maps API Key - Replace with your actual key
  static const String _googleMapsApiKey =
      'AIzaSyDf5_sia3qxAWcuXeVHfpxa_7tWpW7zCHg';

  @override
  void initState() {
    super.initState();
    _authService = Provider.of<AuthService>(context, listen: false);
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxVolunteersController.dispose();
    _locationAutocompleteController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (kIsWeb) {
        // For web, just use default location and get its address
        _updateMapLocation(_selectedLatitude, _selectedLongitude);
        await _getLocationNameFromCoordinates(
          _selectedLatitude,
          _selectedLongitude,
        );
        return;
      }

      // Check location permissions for mobile
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permission denied');
          // Use default location
          _updateMapLocation(_selectedLatitude, _selectedLongitude);
          await _getLocationNameFromCoordinates(
            _selectedLatitude,
            _selectedLongitude,
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('Location permissions are permanently denied');
        // Use default location
        _updateMapLocation(_selectedLatitude, _selectedLongitude);
        await _getLocationNameFromCoordinates(
          _selectedLatitude,
          _selectedLongitude,
        );
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _selectedLatitude = position.latitude;
        _selectedLongitude = position.longitude;
      });

      _updateMapLocation(_selectedLatitude, _selectedLongitude);
      await _getLocationNameFromCoordinates(
        _selectedLatitude,
        _selectedLongitude,
      );
    } catch (e) {
      print('Error getting location: $e');
      _showSnackBar('Error getting current location');
      _updateMapLocation(_selectedLatitude, _selectedLongitude);
      await _getLocationNameFromCoordinates(
        _selectedLatitude,
        _selectedLongitude,
      );
    }
  }

  void _updateMapLocation(double lat, double lng) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: LatLng(lat, lng),
          infoWindow: const InfoWindow(title: 'Event Location'),
        ),
      };
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15.0),
    );
  }

  /// Robust location name resolver using Google Maps Geocoding API
  Future<void> _getLocationNameFromCoordinates(double lat, double lng) async {
    try {
      final locationName = await _reverseGeocode(lat, lng);

      setState(() {
        _locationController.text = locationName;
        _isLocationSelected = true;
        _selectedLatitude = lat;
        _selectedLongitude = lng;
      });
      
      debugPrint('Location resolved: $locationName');
    } catch (e) {
      debugPrint('Error resolving location: $e');
      // Fallback to a user-friendly coordinate display
      final locationName = await _getFallbackLocationName(lat, lng);
      
      setState(() {
        _locationController.text = locationName;
        _isLocationSelected = true;
        _selectedLatitude = lat;
        _selectedLongitude = lng;
      });
    }
  }

  /// Primary method: Google Maps Reverse Geocoding API
  Future<String> _reverseGeocode(double lat, double lng) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$_googleMapsApiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['status'] == 'OK' &&
          data['results'] != null &&
          data['results'].isNotEmpty) {
        final result = data['results'][0];

        // Extract meaningful location components
        String city = '';
        String country = '';
        String locality = '';

        for (final component in result['address_components']) {
          final types = List<String>.from(component['types']);

          if (types.contains('locality')) {
            city = component['long_name'];
          } else if (types.contains('administrative_area_level_1') &&
              city.isEmpty) {
            city = component['long_name'];
          } else if (types.contains('administrative_area_level_2') &&
              city.isEmpty) {
            locality = component['long_name'];
          } else if (types.contains('country')) {
            country = component['long_name'];
          }
        }
        
        // Build location string priority: City, Country or Locality, Country
        if (city.isNotEmpty && country.isNotEmpty) {
          return '$city, $country';
        } else if (locality.isNotEmpty && country.isNotEmpty) {
          return '$locality, $country';
        } else if (country.isNotEmpty) {
          return country;
        } else {
          // Use the formatted address as fallback
          return result['formatted_address'] ?? 'Unknown Location';
        }
      } else {
        throw Exception('No results found: ${data['status']}');
      }
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    }
  }

  /// Fallback method: Estimate location based on coordinates
  Future<String> _getFallbackLocationName(double lat, double lng) async {
    // Try alternative geocoding service (OpenStreetMap Nominatim) as fallback
    try {
      final nominatimUrl =
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&addressdetails=1';

      final response = await http.get(
        Uri.parse(nominatimUrl),
        headers: {'User-Agent': 'LocalLoop/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['address'] != null) {
          final address = data['address'];

          String city =
              address['city'] ??
              address['town'] ??
              address['village'] ??
              address['suburb'] ??
              address['municipality'] ??
              '';

          String country = address['country'] ?? '';

          if (city.isNotEmpty && country.isNotEmpty) {
            return '$city, $country';
          } else if (country.isNotEmpty) {
            return country;
          }
        }
      }
    } catch (e) {
      debugPrint('Nominatim fallback failed: $e');
    }

    // Final fallback: Estimate region based on coordinates
    return _estimateLocationFromCoordinates(lat, lng);
  }

  /// Final fallback: Basic regional estimation
  String _estimateLocationFromCoordinates(double lat, double lng) {
    // Kenya region check (since default is Nairobi)
    if (lat >= -4.5 && lat <= 5.5 && lng >= 33.5 && lng <= 42.0) {
      if (lat >= -1.5 && lat <= -1.0 && lng >= 36.5 && lng <= 37.0) {
        return 'Nairobi, Kenya';
      }
      return 'Kenya';
    }

    // East Africa region
    if (lat >= -12.0 && lat <= 18.0 && lng >= 21.0 && lng <= 52.0) {
      return 'East Africa';
    }

    // Africa continent
    if (lat >= -35.0 && lat <= 37.0 && lng >= -18.0 && lng <= 52.0) {
      return 'Africa';
    }

    // Global fallback with readable coordinates
    String latDir = lat >= 0 ? 'N' : 'S';
    String lngDir = lng >= 0 ? 'E' : 'W';

    return '${lat.abs().toStringAsFixed(2)}°$latDir, ${lng.abs().toStringAsFixed(2)}°$lngDir';
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedLatitude = position.latitude;
      _selectedLongitude = position.longitude;
    });

    _updateMapLocation(position.latitude, position.longitude);
    _getLocationNameFromCoordinates(position.latitude, position.longitude);
  }

  /// Forward geocoding: Convert address text to coordinates
  Future<void> _searchLocationByText(String searchText) async {
    if (searchText.trim().isEmpty) return;
    
    try {
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(searchText)}&key=$_googleMapsApiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' &&
            data['results'] != null &&
            data['results'].isNotEmpty) {
          final result = data['results'][0];
          final geometry = result['geometry'];
          final location = geometry['location'];

          final lat = location['lat'].toDouble();
          final lng = location['lng'].toDouble();

          setState(() {
            _selectedLatitude = lat;
            _selectedLongitude = lng;
          });

          _updateMapLocation(lat, lng);
          await _getLocationNameFromCoordinates(lat, lng);
        } else {
          _showSnackBar(
            'Location not found. Please try a different search term.',
          );
        }
      } else {
        _showSnackBar('Error searching location. Please try again.');
      }
    } catch (e) {
      debugPrint('Location search error: $e');
      _showSnackBar('Error searching location. Please check your connection.');
    }
  }

  Future<void> _selectDateTime({required bool isStartTime}) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStartTime ? _startTime : _endTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (!mounted) return;

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          isStartTime ? _startTime : _endTime,
        ),
      );

      if (pickedTime != null) {
        final DateTime newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          if (isStartTime) {
            _startTime = newDateTime;
            // Ensure end time is after start time
            if (_endTime.isBefore(_startTime)) {
              _endTime = _startTime.add(const Duration(hours: 2));
            }
          } else {
            if (newDateTime.isAfter(_startTime)) {
              _endTime = newDateTime;
            } else {
              _showSnackBar('End time must be after start time');
            }
          }
        });
      }
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isLocationSelected) {
      _showSnackBar('Please select a location on the map');
      return;
    }

    if (_startTime.isBefore(DateTime.now())) {
      _showSnackBar('Start time must be in the future');
      return;
    }

    if (_endTime.isBefore(_startTime)) {
      _showSnackBar('End time must be after start time');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      final userModel = _authService.userModel;
      if (userModel == null) {
        throw Exception('User not authenticated');
      }

      // Create event model
      final EventModel event = EventModel(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        color: EventCategories.getCategory(_selectedCategory)['color'],
        icon: EventCategories.getCategory(_selectedCategory)['icon'],
        startTime: _startTime,
        endTime: _endTime,
        location: _locationController.text.trim(), // Only address string
        locationLatitude: _selectedLatitude,
        locationLongitude: _selectedLongitude,
        organizerId: userModel.uid,
        organizerName: userModel.username ?? userModel.email,
        maxVolunteers: int.tryParse(_maxVolunteersController.text) ?? 50,
        createdAt: DateTime.now(),
      );

      // Create event
      final String eventId = await _eventService.createEvent(event);

      if (!mounted) return;
      // Show success message and navigate
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created successfully!')),
      );

      Navigator.of(context).pop(eventId);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error creating event: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
        backgroundColor: const Color(0xFF00664F),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Event Title *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter event title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter event description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          EventCategories.getCategoryKeys().map((String key) {
                            final category = EventCategories.getCategory(key);
                            return DropdownMenuItem<String>(
                              value: key,
                              child: Row(
                                children: [
                                  Icon(
                                    category['icon'],
                                    color: category['color'],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(category['name']),
                                ],
                              ),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategory = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Start Time
                    InkWell(
                      onTap: () => _selectDateTime(isStartTime: true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Time *',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat(
                                'MMM dd, yyyy - HH:mm',
                              ).format(_startTime),
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // End Time
                    InkWell(
                      onTap: () => _selectDateTime(isStartTime: false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Time *',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat(
                                'MMM dd, yyyy - HH:mm',
                              ).format(_endTime),
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Max Volunteers
                    TextFormField(
                      controller: _maxVolunteersController,
                      decoration: const InputDecoration(
                        labelText: 'Maximum Volunteers',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final int? number = int.tryParse(value);
                          if (number == null || number <= 0) {
                            return 'Please enter a valid number greater than 0';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Location Search
                    TextFormField(
                      controller: _locationAutocompleteController,
                      decoration: const InputDecoration(
                        labelText: 'Search Location (City, Town, Country)',
                        hintText: 'Enter location to search',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onFieldSubmitted: (value) async {
                        await _searchLocationByText(value);
                      },
                    ),
                    const SizedBox(height: 8),

                    // Selected Location Display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade50,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFF00664F),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _locationController.text.isEmpty
                                  ? 'No location selected'
                                  : _locationController.text,
                              style: TextStyle(
                                color:
                                    _locationController.text.isEmpty
                                        ? Colors.grey
                                        : Colors.black87,
                                fontWeight:
                                    _locationController.text.isEmpty
                                        ? FontWeight.normal
                                        : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Map
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: GoogleMap(
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                          },
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              _selectedLatitude,
                              _selectedLongitude,
                            ),
                            zoom: 15.0,
                          ),
                          onTap: _onMapTapped,
                          markers: _markers,
                          myLocationEnabled: !kIsWeb,
                          myLocationButtonEnabled: !kIsWeb,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap on the map to select event location or search above',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Create button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00664F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text(
                          'Create Event',
                          style: TextStyle(fontSize: 18),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
