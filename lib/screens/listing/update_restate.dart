// car_form.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary/cloudinary.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'db_helper.dart'; // Assuming this is your database helper
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class Restate extends StatefulWidget {
  final Map<String, dynamic>? listingData;
  final bool isEditing;

  Restate({this.listingData, this.isEditing = false});

  @override
  _Restate createState() => _Restate();
}

class _Restate extends State<Restate> {
  final SecureStorage secureStorage = SecureStorage();
  String query = '';
  bool selectedPreference = false;
  final numberFormat = NumberFormat.decimalPattern();
  final GlobalKey<FormState> _localFormKey = GlobalKey<FormState>();
  final MapController mapController = MapController();
  final TextEditingController addressController = TextEditingController();
  LatLng? latLng;
  String apiKey = 'pk.3fd6672dce74ac1387a84418c3a23c49';
  List<Map<String, dynamic>> locations = [];
  final ImagePicker _picker = ImagePicker();
  List<XFile>? _imageFiles = [];
  List<XFile>? _DocFiles = [];
  List<String> cloudinaryImageUrls = [];
  List<String> cloudinaryDocumentUrls = [];

  double totalPaymentMade = 0.0;

  final cloudinary = Cloudinary.signedConfig(
    apiKey: '713443683486728',
    apiSecret: 'gKCMD_fCso--h1CIyPGxTWsp9As',
    cloudName: 'dqfvxj9h0',
  );

  final List<String> years =
      List.generate(30, (index) => (DateTime.now().year - index).toString())
          .toList();
  String? selectedYear,
      selectedBedrooms,
      selectedBathrooms,
      selectedParkingSpace;
  String? customMake;
  String? customModel;
  final List<Color> colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.black,
    Colors.white,
    Colors.grey
  ];
  Color? selectedColor;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController floorareaController = TextEditingController();
  final TextEditingController lotareaController = TextEditingController();
  final TextEditingController monthlyPaymentController =
      TextEditingController();
  final TextEditingController loanDurationController = TextEditingController();
  final TextEditingController downPaymentController = TextEditingController();
  final TextEditingController reservationController = TextEditingController();
  final TextEditingController numberOfMonthsPaidController =
      TextEditingController();

  @override
  void dispose() {
    // Dispose controllers
    titleController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    monthlyPaymentController.dispose();
    loanDurationController.dispose();
    downPaymentController.dispose();
    numberOfMonthsPaidController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    fetchCoordinates("Cebu");
    if (!widget.isEditing) {
      _initializeNewListing();
    } else if (widget.listingData != null) {
      _initializeEditingListing();
    }
  }

  void _initializeNewListing() {
    // Initialize controllers with default empty values
    titleController.text = '';
    priceController.text = '';
    addressController.text = '';
    descriptionController.text = '';
    lotareaController.text = '';
    floorareaController.text = '';
    downPaymentController.text = '';
    loanDurationController.text = '';
    monthlyPaymentController.text = '';
    numberOfMonthsPaidController.text = '';

    // Initialize dropdown or selection values
    selectedBedrooms = null; // Default no selection for Bedrooms
    selectedBathrooms = null; // Default no selection for Bathrooms
    selectedParkingSpace = null; // Default no selection for Parking Space
    selectedPreference = false; // Default no selection for Preference

    // Initialize empty lists for images and documents
    cloudinaryImageUrls = [];
    // cloudinaryDocumentUrls = [];
    _imageFiles = [];
    _DocFiles = [];
  }

  void _initializeEditingListing() {
    final data = widget.listingData!;

    titleController.text = data['title'] ?? '';
    priceController.text = data['price'] != null
        ? numberFormat.format(double.tryParse(data['price'].toString()) ?? 0)
        : '';
    addressController.text = data['address'] ?? '';
    descriptionController.text = data['description'] ?? '';
    lotareaController.text = data['lotArea'] ?? '';
    floorareaController.text = data['floorArea'] ?? '';
    selectedBedrooms = data['bedrooms'];
    selectedBathrooms = data['bathrooms'];

    selectedYear = data['year'];
    selectedParkingSpace = data['parkingSpace'];
    if (data['offer_allowed'] is bool) {
      selectedPreference = data['offer_allowed'];
    } else if (data['offer_allowed'] is String) {
      selectedPreference = data['offer_allowed'] == 'true';
    } else {
      selectedPreference = false; // Default fallback
    }

    reservationController.text = data['reservation'] != null
        ? numberFormat
            .format(double.tryParse(data['reservation'].toString()) ?? 0)
        : '';
    downPaymentController.text = data['downPayment'] != null
        ? numberFormat
            .format(double.tryParse(data['downPayment'].toString()) ?? 0)
        : '';
    loanDurationController.text = data['loanDuration']?.toString() ?? '';
    monthlyPaymentController.text = data['monthlyPayment'] != null
        ? numberFormat
            .format(double.tryParse(data['monthlyPayment'].toString()) ?? 0)
        : '';
    numberOfMonthsPaidController.text =
        data['numberOfMonthsPaid']?.toString() ?? '';
    cloudinaryImageUrls = List.from(data['images'] ?? []);
    // cloudinaryDocumentUrls = List.from(data['documents'] ?? []);
    _computeTotalPayment();
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Validation Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _formatAndSetText(String value, TextEditingController controller) {
    if (value.isNotEmpty) {
      final formatted =
          numberFormat.format(int.parse(value.replaceAll(',', '')));
      controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  Future<void> deleteImageFromCloudinary(String publicId) async {
    final String cloudinaryUrl =
        'https://api.cloudinary.com/v1_1/dqfvxj9h0/image/destroy';

    // Construct the body payload
    final body = {
      'public_id': publicId,
    };

    // Perform the authenticated request
    final response = await http.post(
      Uri.parse(cloudinaryUrl),
      headers: {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('713443683486728:gKCMD_fCso--h1CIyPGxTWsp9As'))}',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );

    // Handle the response
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['result'] == 'ok') {
        print('Image deleted successfully.');
      } else {
        print('Error deleting image: ${jsonResponse['error']}');
      }
    } else {
      print('Failed to delete image: ${response.statusCode}');
    }
  }

  void _showRetrySnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () {
            // Optionally, you can trigger the fetchCoordinates again here
            // For example, by calling fetchCoordinates with the current query
            fetchCoordinates(query); // Ensure to pass the current query
          },
        ),
      ),
    );
  }

  Future<void> fetchCoordinates(String query) async {
    try {
      // Append "Cebu" to the query to improve API results
      final adjustedQuery = '$query, Cebu';

      final response = await http.get(Uri.parse(
          'https://us1.locationiq.com/v1/search?key=$apiKey&q=$adjustedQuery&format=json'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Filter locations to only include addresses containing 'Cebu'
        final filteredLocations = data.where((location) {
          final displayName = location['display_name']?.toLowerCase() ?? '';
          return displayName.contains('cebu');
        }).toList();

        setState(() {
          locations = List<Map<String, dynamic>>.from(filteredLocations);
        });

        if (locations.isNotEmpty) {
          final lat = double.parse(locations[0]['lat']);
          final lon = double.parse(locations[0]['lon']);
          latLng = LatLng(lat, lon);
          mapController.move(latLng!, 13.0);
        } else {
          // Clear the map if no Cebu results are found
          setState(() {
            latLng = null;
          });
        }
      }
    } catch (error) {
      // Optionally log or handle the error here
    }
  }

  Future<void> fetchAddressFromLatLng(LatLng latLng) async {
    final response = await http.get(Uri.parse(
        'https://us1.locationiq.com/v1/reverse?key=$apiKey&lat=${latLng.latitude}&lon=${latLng.longitude}&format=json'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        addressController.text = data['display_name'];
        this.latLng = latLng;
      });
    } else {
      throw Exception('Failed to fetch address');
    }
  }

  Widget buildImageUploader() {
    return Column(
      children: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.blueAccent, width: 1.5),
          ),
          onPressed: _pickAndUploadImages,
          child:
              Text('Select Photos', style: TextStyle(color: Colors.blueAccent)),
        ),
        SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Display existing Cloudinary URLs and uploaded images
            ...cloudinaryImageUrls.asMap().entries.map((entry) {
              int index = entry.key;
              String url = entry.value;

              return Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.blueAccent.withOpacity(0.5),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(url),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () async {
                      String publicIdToRemove =
                          url.split('/').last.split('.').first;

                      try {
                        await deleteImageFromCloudinary(publicIdToRemove);
                        print(
                            'Image deleted from Cloudinary: $publicIdToRemove');
                        setState(() {
                          cloudinaryImageUrls.removeAt(index);
                        });
                      } catch (e) {
                        print('Error deleting image: $e');
                      }
                    },
                  ),
                ],
              );
            }),
            // Display only processing images
            ...(_imageFiles ?? []).asMap().entries.map((entry) {
              int fileIndex = entry.key;
              XFile file = entry.value;
              // Only show images that haven't been uploaded to Cloudinary yet
              if (fileIndex < cloudinaryImageUrls.length) return Container();

              return Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.blueAccent.withOpacity(0.5),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[300],
                    ),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  IconButton(
                    icon: Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _imageFiles!.removeAt(fileIndex);
                      });
                    },
                  ),
                ],
              );
            }),
          ],
        ),
        SizedBox(height: 30),
        if (_imageFiles != null &&
            _imageFiles!.length > cloudinaryImageUrls.length)
          Text('Images still processing',
              style: TextStyle(color: Colors.orange)),
      ],
    );
  }

  Future<void> _pickAndUploadImages() async {
    if (_imageFiles != null && _imageFiles!.length >= 15) {
      // Show an alert or message indicating the limit has been reached
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You can only upload up to 15 images.')),
      );
      return;
    }

    PermissionStatus permissionStatus = await Permission.photos.request();

    if (permissionStatus.isGranted) {
      final List<XFile>? selectedImages = await _picker.pickMultiImage();
      if (selectedImages != null && selectedImages.isNotEmpty) {
        // Ensure total images do not exceed 15
        final totalImages = _imageFiles!.length + selectedImages.length;
        if (totalImages > 15) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You can only upload up to 15 images.')),
          );
          return;
        }

        setState(() {
          _imageFiles ??= [];
          _imageFiles!.addAll(selectedImages);
        });
        // PermissionStatus permissionStatus = await Permission.photos.request();

        // if (permissionStatus.isGranted) {
        //   final List<XFile>? selectedImages = await _picker.pickMultiImage();
        //   if (selectedImages != null && selectedImages.isNotEmpty) {
        //     setState(() {
        //       _imageFiles ??= [];
        //       _imageFiles!.addAll(selectedImages);
        //     });

        for (var file in selectedImages) {
          if (file.path != null) {
            try {
              final response = await cloudinary.upload(
                file: file.path!,
                folder: 'car_listings',
                resourceType: CloudinaryResourceType.image,
              );

              if (response.isSuccessful && response.secureUrl != null) {
                setState(() {
                  cloudinaryImageUrls.add(response.secureUrl!);
                });
                print('Image uploaded to Cloudinary: ${response.secureUrl}');
              } else {
                print('Error uploading to Cloudinary: ${response.error}');
                setState(() {
                  _imageFiles!.remove(file);
                });
              }
            } catch (e) {
              print('Error during upload: $e');
              setState(() {
                _imageFiles!.remove(file);
              });
            }
          }
        }
      }
    } else if (permissionStatus.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permission to access storage is required.')),
      );
    } else if (permissionStatus.isPermanentlyDenied) {
      bool? openSettings = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Permission Needed'),
          content: Text(
            'Permission to access storage is permanently denied. Please enable it in the app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Open Settings'),
            ),
          ],
        ),
      );

      if (openSettings == true) {
        openAppSettings();
      }
    }
  }

  void _computeTotalPayment() {
    // Remove commas before parsing to ensure proper conversion
    double downPayment =
        double.tryParse(downPaymentController.text.replaceAll(',', '')) ?? 0.0;
    double monthlyPayment =
        double.tryParse(monthlyPaymentController.text.replaceAll(',', '')) ??
            0.0;
    int numberOfMonthsPaid =
        int.tryParse(numberOfMonthsPaidController.text.replaceAll(',', '')) ??
            0;

    setState(() {
      totalPaymentMade = downPayment + (monthlyPayment * numberOfMonthsPaid);
    });
  }

  Widget _buildDocumentUploader() {
    return Column(
      children: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.blueAccent, width: 1.5),
          ),
          onPressed: () async {
            // Check if the document limit is reached
            if (_DocFiles != null && _DocFiles!.length >= 10) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('You can only upload up to 10 documents.')),
              );
              return; // Exit if the limit is reached
            }

            FilePickerResult? result = await FilePicker.platform.pickFiles(
              allowMultiple: true,
              type: FileType.custom,
              allowedExtensions: ['pdf', 'docx', 'jpg', 'png'],
            );

            if (result != null) {
              for (PlatformFile file in result.files) {
                if (_DocFiles!.length >= 10) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'You can only upload up to 10 documents. Remaining files ignored.'),
                    ),
                  );
                  break; // Prevent adding more than 5 files
                }
              }
            }
            if (result != null) {
              for (PlatformFile file in result.files) {
                if (file.path != null) {
                  final response = await cloudinary.upload(
                    file: file.path!,
                    folder: 'ownership_documents',
                    resourceType: CloudinaryResourceType.auto,
                  );

                  if (response.isSuccessful && response.secureUrl != null) {
                    setState(() {
                      if (!cloudinaryDocumentUrls
                          .contains(response.secureUrl!)) {
                        cloudinaryDocumentUrls.add(response.secureUrl!);
                        _DocFiles!.add(XFile(file.path!));
                      }
                    });
                  } else {
                    print('Error uploading to Cloudinary: ${response.error}');
                  }
                }
              }
            } else {
              print('File picking canceled.');
            }
          },
          child: Text('Upload Ownership Proof Documents',
              style: TextStyle(color: Colors.blueAccent)),
        ),
        SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // First, map through _DocFiles
            ..._DocFiles!.asMap().entries.map((entry) {
              int index = entry.key;
              XFile file = entry.value;
              String fileExtension = file.path!.split('.').last.toLowerCase();
              bool isImage = fileExtension == 'png' || fileExtension == 'jpg';

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.blueAccent.withOpacity(0.5),
                          width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                      color: isImage ? null : Colors.white,
                      image: isImage && cloudinaryDocumentUrls.length > index
                          ? DecorationImage(
                              image:
                                  NetworkImage(cloudinaryDocumentUrls[index]),
                              fit: BoxFit.cover)
                          : null,
                    ),
                    child: !isImage
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.description,
                                  size: 40, color: Colors.blueAccent),
                              SizedBox(height: 5),
                              Text(
                                file.name,
                                style: TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                fileExtension.toUpperCase(),
                                style:
                                    TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          )
                        : null,
                  ),
                  Positioned(
                    top: -5,
                    right: -5,
                    child: IconButton(
                      icon: Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () async {
                        if (cloudinaryDocumentUrls.length > index) {
                          String cloudinaryUrl = cloudinaryDocumentUrls[index];
                          String publicIdToRemove =
                              cloudinaryUrl.split('/').last.split('.').first;

                          try {
                            await deleteImageFromCloudinary(publicIdToRemove);
                            print(
                                'Document deleted from Cloudinary: $publicIdToRemove');
                          } catch (e) {
                            print('Error deleting document: $e');
                          }

                          setState(() {
                            _DocFiles!.removeAt(index);
                            cloudinaryDocumentUrls.removeAt(index);
                          });
                        }
                      },
                    ),
                  ),
                ],
              );
            }).toList(),

            // Then, add any remaining Cloudinary URLs that don't have corresponding local files
            ...List.generate(
              cloudinaryDocumentUrls.length,
              (index) {
                // Skip if this URL already has a corresponding local file
                if (index < _DocFiles!.length) {
                  return Container(); // Return empty container for URLs that have local files
                }

                String url = cloudinaryDocumentUrls[index];
                String fileExtension = url.split('.').last.toLowerCase();
                bool isImage = fileExtension == 'jpg' || fileExtension == 'png';

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.blueAccent.withOpacity(0.5),
                            width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                        color: isImage ? null : Colors.white,
                        image: isImage
                            ? DecorationImage(
                                image: NetworkImage(url),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: !isImage
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.description,
                                    size: 40, color: Colors.blueAccent),
                                SizedBox(height: 5),
                                Text(
                                  url.split('/').last,
                                  style: TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  fileExtension.toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            )
                          : null,
                    ),
                    Positioned(
                      top: -5,
                      right: -5,
                      child: IconButton(
                        icon: Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () async {
                          String publicIdToRemove =
                              url.split('/').last.split('.').first;
                          try {
                            await deleteImageFromCloudinary(publicIdToRemove);
                            print(
                                'Document deleted from Cloudinary: $publicIdToRemove');
                            setState(() {
                              cloudinaryDocumentUrls.removeAt(index);
                            });
                          } catch (e) {
                            print('Error deleting document: $e');
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ).where((widget) => widget is Stack).toList(),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final OutlineInputBorder borderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30.0),
      borderSide: const BorderSide(color: Colors.black),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Listing' : 'Add Listing'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _localFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 15),
                const Text(
                  "Listing Details:",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    floatingLabelStyle:
                        const TextStyle(color: Color(0xff4A8AF0)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    enabledBorder: borderStyle,
                    focusedBorder: borderStyle,
                    border: borderStyle,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      _showAlert('Please enter a title');
                      return 'Please enter a title'; // Prevent form submission
                    }

                    // Regular expression to allow only letters, numbers, and spaces
                    final regex = RegExp(r'^[a-zA-Z0-9\s]+$');
                    if (!regex.hasMatch(value)) {
                      _showAlert(
                          'Title contains invalid characters. Only letters, numbers, and spaces are allowed.');
                      return 'Invalid characters in title'; // Prevent form submission
                    }

                    return null; // No validation error
                  },
                ),
                const SizedBox(
                  height: 15.0,
                ),

                TextFormField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: 'Price',
                    floatingLabelStyle:
                        const TextStyle(color: Color(0xff4A8AF0)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    enabledBorder: borderStyle,
                    focusedBorder: borderStyle,
                    border: borderStyle,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      _showAlert('Please enter a price');
                      return 'Please enter a price'; // Prevent form submission
                    }

                    final price = int.tryParse(value.replaceAll(',', ''));
                    if (price == null || price <= 0) {
                      _showAlert('Price must be a positive value');
                      return 'Price must be a positive value'; // Prevent form submission
                    } else if (price > totalPaymentMade) {
                      _showAlert(
                          'Price must not exceed total payment made (\₱${numberFormat.format(totalPaymentMade)})');
                      return 'Price must not exceed total payment made'; // Prevent form submission
                    }
                    return null; // No validation error
                  },
                  onChanged: (value) {
                    _formatAndSetText(value, priceController);
                  },
                ),
                const SizedBox(
                  height: 15.0,
                ),
                Align(
                  alignment:
                      Alignment.centerLeft, // Aligns everything to the right
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment
                        .start, // Keeps elements aligned to the left within the column
                    children: [
                      DropdownButtonHideUnderline(
                          child: DropdownButton2<String>(
                        isExpanded: true,
                        buttonStyleData: ButtonStyleData(
                          padding: const EdgeInsets.only(right: 18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30.0),
                            border: Border.all(color: Colors.black),
                          ),
                        ),
                        value: selectedYear,
                        hint: const Text('Select Year'),
                        items:
                            years.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedYear = value;
                          });
                        },
                      )),
                      const SizedBox(
                        height: 15.0,
                      ),
                      DropdownButtonHideUnderline(
                          child: DropdownButton2<String>(
                        isExpanded: true,
                        buttonStyleData: ButtonStyleData(
                          padding: const EdgeInsets.only(right: 18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30.0),
                            border: Border.all(color: Colors.black),
                          ),
                        ),
                        value: selectedBedrooms,
                        hint: const Text('Bedrooms (Optional)'),
                        items: [
                          '0 Bedrooms',
                          '1 Bedroom',
                          '2 Bedrooms',
                          '3 Bedrooms',
                          '4 Bedrooms',
                          '5 Bedrooms',
                          '5+ Bedrooms'
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedBedrooms = value;
                          });
                        },
                      )),
                      const SizedBox(
                        height: 15.0,
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton2<String>(
                          isExpanded: true,
                          buttonStyleData: ButtonStyleData(
                            padding: const EdgeInsets.only(right: 18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30.0),
                              border: Border.all(color: Colors.black),
                            ),
                          ),
                          value: selectedBathrooms,
                          hint: const Text('Bathrooms (Optional)'),
                          items: [
                            '0 Bathrooms',
                            '1 Bathrooms',
                            '2 Bathrooms',
                            '3 Bathrooms',
                            '4 Bathrooms',
                            '5 Bathrooms',
                            '5+ Bathrooms'
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedBathrooms = value;
                            });
                          },
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 10.0,
                ),
                TextFormField(
                  controller: floorareaController,
                  decoration: InputDecoration(
                    labelText: 'Floor Area',
                    suffixText: 'sqm',
                    floatingLabelStyle:
                        const TextStyle(color: Color(0xff4A8AF0)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    enabledBorder: borderStyle,
                    focusedBorder: borderStyle,
                    border: borderStyle,
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a floor area in sqm';
                    } else if (double.tryParse(value) == null ||
                        double.parse(value) <= 0) {
                      return 'Please enter a value greater than zero';
                    }
                    return null;
                  },
                ),
                const SizedBox(
                  height: 10.0,
                ),
                TextFormField(
                  controller: lotareaController,
                  decoration: InputDecoration(
                    labelText: 'Lot Area (Optional)',
                    suffixText: 'sqm',
                    floatingLabelStyle:
                        const TextStyle(color: Color(0xff4A8AF0)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    enabledBorder: borderStyle,
                    focusedBorder: borderStyle,
                    border: borderStyle,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return 'Please enter a value greater than zero';
                      }
                    }
                    return null; // Allows optional empty field
                  },
                ),
                const SizedBox(
                  height: 10.0,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Parking Space (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                      ), // Customize the style as needed
                    ),
                    const SizedBox(
                        height:
                            8), // Add some space between the text and the chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ChoiceChip(
                          label: const Text('0'),
                          backgroundColor: const Color(0xffFFFCF1),
                          selectedColor: const Color(0xff4A8AF0),
                          showCheckmark: false,
                          labelStyle: TextStyle(
                            color: selectedParkingSpace == '0'
                                ? Colors.white
                                : Colors.black,
                          ),
                          selected: selectedParkingSpace == '0',
                          onSelected: (selected) {
                            setState(() => selectedParkingSpace = '0');
                          },
                        ),
                        ChoiceChip(
                          label: const Text('1'),
                          backgroundColor: const Color(0xffFFFCF1),
                          selectedColor: const Color(0xff4A8AF0),
                          showCheckmark: false,
                          labelStyle: TextStyle(
                            color: selectedParkingSpace == '1'
                                ? Colors.white
                                : Colors.black,
                          ),
                          selected: selectedParkingSpace == '1',
                          onSelected: (selected) {
                            setState(() => selectedParkingSpace = '1');
                          },
                        ),
                        ChoiceChip(
                          label: const Text('2'),
                          backgroundColor: const Color(0xffFFFCF1),
                          selectedColor: const Color(0xff4A8AF0),
                          showCheckmark: false,
                          labelStyle: TextStyle(
                            color: selectedParkingSpace == '2'
                                ? Colors.white
                                : Colors.black,
                          ),
                          selected: selectedParkingSpace == '2',
                          onSelected: (selected) {
                            setState(() => selectedParkingSpace = '2');
                          },
                        ),
                        ChoiceChip(
                          label: const Text('2+'),
                          backgroundColor: const Color(0xffFFFCF1),
                          selectedColor: const Color(0xff4A8AF0),
                          showCheckmark: false,
                          labelStyle: TextStyle(
                            color: selectedParkingSpace == '2+'
                                ? Colors.white
                                : Colors.black,
                          ),
                          selected: selectedParkingSpace == '2+',
                          onSelected: (selected) {
                            setState(() => selectedParkingSpace = '2+');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10.0,
                ),

                /// Address Field
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    controller: addressController,
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        fetchCoordinates(value);
                      } else {
                        setState(() {
                          locations.clear();
                        });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Enter an Address',
                      floatingLabelStyle:
                          const TextStyle(color: Color(0xff4A8AF0)),
                      contentPadding: const EdgeInsets.only(
                          left: 18, right: 15, top: 10, bottom: 10),
                      enabledBorder: borderStyle,
                      focusedBorder: borderStyle,
                      border: borderStyle,
                    ),
                  ),
                ),

// Suggestions List (Only show if there is input and locations are available)
                if (addressController.text.isNotEmpty && locations.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: locations.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(locations[index]['display_name']),
                        onTap: () {
                          final lat = double.parse(locations[index]['lat']);
                          final lon = double.parse(locations[index]['lon']);
                          setState(() {
                            latLng = LatLng(lat, lon);
                            mapController.move(latLng!, 13.0);
                            addressController.text =
                                locations[index]['display_name'];
                            locations.clear();
                          });
                        },
                      );
                    },
                  ),
                // Map Display
                Container(
                  height: 300, // Set your desired height
                  child: FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      onTap: (tapPosition, point) {
                        fetchAddressFromLatLng(point);
                        mapController.move(point, 13.0);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                        subdomains: ['a', 'b', 'c'],
                      ),
                      if (latLng != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: latLng!,
                              width: 80.0,
                              height: 80.0,
                              child: Container(
                                child: const Icon(Icons.location_on,
                                    color: Colors.red, size: 40),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),
                const Text(
                  "Payment Details:",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: monthlyPaymentController,
                  decoration: InputDecoration(
                    labelText: 'Monthly Payment',
                    floatingLabelStyle:
                        const TextStyle(color: Color(0xff4A8AF0)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    enabledBorder: borderStyle,
                    focusedBorder: borderStyle,
                    border: borderStyle,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a monthly payment';
                    } else if (int.tryParse(value.replaceAll(',', '')) == 0) {
                      return 'Monthly payment cannot be zero';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _formatAndSetText(value, monthlyPaymentController);
                    _computeTotalPayment();
                  },
                ),

                const SizedBox(height: 15),
                TextFormField(
                  controller: loanDurationController,
                  decoration: InputDecoration(
                    labelText: 'Loan Duration (Months)',
                    floatingLabelStyle:
                        const TextStyle(color: Color(0xff4A8AF0)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    enabledBorder: borderStyle,
                    focusedBorder: borderStyle,
                    border: borderStyle,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      _showAlert('Please enter a loan duration');
                      return 'Please enter a loan duration'; // Prevent form submission
                    }

                    final duration = int.tryParse(value.replaceAll(',', ''));
                    if (duration == null || duration < 12 || duration > 360) {
                      _showAlert(
                          'Loan duration must be between 12 and 360 months');
                      return 'Loan duration must be between 12 and 360 months'; // Prevent form submission
                    }

                    final monthsPaid = int.tryParse(
                        numberOfMonthsPaidController.text.replaceAll(',', ''));
                    if (monthsPaid != null && monthsPaid > duration) {
                      return 'Number of months paid cannot exceed loan duration'; // Prevent form submission
                    }
                    return null; // No validation error
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Total Payment Made: \₱${numberFormat.format(totalPaymentMade)}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                TextFormField(
                  controller: downPaymentController,
                  decoration: InputDecoration(
                    labelText: 'Down Payment',
                    floatingLabelStyle:
                        const TextStyle(color: Color(0xff4A8AF0)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    enabledBorder: borderStyle,
                    focusedBorder: borderStyle,
                    border: borderStyle,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a down payment';
                    }
                    final downPayment = int.tryParse(value.replaceAll(',', ''));

                    if (downPayment == null) {
                      return 'Please enter a valid number';
                    } else if (downPayment < 0) {
                      return 'Down payment cannot be less than zero';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _formatAndSetText(value, downPaymentController);
                    _computeTotalPayment();
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: numberOfMonthsPaidController,
                  decoration: InputDecoration(
                    labelText: 'Number of Months Paid',
                    floatingLabelStyle:
                        const TextStyle(color: Color(0xff4A8AF0)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    enabledBorder: borderStyle,
                    focusedBorder: borderStyle,
                    border: borderStyle,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      _showAlert('Please enter the number of months paid');
                      return 'Please enter the number of months paid'; // Prevent form submission
                    }

                    final monthsPaid = int.tryParse(value.replaceAll(',', ''));
                    if (monthsPaid == null || monthsPaid <= 0) {
                      _showAlert(
                          'Number of months paid must be greater than zero');
                      return 'Number of months paid must be greater than zero'; // Prevent form submission
                    }

                    final loanDuration = int.tryParse(
                        loanDurationController.text.replaceAll(',', ''));
                    if (loanDuration != null && monthsPaid > loanDuration) {
                      _showAlert(
                          'Number of months paid cannot exceed loan duration ($loanDuration)');
                      return 'Number of months paid cannot exceed loan duration'; // Prevent form submission
                    }
                    return null; // No validation error
                  },
                  onChanged: (value) {
                    _formatAndSetText(value, numberOfMonthsPaidController);
                    _computeTotalPayment();
                  },
                ),
                SizedBox(height: 10),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.start, // Centers the ChoiceChip
                  children: [
                    const Text(
                      "Sale Preference:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10),
                    ChoiceChip(
                      backgroundColor: const Color(0xffFFFCF1),
                      label: Text('Allow Offers'),
                      showCheckmark: true, // Shows a checkmark when selected
                      selected:
                          selectedPreference, // Directly uses the boolean value
                      onSelected: (bool selected) {
                        setState(() {
                          selectedPreference = selected; // Updates the boolean
                        });
                      },
                      selectedColor: const Color(0xff4A8AF0),
                      labelStyle: TextStyle(
                        color: selectedPreference ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: reservationController,
                  decoration: InputDecoration(
                    labelText: 'Reservation Fee',
                    floatingLabelStyle:
                        const TextStyle(color: Color(0xff4A8AF0)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    enabledBorder: borderStyle,
                    focusedBorder: borderStyle,
                    border: borderStyle,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a reservation fee';
                    }

                    final reservation = int.tryParse(value.replaceAll(',', ''));
                    final price =
                        int.tryParse(priceController.text.replaceAll(',', ''));

                    if (reservation == null) {
                      return 'Please enter a valid number';
                    } else if (reservation < 0) {
                      return 'Reservation fee cannot be less than zero';
                    } else if (price == null || price <= 0) {
                      return 'Please enter a valid price first';
                    } else {
                      final minReservation = price * 0.2; // 20% of the price
                      final maxReservation = price * 0.5; // 50% of the price

                      if (reservation < minReservation) {
                        return 'Reservation fee must be at least 20% of the price';
                      } else if (reservation > maxReservation) {
                        return 'Reservation fee cannot exceed 50% of the price';
                      }
                    }

                    return null; // No validation error
                  },
                  onChanged: (value) {
                    _formatAndSetText(value, reservationController);
                  },
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Put Description here',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    enabledBorder: borderStyle.copyWith(
                        borderRadius: BorderRadius.circular(15)),
                    focusedBorder: borderStyle.copyWith(
                        borderRadius: BorderRadius.circular(15)),
                    border: borderStyle.copyWith(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                const SizedBox(
                  height: 10.0,
                ),
                // _buildDocumentUploader(), // Space between sections
                buildImageUploader(),
                ElevatedButton(
                  onPressed: () async {
                    if (_localFormKey.currentState!.validate()) {
                      // Check if images are uploaded
                      if (cloudinaryImageUrls == null ||
                          cloudinaryImageUrls!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Please select at least one image')),
                        );
                        return;
                      }
                      if (selectedYear == null || selectedYear!.isEmpty) {
                        // Show an alert or a message indicating that the year is required
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please select a year')),
                        );
                        return;
                      }
                      if (selectedPreference == null) {
                        // Show an alert or a message indicating that the selection is required
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Please select a sale preference')),
                        );
                        return;
                      }
                      if (addressController.text.isEmpty) {
                        // Show a message if the address is empty
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please enter an address')),
                        );
                        return;
                      }

                      // Check if images are still uploading (i.e., URLs are not available yet)
                      if (cloudinaryImageUrls.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Your images are still uploading')),
                        );
                        return;
                      }

                      // Prepare the listing content
                      Map<String, dynamic> listingContent = {
                        'category': 'Real Estate',
                        'title': titleController.text,
                        'year': selectedYear,
                        'address': addressController.text,
                        'offer_allowed': selectedPreference,
                        'price': double.tryParse(
                                priceController.text.replaceAll(',', '')) ??
                            0.0,
                        'reservation': double.tryParse(reservationController
                                .text
                                .replaceAll(',', '')) ??
                            0.0,
                        'bedrooms': selectedBedrooms ??
                            '', // This will be added with empty string if null
                        'bathrooms': selectedBathrooms ??
                            '', // This will be added with empty string if null
                        'floorArea': floorareaController
                            .text, // This will be added even if empty
                        'lotArea': lotareaController
                            .text, // This will be added even if empty
                        'parkingSpace': selectedParkingSpace ??
                            '', // This will be added with empty string if null
                        'description': descriptionController.text,
                        'monthlyPayment': double.tryParse(
                                monthlyPaymentController.text
                                    .replaceAll(',', '')) ??
                            0.0,
                        'loanDuration': loanDurationController.text,
                        'totalPaymentMade': totalPaymentMade,
                        'downPayment': double.tryParse(downPaymentController
                                .text
                                .replaceAll(',', '')) ??
                            0.0,
                        'numberOfMonthsPaid': double.tryParse(
                                numberOfMonthsPaidController.text
                                    .replaceAll(',', '')) ??
                            0.0,
                        'images': cloudinaryImageUrls, // Store Cloudinary URLs
                        // 'documents': cloudinaryDocumentUrls,
                      };
                      // Debug print to check content before submitting
                      // Connect to the database and add the listing
                      DatabaseService dbService = DatabaseService();
                      try {
                        final token = await secureStorage.getToken();
                        await dbService.addCarListing(token!, listingContent);
                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Submitted Successfully')),
                        );

                        // Navigate back to the previous screen
                        Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      foregroundColor: const Color(0xffFFFCF1),
                      backgroundColor: const Color(0xff4A8AF0)),
                  child: const Text('Submit for Review'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
