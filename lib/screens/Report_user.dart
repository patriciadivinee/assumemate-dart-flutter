import 'dart:convert';
import 'dart:io';
import 'package:cloudinary/cloudinary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class ReportUserScreen extends StatefulWidget {
  final String user_id;

  ReportUserScreen(this.user_id);

  @override
  _ReportUserScreenState createState() => _ReportUserScreenState();
}

class _ReportUserScreenState extends State<ReportUserScreen> {
  List<String> selectedIssues = [];
  List<File> _imageFiles = [];
  List<String> cloudinaryImageUrls = [];

  final cloudinary = Cloudinary.signedConfig(
    apiKey: '713443683486728',
    apiSecret: 'gKCMD_fCso--h1CIyPGxTWsp9As',
    cloudName: 'dqfvxj9h0',
  );

  final ImagePicker _picker = ImagePicker();
  final TextEditingController inputDetailsController = TextEditingController();
  final String? baseURL = dotenv.env['API_URL'];

  Future<void> _pickImages() async {
    PermissionStatus permissionStatus = await Permission.photos.request();

    if (permissionStatus.isGranted) {
      final List<XFile>? selectedImages = await _picker.pickMultiImage();
      if (selectedImages != null && selectedImages.isNotEmpty) {
        setState(() {
          _imageFiles.addAll(selectedImages.map((file) => File(file.path)));
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permission to access storage is required.')),
      );
    }
  }

  void _removeImage(File image) {
    setState(() {
      _imageFiles.remove(image);
    });
  }

  Future<void> _submitReport() async {
    if (selectedIssues.isEmpty ||
        _imageFiles.isEmpty ||
        inputDetailsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    // Retrieve the token from secure storage
    final secureStorage = SecureStorage();
    String? token = await secureStorage.getToken();
    String? reporterId = await secureStorage.getUserId();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No authorization token found.')),
      );
      return; // Exit if no token is found
    }

    // Upload images to Cloudinary
    for (var imageFile in _imageFiles) {
      final response = await cloudinary.upload(
        file: imageFile.path,
        folder: 'Report User',
        resourceType: CloudinaryResourceType.image,
      );
      if (response.isSuccessful && response.secureUrl != null) {
        cloudinaryImageUrls.add(response.secureUrl!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: ${response.error}')),
        );
        return; // Exit if image upload fails
      }
    }

    // Prepare the report details
    final reportDetails = {
      'issue_types': selectedIssues,
      'describe': inputDetailsController.text.trim(),
      'images': cloudinaryImageUrls,
      'reported_user_id':
          widget.user_id, // The user_id of the user being reported
      'reporter_id':
          reporterId, // The user_id of the user who is logged in and reporting
    };

    // Send the report to your backend
    try {
      final response = await http.post(
        Uri.parse('$baseURL/send/report/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'report_details': reportDetails,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report submitted successfully')),
        );
        // Clear all fields after submission
        setState(() {
          inputDetailsController.clear();
          _imageFiles.clear();
          selectedIssues.clear();
          cloudinaryImageUrls.clear(); // Clear uploaded image URLs
        });
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception(errorResponse['detail'] ?? 'Failed to submit report');
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
        title: const Text('What happened?'),
        backgroundColor: Colors.blue,
        actions: [
          TextButton(
            onPressed: _submitReport,
            child: const Text(
              'SEND',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: inputDetailsController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Describe the issue briefly...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('CAMERA ROLL'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300]),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            _imageFiles.isNotEmpty
                ? Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _imageFiles.map((imageFile) {
                      return Stack(
                        alignment: Alignment.topRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.file(
                              imageFile,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _removeImage(imageFile),
                          ),
                        ],
                      );
                    }).toList(),
                  )
                : const Text('No images selected.'),
            const SizedBox(height: 16.0),
            const Text(
              "Select the type of issue",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                _buildChip('Fraud'),
                _buildChip('Scam'),
                _buildChip('Nudity'),
                _buildChip('Hate Speech'),
                _buildChip('Harassment'),
                _buildChip('Violence'),
                _buildChip('Spam'),
                _buildChip('False Information'),
                _buildChip('Something else'),
              ],
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Information about your account, and this app will be automatically included in this report.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    final isSelected = selectedIssues.contains(label);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            selectedIssues.add(label);
          } else {
            selectedIssues.remove(label);
          }
        });
      },
      selectedColor: Colors.blue,
      backgroundColor: Colors.grey[200],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    );
  }
}
