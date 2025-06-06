// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:local_loop/models/event_model.dart';
import 'package:local_loop/services/event_service.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventService = EventService();

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxVolunteersController = TextEditingController(text: '50');

  // Form state
  String _selectedCategory = 'community';
  DateTime _startTime = DateTime.now().add(const Duration(hours: 1));
  DateTime _endTime = DateTime.now().add(const Duration(hours: 3));
  double _selectedLatitude = -1.2921; // Default to Nairobi
  double _selectedLongitude = 36.8219;
  List<XFile> _selectedImages = [];
  bool _isLoading = false;
  bool _isLocationSelected = false;

  // Map controller
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxVolunteersController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (kIsWeb) {
        // For web, just use default location
        _updateMapLocation(_selectedLatitude, _selectedLongitude);
        return;
      }

      // Check location permissions for mobile
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('Location permissions are permanently denied');
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
      _updateLocationFromCoordinates(_selectedLatitude, _selectedLongitude);
    } catch (e) {
      print('Error getting location: $e');
      _showSnackBar('Error getting current location');
      _updateMapLocation(_selectedLatitude, _selectedLongitude);
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

  Future<void> _updateLocationFromCoordinates(double lat, double lng) async {
    try {
      // For web, just use coordinates
      if (kIsWeb) {
        setState(() {
          _locationController.text =
              'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
          _isLocationSelected = true;
        });
        return;
      }

      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        List<String> addressParts = [];

        // Add each part only if it exists and is not empty
        if (place.street?.isNotEmpty ?? false) addressParts.add(place.street!);
        if (place.subLocality?.isNotEmpty ?? false)
          addressParts.add(place.subLocality!);
        if (place.locality?.isNotEmpty ?? false)
          addressParts.add(place.locality!);
        if (place.country?.isNotEmpty ?? false)
          addressParts.add(place.country!);

        final address =
            addressParts.isNotEmpty
                ? addressParts.join(', ')
                : 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';

        setState(() {
          _locationController.text = address;
          _isLocationSelected = true;
          _selectedLatitude = lat;
          _selectedLongitude = lng;
        });
      } else {
        // Fallback to coordinates if no placemark found
        setState(() {
          _locationController.text =
              'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
          _isLocationSelected = true;
          _selectedLatitude = lat;
          _selectedLongitude = lng;
        });
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
      // Always ensure we at least save the coordinates
      setState(() {
        _locationController.text =
            'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
        _isLocationSelected = true;
        _selectedLatitude = lat;
        _selectedLongitude = lng;
      });
    }
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedLatitude = position.latitude;
      _selectedLongitude = position.longitude;
    });

    _updateMapLocation(position.latitude, position.longitude);
    _updateLocationFromCoordinates(position.latitude, position.longitude);
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      _showSnackBar('Error picking images: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) return [];

    List<String> imageUrls = [];

    for (int i = 0; i < _selectedImages.length; i++) {
      try {
        final String fileName =
            '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final Reference ref = FirebaseStorage.instance
            .ref()
            .child('event_images')
            .child(fileName);

        late UploadTask uploadTask;

        if (kIsWeb) {
          uploadTask = ref.putData(await _selectedImages[i].readAsBytes());
        } else {
          uploadTask = ref.putFile(File(_selectedImages[i].path));
        }

        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      } catch (e) {
        print('Error uploading image $i: $e');
      }
    }

    return imageUrls;
  }

  Future<void> _selectDateTime({required bool isStartTime}) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStartTime ? _startTime : _endTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

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
      // Upload images
      final List<String> imageUrls = await _uploadImages();

      // Get current user
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create event model
      final EventModel event = EventModel(
        id: '', // Will be set by Firestore
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        color: EventCategories.getCategory(_selectedCategory)['color'],
        icon: EventCategories.getCategory(_selectedCategory)['icon'],
        startTime: _startTime,
        endTime: _endTime,
        location: _locationController.text.trim(),
        locationLatitude: _selectedLatitude,
        locationLongitude: _selectedLongitude,
        organizerId: currentUser.uid,
        organizerName:
            currentUser.displayName ?? currentUser.email ?? 'Unknown',
        images: imageUrls,
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
        // Check if widget is still mounted
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

                    // Location
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Location *',
                        border: const OutlineInputBorder(),
                        suffixIcon:
                            _isLocationSelected
                                ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                                : const Icon(Icons.location_on),
                      ),
                      readOnly: true,
                      validator: (value) {
                        if (!_isLocationSelected) {
                          return 'Please select a location on the map';
                        }
                        return null;
                      },
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
                      'Tap on the map to select event location',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Images section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Event Images',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('Add Images'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Display selected images
                    if (_selectedImages.isNotEmpty)
                      Container(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child:
                                          kIsWeb
                                              ? FutureBuilder<Uint8List>(
                                                future:
                                                    _selectedImages[index]
                                                        .readAsBytes(),
                                                builder: (context, snapshot) {
                                                  if (snapshot.hasData) {
                                                    return Image.memory(
                                                      snapshot.data!,
                                                      fit: BoxFit.cover,
                                                    );
                                                  }
                                                  return const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  );
                                                },
                                              )
                                              : Image.file(
                                                File(
                                                  _selectedImages[index].path,
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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
