import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:assumemate/logo/loading_animation.dart';
import 'package:assumemate/provider/photos_permission.dart';
import 'package:assumemate/logo/pop_up.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:assumemate/provider/profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late PhotosPermission photoPermission;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mobilenoController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final SecureStorage secureStorage = SecureStorage();
  late String _profilePic;
  late bool isSaved;
  bool _isLoading = false;
  String? _applicationStatus;
  final ImagePicker _picker = ImagePicker();

  void _updateProfile() {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    Map<String, dynamic> profileData = {
      'user_prof_fname': _firstNameController.text.trim(),
      'user_prof_lname': _lastNameController.text.trim(),
      'user_prof_gender': _genderController.text.trim(),
      'user_prof_dob': _dobController.text.trim(),
      'user_prof_mobile': _mobilenoController.text.trim(),
      'user_prof_address': _addressController.text.trim(),
    };

    profileProvider.updateUserProfile(profileData).then((_) {
      if (profileProvider.errorMessage.isEmpty) {
        Navigator.of(context).pop(); // Go back on successful update
      } else {
        popUp(context, profileProvider.errorMessage);
        profileProvider.clearErrorMessage();
      }
    });
  }

  void _changeProfilePicture({required File image}) {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);

    Navigator.of(context).pop();

    profileProvider.updateUserProfilePicture(image).then((_) {
      if (profileProvider.errorMessage.isEmpty) {
        Navigator.of(context).pop();
      } else {
        popUp(context, profileProvider.errorMessage);
        profileProvider.clearErrorMessage();
      }
    });
  }

  Future<File?> _cropImage(File image) async {
    CroppedFile? croppedImage = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
        uiSettings: [
          AndroidUiSettings(
            lockAspectRatio: true,
            showCropGrid: false,
          )
        ]);
    if (croppedImage == null) return null;
    return File(croppedImage.path);
  }

  Future<void> _pickImage() async {
    final isGranted = await photoPermission.requestPhotosPermission();

    if (isGranted) {
      final result = await _picker.pickImage(source: ImageSource.gallery);

      if (result != null) {
        File file = File(result.path);
        File? croppedFile = await _cropImage(file);

        if (croppedFile != null) {
          final fileSize = await croppedFile.length(); // Get file size in bytes
          final fileSizeInMB = fileSize / (1024 * 1024); // Convert bytes to MB

          if (fileSizeInMB > 10) {
            popUp(context, 'File size exceeds 10 MB');
          } else {
            _changeProfilePicture(image: croppedFile);
          }
        }
      }
    }
  }

  Future<void> _getApplicationStatus() async {
    _applicationStatus = await secureStorage.getApplicationStatus();
    print(_applicationStatus);

    setState(() {});
  }

  bool _validateInputs() {
    String mobile = _mobilenoController.text.trim();
    String pattern = r'^\+639\d{9}$';

    if (mobile.isEmpty) {
      popUp(context, 'Mobile number cannot be empty');
      return false;
    }

    if (mobile.startsWith('09')) {
      mobile = '+639${mobile.substring(2)}';
    } else if (mobile.startsWith('9')) {
      mobile = '+639${mobile.substring(1)}';
    } else if (mobile.startsWith('639')) {
      mobile = '+639${mobile.substring(3)}';
    } else {
      popUp(context, 'Enter a valid Philippine number');
      return false;
    }

    if (!RegExp(pattern).hasMatch(mobile)) {
      popUp(context, 'Enter a valid Philippine number');
      return false;
    }

    if (_addressController.text.trim().isEmpty) {
      popUp(context, 'Address cannot be empty');
      return false;
    }
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    if (_mobilenoController.text.trim() ==
            profileProvider.userProfile['user_prof_mobile'] &&
        _addressController.text.trim() ==
            profileProvider.userProfile['user_prof_address']) {
      popUp(context, 'Mobile number or address cannot be the same as previous');
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _getApplicationStatus();
    isSaved = true;
    photoPermission = Provider.of<PhotosPermission>(context, listen: false);
    photoPermission.checkPhotoPermission();
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);

    // Initialize controllers with current profile data
    _profilePic = profileProvider.userProfile['user_prof_pic'] ??
        'https://openseauserdata.com/files/a1439c13b366dd156de18328ca708f9f.png';

    _firstNameController.text =
        profileProvider.userProfile['user_prof_fname'] ?? '';
    _lastNameController.text =
        profileProvider.userProfile['user_prof_lname'] ?? '';
    _mobilenoController.text = profileProvider.userProfile['user_prof_mobile']
            .replaceFirst('+63', '') ??
        '';
    _addressController.text =
        profileProvider.userProfile['user_prof_address'] ?? '';
    _genderController.text =
        profileProvider.userProfile['user_prof_gender'] ?? '';
    _dobController.text = profileProvider.userProfile['user_prof_dob'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    // if (_applicationStatus == '' || _applicationStatus == null) {
    //   return const Scaffold(
    //     body: LoadingAnimation(),
    //   );
    // }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          splashColor: Colors.transparent,
          icon: const Icon(Icons.arrow_back_ios),
          color: const Color(0xffFFFEF7),
          onPressed: () {
            if (isSaved) {
              Navigator.of(context).pop();
            } else {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text(
                      'Discard changes?',
                      style: TextStyle(
                          color: Color(0xff4A8AF0),
                          fontSize: 15,
                          fontWeight: FontWeight.w500),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Color(0xff4A8AF0)),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff4A8AF0),
                        ),
                        child: const Text(
                          'Discard',
                          style: TextStyle(color: Color(0xffFFFEF7)),
                        ),
                      ),
                    ],
                  );
                },
              );
            }
          },
        ),
        title: const Text(
          "Edit profile",
          style: TextStyle(
            fontSize: 20,
            color: Color(0xffFFFEF7),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xff4A8AF0),
        actions: [
          TextButton(
              onPressed: _applicationStatus == 'PENDING'
                  ? null
                  : () {
                      if (_validateInputs()) {
                        _updateProfile();
                        setState(() => isSaved = true);
                      }
                    },
              child: Text(
                _applicationStatus == 'PENDING' ? '' : 'Save',
                style: const TextStyle(
                  fontSize: 20,
                  color: Color(0xffFFFEF7),
                  fontWeight: FontWeight.normal,
                ),
              ))
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: profileProvider.isLoading
                    ? const Center(child: LoadingAnimation())
                    : SingleChildScrollView(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(_profilePic),
                                radius: 50,
                              ),
                              const SizedBox(height: 10),
                              InkWell(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () {
                                  _applicationStatus == 'PENDING'
                                      ? null
                                      : bottomModal();
                                },
                                child: const Text(
                                  'Edit profile picture',
                                  style: TextStyle(
                                    color: Color(0xff4A8AF0),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              buildInput(
                                  "First name", _firstNameController, true),
                              const SizedBox(height: 10),
                              buildInput(
                                  "Last name", _lastNameController, true),
                              const SizedBox(height: 10),
                              buildInput("Gender", _genderController, true),
                              const SizedBox(height: 10),
                              buildInput("Birth date", _dobController, true),
                              const SizedBox(height: 10),
                              buildInput(
                                  "Address",
                                  _addressController,
                                  _applicationStatus == 'PENDING'
                                      ? true
                                      : false),
                              const SizedBox(height: 10),
                              buildMobInput(
                                  "Mobile number",
                                  _mobilenoController,
                                  profileProvider
                                      .userProfile['user_prof_mobile'],
                                  _applicationStatus == 'PENDING'
                                      ? true
                                      : false),
                            ]),
                      )),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        color: const Color(0xffFFFCF1),
        child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.black45, width: 2),
                borderRadius: BorderRadius.circular(8.0),
                color: const Color(0xffFFFCF1)),
            child: Row(children: [
              const Icon(Icons.info_outline, color: Color(0xff4A8AF0)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _applicationStatus == 'PENDING'
                      ? 'Your account profile is under review. Updates are currently unavailable.'
                      : 'Updates to your Assumemate name, gender, and birth date are no longer allowed as they have been reviewed and confirmed.',
                  style: const TextStyle(fontSize: 13),
                  softWrap: true,
                  textAlign: TextAlign.start,
                ),
              ),
            ])),
      ),
    );
  }

  Future bottomModal() {
    return showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: () {
                  _pickImage();
                },
                child: const Row(
                  children: [
                    Icon(Icons.image_outlined, size: 30),
                    SizedBox(width: 5),
                    Text(
                      'New profile picture',
                      style: TextStyle(fontSize: 15),
                    )
                  ],
                ),
              ));
        });
  }

  Widget buildInput(
      String labelText, TextEditingController controller, bool readOnly) {
    return Container(
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xff4A8AF0).withOpacity(0.4), // Border color
            width: 2.0, // Border width
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: TextFormField(
          controller: controller,
          readOnly: readOnly,
          onChanged: (text) => setState(() => isSaved = false),
          decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(10),
              label: Text(labelText),
              labelStyle: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
              border: InputBorder.none),
        ));
  }

  Widget buildMobInput(String labelText, TextEditingController controller,
      String conText, bool readOnly) {
    return Container(
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xff4A8AF0).withOpacity(0.4),
            width: 2.0, // Border width
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: TextFormField(
          controller: controller,
          readOnly: readOnly,
          maxLength: 10,
          onChanged: (text) => setState(() => isSaved = false),
          keyboardType: TextInputType.number, // Numeric keyboard
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly, // Allow only digits
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: InputDecoration(
            counterText: '',
            contentPadding: const EdgeInsets.all(10),
            label: Text(labelText),
            labelStyle: const TextStyle(
              fontSize: 18,
              color: Colors.black45,
            ),
            border: InputBorder.none,
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
                  const Text(
                    '(+63)',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
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
        ));
  }
}
