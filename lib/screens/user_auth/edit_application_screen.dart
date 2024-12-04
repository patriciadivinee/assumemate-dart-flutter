// ignore_for_file: unused_import, sized_box_for_whitespace, prefer_const_constructors
import 'dart:convert';
import 'dart:typed_data';
import 'package:assumemate/provider/profile_provider.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:country_icons/country_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:assumemate/logo/loading_animation.dart';
import 'package:assumemate/logo/pop_up.dart';
import 'package:assumemate/provider/photos_permission.dart';
import 'package:assumemate/screens/home_screen.dart';
import 'package:assumemate/screens/waiting_area/pending_application_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:assumemate/service/service.dart';
import 'package:provider/provider.dart';

class EditApplicationScreen extends StatefulWidget {
  const EditApplicationScreen({super.key});

  @override
  State<EditApplicationScreen> createState() => _EditApplicationScreenState();
}

class _EditApplicationScreenState extends State<EditApplicationScreen> {
  late PhotosPermission storagePermission;
  final ApiService apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  // String? roleSelected;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController mobilenoController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  String? _validIDUrl;
  String? _picUrl;
  DateTime? _selectedDate;
  String? _selectedGender;
  File? _validIDImage;
  File? _pictureImage;
  String? _validIDError;
  String? _pictureError;

  bool _isLoading = false;

  final SecureStorage secureStorage = SecureStorage();

  Future<String> imageToBase64(File imageFile) async {
    List<int> imageBytes = await imageFile.readAsBytes();
    return base64Encode(imageBytes);
  }

  Future<void> getInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await apiService.viewInfoApplication();

      if (response.containsKey('account')) {
        final profile = response['profile'];
        final account = response['account'];

        setState(() {
          emailController.text = account['email'];
          firstNameController.text = profile['user_prof_fname'];
          lastNameController.text = profile['user_prof_lname'];
          mobilenoController.text =
              profile['user_prof_mobile'].replaceFirst('+63', '');
          addressController.text = profile['user_prof_address'];
          _dateController.text = profile['user_prof_dob'];
          _selectedGender = profile['user_prof_gender'];
          _picUrl = profile['user_prof_valid_pic'];
          _validIDUrl = profile['user_prof_valid_id'];
          _selectedDate = DateTime.parse(profile['user_prof_dob']);
        });
        print(_validIDUrl);
      }
    } catch (e) {
      popUp(context, 'An error occured: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resubmitApplication() async {
    setState(() {
      _isLoading = true;
    });

    final Map<String, dynamic> profileData = {
      'user_prof_fname': firstNameController.text.trim(),
      'user_prof_lname': lastNameController.text.trim(),
      'user_prof_gender': _selectedGender,
      'user_prof_dob': _dateController.text.trim(),
      'user_prof_mobile': mobilenoController.text.trim(),
      'user_prof_address': addressController.text.trim(),
      'user_prof_valid_id': _validIDImage != null
          ? await imageToBase64(_validIDImage!)
          : _validIDUrl,
      'user_prof_valid_pic':
          _pictureImage != null ? await imageToBase64(_pictureImage!) : _picUrl,
    };

    try {
      final response = await apiService.updateApplicationDetails(profileData);

      if (response.containsKey('success')) {
        await Provider.of<ProfileProvider>(context, listen: false)
            .initializeToken();
        Navigator.of(context).pop(response['status']);
        popUp(context, response['success']);
      } else {
        popUp(context, response['error'] ?? 'Unknown error');
      }
    } catch (e) {
      popUp(context, 'An error occurred: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(String type) async {
    final result = await _picker.pickImage(source: ImageSource.gallery);

    if (result != null) {
      final file = File(result.path);
      final fileSize = await file.length(); // Get file size in bytes
      final fileSizeInMB = fileSize / (1024 * 1024); // Convert bytes to MB

      if (fileSizeInMB > 25) {
        setState(() {
          if (type == 'validID') {
            _validIDError = 'File size exceeds 25 MB';
            _validIDImage = null;
          } else if (type == 'picture') {
            _pictureError = 'File size exceeds 25 MB';
            _pictureImage = null;
          }
        });
      } else {
        setState(() {
          if (type == 'validID') {
            _validIDImage = file;
            _validIDError = null;
          } else if (type == 'picture') {
            _pictureImage = file;
            _pictureError = null;
          }
        });
      }
    }
  }

  void _validateInputs() {
    if (_validIDImage == null || _pictureImage == null) {
      popUp(context, 'Please attach a photo of valid ID and 2x2 picture');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final today = DateTime.now();
    final minAdultDate = DateTime(today.year - 18, today.month, today.day);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: minAdultDate,
      firstDate: DateTime(1900),
      lastDate: minAdultDate,
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getInfo();
    storagePermission = Provider.of<PhotosPermission>(context, listen: false);
    storagePermission.checkPhotoPermission();
  }

  @override
  Widget build(BuildContext context) {
    Future<void> askPermission(String type) async {
      final result = await storagePermission.requestPhotosPermission();

      print(result);

      if (result) {
        if (type == 'validID') {
          _pickImage('validID');
        } else {
          _pickImage('picture');
        }
      }
      print('pressed');
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffFFFCF1),
        leading: IconButton(
          splashColor: Colors.transparent,
          icon: const Icon(
            Icons.arrow_back_ios,
          ),
          color: Colors.black,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Edit',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            )),
      ),
      body: SafeArea(
        child: Stack(children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildInputEmail("Email", emailController, validateEmail),
                    const SizedBox(height: 15.0),
                    buildInputRow(
                        "First Name", firstNameController, validateNotEmpty),
                    const SizedBox(height: 15.0),
                    buildInputRow(
                        "Last Name", lastNameController, validateNotEmpty),
                    const SizedBox(height: 15.0),

                    // Gender Dropdown
                    buildDropdownRow("Select Sex at Birth", (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    }),
                    const SizedBox(height: 15.0),

                    // Date Picker
                    buildDatePickerRow("Date of Birth", _selectedDate),
                    const SizedBox(height: 5.0),
                    Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline,
                              color: Colors.black45, size: 18),
                          SizedBox(width: 2),
                          Text(
                            'You must at least 18 years old',
                            style:
                                TextStyle(color: Colors.black45, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15.0),

                    //PhoneNumber
                    buildMobileNo("Mobile Number", mobilenoController),
                    const SizedBox(height: 15.0),

                    //Address
                    buildInputRow(
                        "Address", addressController, validateNotEmpty),
                    const SizedBox(height: 15.0),

                    Row(
                      children: [
                        buildImagePicker(
                          "Select valid ID",
                          _validIDImage,
                          _validIDUrl,
                          storagePermission.isPermissionGranted
                              ? () => _pickImage('validID')
                              : () => askPermission('validID'),
                        ),
                        const SizedBox(width: 7),
                        buildImagePicker(
                          "Select 2x2 Picture",
                          _pictureImage,
                          _picUrl,
                          storagePermission.isPermissionGranted
                              ? () => _pickImage('picture')
                              : () => askPermission('picture'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22.0),

                    // Submit Button
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          // _validateInputs();
                          if (_formKey.currentState!.validate()) {
                            _resubmitApplication();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4A8AF0),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                        ),
                        child: const Text(
                          "Resubmit",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading) const LoadingAnimation(),
        ]),
      ),
    );
  }

  final OutlineInputBorder borderStyle = OutlineInputBorder(
    borderRadius: BorderRadius.circular(30.0),
    borderSide: const BorderSide(color: Colors.black),
  );

  // Text Field with validation
  Widget buildInputRow(String labelText, TextEditingController controller,
      String? Function(String?)? validator) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: TextFormField(
                onTapOutside: (event) {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                controller: controller,
                style: TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: labelText,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  enabledBorder: borderStyle,
                  focusedBorder: borderStyle,
                  border: borderStyle,
                ),
                validator: validator),
          ),
        ),
      ],
    );
  }

  Widget buildMobileNo(String labelText, TextEditingController controller) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: TextFormField(
              onTapOutside: (event) {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              controller: controller,
              style: TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: labelText,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                enabledBorder: borderStyle,
                focusedBorder: borderStyle,
                border: borderStyle,
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 15, right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'icons/flags/png250px/ph.png',
                        package: 'country_icons',
                        width: 30,
                        height: 30,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '(+63)',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly, // Allow only digits
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (value) => validateMobileNumber(value ?? ''),
            ),
          ),
        ),
      ],
    );
  }

  //Email Input
  Widget buildInputEmail(String labelText, TextEditingController controller,
      String? Function(String?)? validator) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: TextFormField(
                readOnly: true,
                controller: controller,
                style: TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: labelText,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  enabledBorder: borderStyle,
                  focusedBorder: borderStyle,
                  border: borderStyle,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: validator),
          ),
        ),
      ],
    );
  }

  // Gender Dropdown
  Widget buildDropdownRow(String labelText, Function(String?)? onChanged) {
    return Container(
      width: 800,
      child: DropdownButtonFormField2<String>(
        decoration: InputDecoration(
          hintText: labelText,
          contentPadding:
              const EdgeInsets.only(left: 2, right: 15, top: 10, bottom: 10),
          enabledBorder: borderStyle,
          focusedBorder: borderStyle,
          border: borderStyle,
        ),
        value: _selectedGender,
        hint: Text(
          labelText,
          style: TextStyle(fontSize: 12),
        ),
        dropdownStyleData: DropdownStyleData(
            decoration: BoxDecoration(
          color: Color(0xffFFFCF1),
          borderRadius: BorderRadius.circular(14),
        )),
        items: <String>['Male', 'Female']
            .map((item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(fontSize: 12),
                )))
            .toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? "Please select gender" : null,
      ),
    );
  }

  // Date Picker
  Widget buildDatePickerRow(String labelText, DateTime? selectedDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                onTap: () {
                  _selectDate(context);
                },
                onTapOutside: (event) {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                style: TextStyle(fontSize: 12),
                controller: _dateController,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: labelText,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  enabledBorder: borderStyle,
                  focusedBorder: borderStyle,
                  border: borderStyle,
                  suffixIcon: Padding(
                      padding: const EdgeInsets.only(left: 10, right: 17),
                      child: Icon(Icons.calendar_today)),
                ),
                validator: (value) {
                  if (selectedDate == null) {
                    return "$labelText is required";
                  }
                  // final today = DateTime.now();
                  // final minAdultDate =
                  //     DateTime(today.year - 18, today.month, today.day);

                  // // Check if the selected date is before the minimum adult date
                  // if (selectedDate.isAfter(minAdultDate)) {
                  //   return "You must be at least 18 years old";
                  // }

                  return null;
                },
              ),
            )
          ],
        ),
      ],
    );
  }

  // Password Field
  Widget buildPasswordRow(
      String labelText, TextEditingController controller, passValidator) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: TextFormField(
                controller: controller,
                style: TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: labelText,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  enabledBorder: borderStyle,
                  focusedBorder: borderStyle,
                  border: borderStyle,
                ),
                obscureText: true,
                validator: passValidator),
          ),
        ),
      ],
    );
  }

  Widget buildImagePicker(
      String labelText, File? image, String? imgUrl, VoidCallback onTap) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: InkWell(
          onTap: onTap,
          child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Color(0xffFFFCF1),
                border: Border.all(
                    color: Color(0xff4A8AF0).withOpacity(0.4), // Border color
                    width: 2),
              ),
              child: image != null
                  ? Stack(
                      alignment: AlignmentDirectional.center,
                      children: [
                        Image.file(
                          File(image.path),
                          fit: BoxFit.contain,
                        ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: GestureDetector(
                            onTap: () {
                              if (labelText == 'Select valid ID') {
                                setState(() {
                                  _validIDImage = null;
                                });
                              }
                              if (labelText == 'Select 2x2 Picture') {
                                setState(() {
                                  _pictureImage = null;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white54,
                              ),
                              child: const Icon(
                                FontAwesomeIcons.xmark,
                                color: Colors.black54,
                                size: 15, // Adjust size as needed
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : imgUrl != null
                      ? Image.network(
                          imgUrl,
                          fit: BoxFit.contain,
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              color: Colors.grey.shade300,
                              size: 45,
                            ),
                            Text(
                              labelText,
                              style: TextStyle(fontSize: 12),
                            )
                          ],
                        )),
        ),
      ),
    );
  }

  // Validators
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter an email";
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return "Please enter a valid email";
    }
    return null;
  }

  //Empty field
  String? validateNotEmpty(String? value) {
    if (value == null || value.isEmpty) {
      return "This field cannot be empty";
    }
    return null;
  }

  //Mobile number validator
  String? validateMobileNumber(String value) {
    value = value.trim();

    if (value.isEmpty) {
      return 'Mobile number is required';
    }

    if (value.startsWith('09')) {
      value = value.replaceFirst('09', '+639');
    } else if (value.startsWith('9')) {
      value = '+639${value.substring(1)}';
    }

    // Regular expression to match Philippine mobile numbers
    String pattern = r'^\+639\d{9}$';
    RegExp regExp = RegExp(pattern);

    if (!regExp.hasMatch(value)) {
      return 'Please enter a valid Philippine mobile number';
    }
    return null;
  }
}
