// motor_form.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary/cloudinary.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'db_helper.dart'; // Assuming this is your database helper
import 'motor_data.dart';

class MotorForm extends StatefulWidget {
  @override
  _MotorForm createState() => _MotorForm();
}

class _MotorForm extends State<MotorForm> {
  final SecureStorage secureStorage = SecureStorage();

  final GlobalKey<FormState> _localFormKey = GlobalKey<FormState>();

  final ImagePicker _picker = ImagePicker();
  List<XFile>? _imageFiles = [];
  List<String> cloudinaryImageUrls = [];
  List<String> cloudinaryDocumentUrls = [];

  double totalPaymentMade = 0.0;

  final cloudinary = Cloudinary.signedConfig(
    apiKey: '713443683486728',
    apiSecret: 'gKCMD_fCso--h1CIyPGxTWsp9As',
    cloudName: 'dqfvxj9h0',
  );

  final List<String> years =
      List.generate(30, (index) => (1990 + index).toString()).reversed.toList();
  String? selectedYear,
      selectedTransmission,
      selectedFuelType,
      selectedMileageRange,
      selectedMake;
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
  final TextEditingController modelController = TextEditingController();
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
    super.dispose();
  }

  Future<void> _pickImages() async {
    PermissionStatus permissionStatus = await Permission.photos.request();

    if (permissionStatus.isGranted) {
      final List<XFile>? selectedImages = await _picker.pickMultiImage();
      if (selectedImages != null && selectedImages.isNotEmpty) {
        setState(() {
          _imageFiles!.addAll(selectedImages);
        });

        for (var file in selectedImages) {
          if (file.path != null) {
            final response = await cloudinary.upload(
              file: file.path!,
              folder: 'car_listings',
              resourceType: CloudinaryResourceType.image,
            );

            if (response.isSuccessful && response.secureUrl != null) {
              cloudinaryImageUrls.add(response.secureUrl!);
            } else {
              print('Error uploading to Cloudinary: ${response.error}');
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

  void _computeTotalPayment() {
    double downPayment = double.tryParse(downPaymentController.text) ?? 0.0;
    double monthlyPayment =
        double.tryParse(monthlyPaymentController.text) ?? 0.0;
    int numberOfMonthsPaid =
        int.tryParse(numberOfMonthsPaidController.text) ?? 0;

    setState(() {
      totalPaymentMade = downPayment + (monthlyPayment * numberOfMonthsPaid);
    });
  }

  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Color'),
        Wrap(
          spacing: 8,
          children: colors.map((color) {
            return ChoiceChip(
              label: Container(width: 20, height: 20, color: color),
              selected: selectedColor == color,
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
        OutlinedButton(
          onPressed: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles(
              allowMultiple: true,
              type: FileType.custom,
              allowedExtensions: ['pdf', 'docx', 'jpg', 'png'],
            );

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
                      cloudinaryDocumentUrls.add(response.secureUrl!);
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
          child: Text('Upload Ownership Proof Documents'),
        ),
        SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: cloudinaryDocumentUrls.map((url) {
            if (url.toLowerCase().endsWith('.pdf') ||
                url.toLowerCase().endsWith('.docx')) {
              // Get the file name and extension for non-image files
              String fileName = url.split('/').last;
              String fileType = url.split('.').last;

              return Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.description, size: 40, color: Colors.blue),
                    SizedBox(height: 5),
                    Text(fileName,
                        style: TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(fileType.toUpperCase(),
                        style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              );
            } else {
              // Display image files
              return Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(url),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            }
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _localFormKey,
      child: Column(
        children: [
          OutlinedButton(
            onPressed: _pickImages,
            child: Text('Select Photos'),
          ),
          Wrap(
            spacing: 8,
            children: _imageFiles!.map((file) {
              return Stack(
                alignment: Alignment.topRight,
                children: [
                  Image.file(File(file.path), width: 100, height: 100),
                  IconButton(
                    icon: Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _imageFiles = List.from(_imageFiles!)..remove(file);
                      });
                    },
                  ),
                ],
              );
            }).toList(),
          ),
          // Make DropdownButtonFormField
          DropdownButtonFormField<String>(
            value: selectedMake,
            hint: Text('Select Motor Brand'),
            items: motormake.map<DropdownMenuItem<String>>((motor) {
              return DropdownMenuItem<String>(
                value: motor.brand
                    .first, // Assuming each brand list has only one element
                child: Text(motor.brand.first),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedMake = newValue;
              });
            },
            validator: (value) => value == null
                ? 'Please select a brand'
                : null, // Validation for make
          ),
          TextFormField(
            controller: modelController,
            decoration: InputDecoration(labelText: 'Model(Optional)'),
          ),
          SizedBox(
            height: 20.0,
          ),
          TextFormField(
            controller: titleController,
            decoration: InputDecoration(labelText: 'Title'),
            validator: (value) =>
                value!.isEmpty ? 'Please enter a title' : null,
          ),
          SizedBox(
            height: 20.0,
          ),
          TextFormField(
            controller: priceController,
            decoration: InputDecoration(labelText: 'Price'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) =>
                value!.isEmpty ? 'Please enter a price' : null,
          ),
          DropdownButton<String>(
            value: selectedYear,
            hint: Text('Select Year'),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ChoiceChip(
                label: Text('Manual'),
                selected: selectedTransmission == 'Manual',
                onSelected: (selected) =>
                    setState(() => selectedTransmission = 'Manual'),
              ),
              ChoiceChip(
                label: Text('Automatic'),
                selected: selectedTransmission == 'Automatic',
                onSelected: (selected) =>
                    setState(() => selectedTransmission = 'Automatic'),
              ),
            ],
          ),
          DropdownButton<String>(
            value: selectedFuelType,
            hint: Text('Select Fuel Type'),
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
          ),
          _buildColorPicker(),
          DropdownButton<String>(
            value: selectedMileageRange,
            hint: Text('Select Mileage'),
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
          TextFormField(
            controller: descriptionController,
            decoration: InputDecoration(labelText: 'Description'),
            validator: (value) =>
                value!.isEmpty ? 'Please enter a description' : null,
          ),
          _buildDocumentUploader(),
          TextFormField(
            controller: monthlyPaymentController,
            decoration: InputDecoration(labelText: 'Monthly Payment'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) =>
                value!.isEmpty ? 'Please enter a monthly payment' : null,
            onChanged: (value) => _computeTotalPayment(),
          ),
          TextFormField(
            controller: loanDurationController,
            decoration: InputDecoration(labelText: 'Loan Duration (Months)'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) =>
                value!.isEmpty ? 'Please enter a loan duration' : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Total Payment Made: \₱${totalPaymentMade.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          TextFormField(
            controller: downPaymentController,
            decoration: InputDecoration(labelText: 'Down Payment'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) =>
                value!.isEmpty ? 'Please enter a down payment' : null,
            onChanged: (value) => _computeTotalPayment(),
          ),
          TextFormField(
            controller: numberOfMonthsPaidController,
            decoration: InputDecoration(labelText: 'Number of Months Paid'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) =>
                value!.isEmpty ? 'Please enter number of months paid' : null,
            onChanged: (value) => _computeTotalPayment(),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_localFormKey.currentState!.validate()) {
                if (_imageFiles == null || _imageFiles!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select at least one image')),
                  );
                  return;
                }

                // Prepare the listing content
                Map<String, dynamic> listingContent = {
                  'category': 'Motorcycle',
                  'make:': selectedMake,
                  'model': modelController.text,
                  'title': titleController.text,
                  'price': priceController.text,
                  'year': selectedYear,
                  'transmission': selectedTransmission,
                  'fuelType': selectedFuelType,
                  'color': selectedColor?.toString(),
                  'mileage': selectedMileageRange,
                  'description': descriptionController.text,
                  'monthlyPayment': monthlyPaymentController.text,
                  'loanDuration': loanDurationController.text,
                  'totalPaymentMade': totalPaymentMade,
                  'downPayment': downPaymentController.text,
                  'numberOfMonthsPaid': numberOfMonthsPaidController.text,
                  'images': cloudinaryImageUrls, // Store Cloudinary URLs
                  'documents': cloudinaryDocumentUrls,
                };

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
            child: Text('Submit for Review'),
          ),
        ],
      ),
    );
  }
}
