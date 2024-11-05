import 'package:flutter/material.dart';
import 'package:assumemate/logo/loading_animation.dart';
import 'package:assumemate/logo/pop_up.dart';
import 'package:assumemate/service/service.dart';
import 'package:assumemate/storage/secure_storage.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final ApiService apiService = ApiService();

  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FocusNode _newPasswordFocusNode = FocusNode();
  final SecureStorage secureStorage = SecureStorage();

  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_checkPasswordMatch);
    _confirmPasswordController.addListener(_checkPasswordMatch);
    _currentPasswordController.addListener(_checkPasswordMatch);

    _newPasswordFocusNode.addListener(() {
      if (!_newPasswordFocusNode.hasFocus) {
        _formKey.currentState?.validate();
      }
    });
  }

  void clearControllers() {
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _currentPasswordController.clear();
  }

  void _changePassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isSubmitting = true;
      });

      final currPassword = _currentPasswordController.text.trim();
      final newPassword = _newPasswordController.text.trim();
      final token = await secureStorage.getToken();

      try {
        final response =
            await apiService.changePassword(token!, currPassword, newPassword);

        if (response.isNotEmpty) {
          popUp(context, response);
          clearControllers();
        }
      } catch (e) {
        popUp(
          context,
          'An error occured: $e',
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff4A8AF0),
        leading: IconButton(
          splashColor: Colors.transparent,
          icon: const Icon(Icons.arrow_back_ios),
          color: const Color(0xffFFFEF7),
          onPressed: () {
            Navigator.of(context).pop(context);
          },
        ),
        title: const Text("Change password",
            style: TextStyle(
              fontSize: 18,
              color: Color(0xffFFFEF7),
              fontWeight: FontWeight.bold,
            )),
      ),
      body: Stack(children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildPasswordInput('Current password',
                        _currentPasswordController, '', null, null),
                    const SizedBox(height: 16),
                    _buildPasswordInput(
                        'New password',
                        _newPasswordController,
                        'At least 8 characters',
                        _newPasswordFocusNode,
                        _validateNewPassword),
                    const SizedBox(height: 16),
                    _buildPasswordInput(
                        'Confirm password',
                        _confirmPasswordController,
                        'At least 8 characters',
                        null,
                        null),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isButtonEnabled ? _changePassword : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A8AF0),
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      child: const Text(
                        'Update password',
                        style: TextStyle(
                          color: Color(0xffFFFEF7),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () {},
                child: const Text(
                  "Forgot password?",
                  style: TextStyle(
                    color: Color(0xff4A8AF0),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isSubmitting) const LoadingAnimation(),
      ]),
    );
  }

  Widget _buildPasswordInput(
    String labelTxt,
    TextEditingController controller,
    String hintText,
    FocusNode? focusNode,
    String? Function(String?)? validator,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            labelTxt,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            border: borderStyle,
            enabledBorder: borderStyle,
            focusedBorder: borderStyle,
            errorBorder: borderStyle,
            focusedErrorBorder: borderStyle,
            hintText: hintText,
          ),
          obscureText: true,
          validator: validator,
        ),
      ],
    );
  }

  final OutlineInputBorder borderStyle = OutlineInputBorder(
    borderRadius: BorderRadius.circular(30.0),
    borderSide: BorderSide(color: const Color(0xff4A8AF0).withOpacity(0.4)),
  );

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    } else if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    return null;
  }

  void _checkPasswordMatch() {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final currentPassword = _currentPasswordController.text;

    setState(() {
      _isButtonEnabled = currentPassword.isNotEmpty &&
          newPassword.isNotEmpty &&
          confirmPassword.isNotEmpty &&
          newPassword == confirmPassword &&
          newPassword.length > 7;
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newPasswordFocusNode.dispose();
    super.dispose();
  }
}
