// car_form.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary/cloudinary.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'db_helper.dart'; // Assuming this is your database helper
import 'car_data.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class CarForm extends StatefulWidget {
  @override
  _CarFormState createState() => _CarFormState();
}

class _CarFormState extends State<CarForm> {
  final SecureStorage secureStorage = SecureStorage();
  String query = '';
  String? selectedPreference; // No default value
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
      List.generate(7, (index) => (DateTime.now().year - index).toString())
          .toList();
  String? selectedYear,
      selectedTransmission,
      selectedFuelType,
      selectedMileageRange,
      selectedMake,
      selectedModel;
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
  final TextEditingController monthlyPaymentController =
      TextEditingController();
  final TextEditingController loanDurationController = TextEditingController();
  final TextEditingController downPaymentController = TextEditingController();
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
    addressController.dispose();
    super.dispose();
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

  void _formatAndSetText(String value, TextEditingController controller) {
    if (value.isNotEmpty) {
      String rawValue = value.replaceAll(',', ''); // Remove commas
      String formattedValue =
          numberFormat.format(int.parse(rawValue)); // Format with commas
      controller.value = TextEditingValue(
        text: formattedValue,
        selection: TextSelection.collapsed(offset: formattedValue.length),
      );
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

  @override
  void initState() {
    super.initState();
    fetchCoordinates("Cebu");
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
          children: _imageFiles!.map((file) {
            int fileIndex = _imageFiles!.indexOf(file);
            bool isProcessing = cloudinaryImageUrls.length <= fileIndex;

            return Stack(
              alignment: Alignment.topRight,
              children: [
                isProcessing
                    ? Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.blueAccent.withOpacity(0.5),
                              width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[300],
                        ),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.blueAccent.withOpacity(0.5),
                              width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(File(file.path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                if (!isProcessing)
                  IconButton(
                    icon: Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () async {
                      final indexToRemove = _imageFiles!.indexOf(file);

                      if (indexToRemove != -1 &&
                          indexToRemove < cloudinaryImageUrls.length) {
                        String cloudinaryUrl =
                            cloudinaryImageUrls[indexToRemove];
                        String publicIdToRemove =
                            cloudinaryUrl.split('/').last.split('.').first;

                        try {
                          await deleteImageFromCloudinary(publicIdToRemove);
                          print(
                              'Image deleted from Cloudinary: $publicIdToRemove');
                        } catch (e) {
                          print('Error deleting image: $e');
                        }

                        setState(() {
                          _imageFiles!.removeAt(indexToRemove);
                          cloudinaryImageUrls.removeAt(indexToRemove);
                        });
                      } else {
                        setState(() {
                          _imageFiles!.remove(file);
                        });
                      }
                    },
                  ),
              ],
            );
          }).toList(),
        ),
        SizedBox(height: 30),
        if (cloudinaryImageUrls.length < _imageFiles!.length)
          Text('Images still processing',
              style: TextStyle(color: Colors.orange)),
      ],
    );
  }

// Pick and Upload Images to Cloudinary
  Future<void> _pickAndUploadImages() async {
    PermissionStatus permissionStatus = await Permission.photos.request();

    if (permissionStatus.isGranted) {
      final List<XFile>? selectedImages = await _picker.pickMultiImage();
      if (selectedImages != null && selectedImages.isNotEmpty) {
        setState(() {
          _imageFiles!.addAll(selectedImages);
        });

        // Make sure all images are uploaded and URLs are captured
        for (var file in selectedImages) {
          if (file.path != null) {
            // Start the image upload process
            final response = await cloudinary.upload(
              file: file.path!,
              folder: 'car_listings',
              resourceType: CloudinaryResourceType.image,
            );

            if (response.isSuccessful && response.secureUrl != null) {
              setState(() {
                cloudinaryImageUrls
                    .add(response.secureUrl!); // Update the URLs after upload
              });
              print('Image uploaded to Cloudinary: ${response.secureUrl}');
            } else {
              print('Error uploading to Cloudinary: ${response.error}');
            }
          }
        }

        // After upload completes, check if the image URLs are available
        if (cloudinaryImageUrls.isEmpty) {
          print('Your images are still uploading');
        } else {
          print('All images uploaded successfully: $cloudinaryImageUrls');
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
              'Permission to access storage is permanently denied. Please enable it in the app settings.'),
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

  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Select Color:',
            style: TextStyle(fontSize: 16),
          ),
        ),
        Wrap(
          spacing: 1,
          children: colors.map((color) {
            return ChoiceChip(
              backgroundColor: const Color(0xffFFFCF1),
              padding: EdgeInsets.zero,
              label: Container(width: 20, height: 20, color: color),
              selected: selectedColor == color,
              showCheckmark: false,
              onSelected: (selected) {
                setState(() {
                  selectedColor = selected ? color : null;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDocumentUploader() {
    return Column(
      children: [
        // Upload Button with matching OutlinedButton styling
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.blueAccent, width: 1.5),
          ),
          onPressed: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles(
              allowMultiple: true,
              type: FileType.custom,
              allowedExtensions: ['pdf', 'docx', 'jpg', 'png'],
            );

            if (result != null) {
              for (PlatformFile file in result.files) {
                if (file.path != null) {
                  setState(() {
                    _DocFiles!.add(XFile(file.path!)); // Add file to the list
                  });

                  final response = await cloudinary.upload(
                    file: file.path!,
                    folder: 'ownership_documents',
                    resourceType: CloudinaryResourceType.auto,
                  );

                  if (response.isSuccessful && response.secureUrl != null) {
                    setState(() {
                      cloudinaryDocumentUrls
                          .add(response.secureUrl!); // Add URL to the list
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

        // Document Thumbnails Display
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _DocFiles!.map((file) {
            // Extract file extension using path
            String fileExtension = file.path!.split('.').last.toLowerCase();

            if (fileExtension == 'pdf' || fileExtension == 'docx') {
              // Display non-image files (PDF, DOCX)
              String fileName = file.name;

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
                      color: Colors.white,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description,
                            size: 40, color: Colors.blueAccent),
                        SizedBox(height: 5),
                        Text(
                          fileName,
                          style: TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          fileExtension.toUpperCase(),
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: -5,
                    right: -5,
                    child: IconButton(
                      icon: Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () async {
                        final indexToRemove = _DocFiles!.indexOf(file);
                        if (indexToRemove != -1) {
                          // Check if the document has been uploaded
                          if (cloudinaryDocumentUrls.isEmpty ||
                              cloudinaryDocumentUrls.length <= indexToRemove) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Document processing unable to delete'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return; // If the document isn't uploaded, just return
                          }

                          String cloudinaryUrl =
                              cloudinaryDocumentUrls[indexToRemove];
                          String publicIdToRemove =
                              cloudinaryUrl.split('/').last.split('.').first;

                          try {
                            // Delete the document from Cloudinary
                            await deleteImageFromCloudinary(publicIdToRemove);
                            print(
                                'Document deleted from Cloudinary: $publicIdToRemove');
                          } catch (e) {
                            print('Error deleting document: $e');
                          }

                          // Update the UI to remove the document from local state
                          setState(() {
                            _DocFiles!.removeAt(indexToRemove);
                            cloudinaryDocumentUrls.removeAt(indexToRemove);
                          });
                        }
                      },
                    ),
                  ),
                ],
              );
            } else {
              // Display image files (PNG, JPG, etc.)
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
                      image: DecorationImage(
                        image: Image.file(File(file.path!))
                            .image, // Load image from file
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -5,
                    right: -5,
                    child: IconButton(
                      icon: Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () async {
                        final indexToRemove = _DocFiles!.indexOf(file);
                        if (indexToRemove != -1) {
                          // Check if the document has been uploaded
                          if (cloudinaryDocumentUrls.isEmpty ||
                              cloudinaryDocumentUrls.length <= indexToRemove) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Document processing unable to delete'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return; // If the document isn't uploaded, just return
                          }

                          String cloudinaryUrl =
                              cloudinaryDocumentUrls[indexToRemove];
                          String publicIdToRemove =
                              cloudinaryUrl.split('/').last.split('.').first;

                          try {
                            // Delete the document from Cloudinary
                            await deleteImageFromCloudinary(publicIdToRemove);
                            print(
                                'Document deleted from Cloudinary: $publicIdToRemove');
                          } catch (e) {
                            print('Error deleting document: $e');
                          }

                          // Update the UI to remove the document from local state
                          setState(() {
                            _DocFiles!.removeAt(indexToRemove);
                            cloudinaryDocumentUrls.removeAt(indexToRemove);
                          });
                        }
                      },
                    ),
                  ),
                ],
              );
            }
          }).toList(),
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

    return Form(
      key: _localFormKey,
      child: Column(
        children: [
          // Make DropdownButtonFormField
          DropdownButtonFormField2<String>(
            decoration: InputDecoration(
              hintText: 'Select Car Make',
              contentPadding: const EdgeInsets.only(
                  left: 2, right: 15, top: 10, bottom: 10),
              enabledBorder: borderStyle,
              focusedBorder: borderStyle,
              border: borderStyle,
            ),
            dropdownStyleData: DropdownStyleData(
                decoration: BoxDecoration(
              color: const Color(0xffFFFCF1),
              borderRadius: BorderRadius.circular(14),
            )),
            value: selectedMake,
            hint: const Text('Select Car Make'),
            items: [
              ...carMakesAndModels.map<DropdownMenuItem<String>>((car) {
                return DropdownMenuItem<String>(
                  value: car.make,
                  child: Text(car.make),
                );
              }).toList(),
              const DropdownMenuItem<String>(
                value: 'Other',
                child: Text('Other'),
              ),
            ],
            onChanged: (String? newValue) {
              setState(() {
                selectedMake = newValue;
                selectedModel = newValue == 'Other'
                    ? 'Other'
                    : null; // Automatically set selectedModel to 'Other'
              });
            },
            validator: (value) => value == null ? 'Please select a make' : null,
          ),

// Text input for custom make if "Other" is selected
          if (selectedMake == 'Other')
            Column(
              children: [
                const SizedBox(height: 15),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Enter Custom Make',
                    floatingLabelStyle:
                        const TextStyle(color: Color(0xff4A8AF0)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    enabledBorder: borderStyle,
                    focusedBorder: borderStyle,
                    border: borderStyle,
                  ),
                  onChanged: (value) {
                    setState(() {
                      customMake = value;
                    });
                  },
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a make'
                      : null,
                ),
              ],
            ),

// Model DropdownButtonFormField (only show if a make is selected)
          if (selectedMake != null && selectedMake != 'Other')
            Column(
              children: [
                const SizedBox(height: 15),
                DropdownButtonFormField2<String>(
                  decoration: InputDecoration(
                    hintText: 'Select Car Model',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    enabledBorder: borderStyle,
                    focusedBorder: borderStyle,
                    border: borderStyle,
                  ),
                  value: selectedModel,
                  hint: Text('Select Car Model'),
                  dropdownStyleData: DropdownStyleData(
                      decoration: BoxDecoration(
                    color: const Color(0xffFFFCF1),
                    borderRadius: BorderRadius.circular(14),
                  )),
                  items: carMakesAndModels
                      .firstWhere((car) => car.make == selectedMake)
                      .models
                      .map<DropdownMenuItem<String>>((String model) {
                    return DropdownMenuItem<String>(
                      value: model,
                      child: Text(model),
                    );
                  }).toList()
                    ..add(DropdownMenuItem<String>(
                      value: 'Other',
                      child: Text('Other'),
                    )),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedModel = newValue;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select a model' : null,
                ),
              ],
            ),

// Text input for custom model if "Other" is selected in the Model dropdown
          if (selectedModel == 'Other')
            Column(
              children: [
                const SizedBox(height: 15),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Enter Custom Model',
                    floatingLabelStyle:
                        const TextStyle(color: Color(0xff4A8AF0)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    enabledBorder: borderStyle,
                    focusedBorder: borderStyle,
                    border: borderStyle,
                  ),
                  onChanged: (value) {
                    setState(() {
                      customModel = value;
                    });
                  },
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a model'
                      : null,
                ),
              ],
            ),
          SizedBox(
            height: 15.0,
          ),
          TextFormField(
            controller: priceController,
            decoration: InputDecoration(
              labelText: 'Price',
              floatingLabelStyle: const TextStyle(color: Color(0xff4A8AF0)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
          SizedBox(height: 10),
          Align(
              alignment: Alignment.centerLeft,
              child: DropdownButtonHideUnderline(
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
                  dropdownStyleData: DropdownStyleData(
                      decoration: BoxDecoration(
                    color: const Color(0xffFFFCF1),
                    borderRadius: BorderRadius.circular(14),
                  )),
                  items: years.map<DropdownMenuItem<String>>((String value) {
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
                ),
              )),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                'Transmission Type:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ChoiceChip(
                backgroundColor: const Color(0xffFFFCF1),
                label: const Text('Manual'),
                showCheckmark: false,
                selectedColor: const Color(0xff4A8AF0),
                labelStyle: TextStyle(
                  color: selectedTransmission == 'Manual'
                      ? Colors.white
                      : Colors.black,
                ),
                selected: selectedTransmission == 'Manual',
                onSelected: (selected) =>
                    setState(() => selectedTransmission = 'Manual'),
              ),
              ChoiceChip(
                backgroundColor: const Color(0xffFFFCF1),
                label: const Text('Automatic'),
                showCheckmark: false,
                selectedColor: const Color(0xff4A8AF0),
                selected: selectedTransmission == 'Automatic',
                labelStyle: TextStyle(
                  color: selectedTransmission == 'Automatic'
                      ? Colors.white
                      : Colors.black,
                ),
                onSelected: (selected) =>
                    setState(() => selectedTransmission = 'Automatic'),
              ),
            ],
          ),
          SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: DropdownButtonHideUnderline(
                child: DropdownButton2<String>(
              isExpanded: true,
              buttonStyleData: ButtonStyleData(
                padding: const EdgeInsets.only(right: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.0),
                  border: Border.all(color: Colors.black),
                ),
              ),
              value: selectedFuelType,
              hint: const Text('Select Fuel Type'),
              dropdownStyleData: DropdownStyleData(
                  decoration: BoxDecoration(
                color: const Color(0xffFFFCF1),
                borderRadius: BorderRadius.circular(14),
              )),
              items: ['Gasoline', 'Diesel', 'LPG', 'Hybrid', 'Electric']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedFuelType = value;
                });
              },
            )),
          ),
          const SizedBox(height: 10),
          _buildColorPicker(),
          const SizedBox(height: 10),
          Align(
              alignment: Alignment.centerLeft, // Aligns to the left
              child: DropdownButtonHideUnderline(
                child: DropdownButton2<String>(
                  isExpanded: true,
                  buttonStyleData: ButtonStyleData(
                    padding: const EdgeInsets.only(right: 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30.0),
                      border: Border.all(color: Colors.black),
                    ),
                  ),
                  value: selectedMileageRange,
                  hint: const Text('Select Mileage'),
                  dropdownStyleData: DropdownStyleData(
                      decoration: BoxDecoration(
                    color: const Color(0xffFFFCF1),
                    borderRadius: BorderRadius.circular(14),
                  )),
                  items: [
                    '0-10,000 km',
                    '10,001-20,000 km',
                    '20,001-30,000 km',
                    '30,001-40,000 km',
                    '40,001-50,000 km',
                    '50,001-60,000 km',
                    '60,001-70,000 km',
                    '70,001-80,000 km',
                    '80,001-90,000 km',
                    '90,001-100,000 km',
                    '100,001-110,000 km',
                    '110,001-120,000 km',
                    '120,001-130,000 km',
                    '130,001-140,000 km',
                    '140,001-150,000 km',
                    '150,001-160,000 km',
                    '160,001-170,000 km',
                    '170,001-180,000 km',
                    '180,001-190,000 km',
                    '190,001-200,000 km',
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMileageRange = value;
                    });
                  },
                ),
              )),
          SizedBox(height: 10),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceEvenly, // Centers the ChoiceChips
            children: [
              const Text(
                "Sale Preference:",
                style: TextStyle(fontSize: 16),
              ),
              ChoiceChip(
                backgroundColor: const Color(0xffFFFCF1),
                label: Text('Buy Only'),
                selected: selectedPreference == 'Buy Only',
                showCheckmark: false,
                onSelected: (bool selected) {
                  setState(() {
                    selectedPreference = selected ? 'Buy Only' : null;
                  });
                },
                selectedColor: const Color(0xff4A8AF0),
                labelStyle: TextStyle(
                  color: selectedPreference == 'Buy Only'
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              SizedBox(width: 10),
              ChoiceChip(
                backgroundColor: const Color(0xffFFFCF1),
                label: Text('Allow Offers'),
                showCheckmark: false,
                selected: selectedPreference == 'Allow Offers',
                onSelected: (bool selected) {
                  setState(() {
                    selectedPreference = selected ? 'Allow Offers' : null;
                  });
                },
                selectedColor: const Color(0xff4A8AF0),
                labelStyle: TextStyle(
                  color: selectedPreference == 'Allow Offers'
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ],
          ),

          SizedBox(height: 10),

          /// Address Field
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
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
                floatingLabelStyle: const TextStyle(color: Color(0xff4A8AF0)),
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
                      addressController.text = locations[index]['display_name'];
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
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
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
                          child: Icon(Icons.location_on,
                              color: Colors.red, size: 40),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 15),
          TextFormField(
            controller: monthlyPaymentController,
            decoration: InputDecoration(
              labelText: 'Monthly Payment',
              floatingLabelStyle: const TextStyle(color: Color(0xff4A8AF0)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
              floatingLabelStyle: const TextStyle(color: Color(0xff4A8AF0)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
              if (duration == null || duration <= 0) {
                _showAlert('Loan duration must be greater than zero');
                return 'Loan duration must be greater than zero'; // Prevent form submission
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          TextFormField(
            controller: downPaymentController,
            decoration: InputDecoration(
              labelText: 'Down Payment',
              floatingLabelStyle: const TextStyle(color: Color(0xff4A8AF0)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
              floatingLabelStyle: const TextStyle(color: Color(0xff4A8AF0)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
                _showAlert('Number of months paid must be greater than zero');
                return 'Number of months paid must be greater than zero'; // Prevent form submission
              }

              final loanDuration =
                  int.tryParse(loanDurationController.text.replaceAll(',', ''));
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
          const SizedBox(height: 15),
          TextField(
            controller: descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Put Description here',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              enabledBorder:
                  borderStyle.copyWith(borderRadius: BorderRadius.circular(15)),
              focusedBorder:
                  borderStyle.copyWith(borderRadius: BorderRadius.circular(15)),
              border:
                  borderStyle.copyWith(borderRadius: BorderRadius.circular(15)),
            ),
          ),
          SizedBox(height: 15),
          _buildDocumentUploader(), // Space between sections
          buildImageUploader(),
          ElevatedButton(
            onPressed: () async {
              if (_localFormKey.currentState!.validate()) {
                // Check if images are uploaded
                if (_imageFiles == null || _imageFiles!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select at least one image')),
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
                    SnackBar(content: Text('Please select a sale preference')),
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
                    SnackBar(content: Text('Your images are still uploading')),
                  );
                  return;
                }
                // Prepare the listing content
                Map<String, dynamic> listingContent = {
                  'category': 'Car',
                  'title':
                      "${(selectedMake == 'Other' ? customMake : selectedMake)!} ${(selectedModel == 'Other' ? customModel : selectedModel)!}",
                  'make': selectedMake == 'Other' ? customMake : selectedMake,
                  'model':
                      selectedModel == 'Other' ? customModel : selectedModel,
                  'preference': selectedPreference,
                  'address': addressController.text,
                  'price': double.tryParse(
                          priceController.text.replaceAll(',', '')) ??
                      0.0,
                  'year': selectedYear,
                  'transmission': selectedTransmission,
                  'fuelType': selectedFuelType,
                  'color': selectedColor?.toString(),
                  'mileage': selectedMileageRange,
                  'description': descriptionController.text,
                  'monthlyPayment': double.tryParse(
                          monthlyPaymentController.text.replaceAll(',', '')) ??
                      0.0,
                  'loanDuration': loanDurationController.text,
                  'totalPaymentMade': totalPaymentMade,
                  'downPayment': double.tryParse(
                          downPaymentController.text.replaceAll(',', '')) ??
                      0.0,
                  'numberOfMonthsPaid': double.tryParse(
                          numberOfMonthsPaidController.text
                              .replaceAll(',', '')) ??
                      0.0,
                  'images': cloudinaryImageUrls, // Store Cloudinary URLs
                  'documents': cloudinaryDocumentUrls,
                };

                // Debug print to check content before submitting
                print('Listing Content: $listingContent');

                // Connect to the database and add the listing
                DatabaseService dbService = DatabaseService();
                try {
                  final token = await secureStorage.getToken();
                  await dbService.addCarListing(token!, listingContent);

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Submitted Successfully')),
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
    );
  }
}
