// car_form.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary/cloudinary.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'db_helper.dart'; // Assuming this is your database helper

class Restate extends StatefulWidget {
  const Restate({super.key});
  @override
  _Restate createState() => _Restate();
}

class _Restate extends State<Restate> {
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
      List.generate(30, (index) => (1995 + index).toString()).reversed.toList();
  String? selectedYear,
      selectedBedrooms,
      selectedBathrooms,
      selectedParkingSpace;
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
              folder: 'real_estate_listings',
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
          SizedBox(
            height: 40.0,
          ),
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
            height: 10.0,
          ),
          TextFormField(
            controller: priceController,
            decoration: InputDecoration(labelText: 'Price'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) =>
                value!.isEmpty ? 'Please enter a price' : null,
          ),
          SizedBox(
            height: 10.0,
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
          SizedBox(
            height: 10.0,
          ),
          DropdownButton<String>(
            value: selectedBedrooms,
            hint: Text('Bedrooms (Optional)'),
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
          ),
          SizedBox(
            height: 10.0,
          ),
          DropdownButton<String>(
            value: selectedBathrooms,
            hint: Text('Bathrooms (Optional)'),
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
          SizedBox(
            height: 10.0,
          ),
          TextFormField(
            controller: floorareaController,
            decoration: InputDecoration(
              labelText: 'Floor Area',
              suffixText: 'sqm',
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            validator: (value) =>
                value!.isEmpty ? 'Please enter a floor area in sqm' : null,
          ),
          SizedBox(
            height: 10.0,
          ),
          TextFormField(
            controller: lotareaController,
            decoration: InputDecoration(
              labelText: 'Lot Area(Optional)',
              suffixText: 'sqm',
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
          ),
          SizedBox(
            height: 10.0,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Parking Space (Optional)',
                style: TextStyle(
                  fontSize: 16,
                ), // Customize the style as needed
              ),
              SizedBox(
                  height: 8), // Add some space between the text and the chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ChoiceChip(
                    label: Text('0'),
                    selected: selectedParkingSpace == '0',
                    onSelected: (selected) {
                      setState(() => selectedParkingSpace = '0');
                    },
                  ),
                  ChoiceChip(
                    label: Text('1'),
                    selected: selectedParkingSpace == '1',
                    onSelected: (selected) {
                      setState(() => selectedParkingSpace = '1');
                    },
                  ),
                  ChoiceChip(
                    label: Text('2'),
                    selected: selectedParkingSpace == '2',
                    onSelected: (selected) {
                      setState(() => selectedParkingSpace = '2');
                    },
                  ),
                  ChoiceChip(
                    label: Text('2+'),
                    selected: selectedParkingSpace == '2+',
                    onSelected: (selected) {
                      setState(() => selectedParkingSpace = '2+');
                    },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(
            height: 10.0,
          ),
          TextFormField(
            controller: descriptionController,
            decoration: InputDecoration(labelText: 'Description'),
            validator: (value) =>
                value!.isEmpty ? 'Please enter a description' : null,
          ),
          SizedBox(
            height: 10.0,
          ),
          _buildDocumentUploader(),
          SizedBox(
            height: 10.0,
          ),
          TextFormField(
            controller: monthlyPaymentController,
            decoration: InputDecoration(labelText: 'Monthly Payment'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) =>
                value!.isEmpty ? 'Please enter a monthly payment' : null,
            onChanged: (value) => _computeTotalPayment(),
          ),
          SizedBox(
            height: 10.0,
          ),
          TextFormField(
            controller: loanDurationController,
            decoration: InputDecoration(labelText: 'Loan Duration (Months)'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) =>
                value!.isEmpty ? 'Please enter a loan duration' : null,
          ),
          SizedBox(
            height: 10.0,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Total Payment Made: \₱${totalPaymentMade.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 10.0,
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
          SizedBox(
            height: 10.0,
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
          SizedBox(
            height: 10.0,
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
                  'category': 'Real Estate',
                  'year': selectedYear,
                  'title': titleController.text,
                  'price': priceController.text,
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
