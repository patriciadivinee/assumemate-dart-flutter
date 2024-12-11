import 'package:flutter/material.dart';
import 'package:assumemate/logo/pop_up.dart';
import 'package:assumemate/service/service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final ApiService apiService = ApiService();

  void _requestResetPassword() async {
    setState(() {
      _isLoading = true;
    });

    String email = _emailController.text.trim();

    try {
      final response = await apiService.requestResetPassword(email);

      if (response.containsKey('message')) {
        popUp(context, response['message']);
      } else {
        popUp(context, response['error']);
      }
    } catch (e) {
      popUp(context, 'An error occured: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffFFFCF1),
        leading: IconButton(
          splashColor: Colors.transparent,
          icon: const Icon(Icons.arrow_back_ios),
          color: Colors.black,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please check your email to continue to reset your password.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            const Text(
              'Enter the email address associated with your account, and we\'ll send you an email with a link to reset your password.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
            const SizedBox(height: 50),
            Form(
                key: _formKey,
                child: Column(children: [
                  TextFormField(
                    controller: _emailController,
                    style: const TextStyle(fontSize: 12),
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(15),
                      hintText: 'EMAIL',
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: const BorderSide(
                            color: Colors.black,
                          )),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: const BorderSide(
                            color: Colors.black,
                          )),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: const BorderSide(
                            color: Colors.black,
                          )),
                      prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 12, right: 10),
                          child: Icon(Icons.email)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                          .hasMatch(value)) {
                        return "Please enter a valid email";
                      }
                      return null;
                    },
                  ),
                ])),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: (_isLoading)
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        _requestResetPassword();
                      }
                    },
              style: ButtonStyle(
                backgroundColor:
                    WidgetStateProperty.all(const Color(0xff4A8AF0)),
                minimumSize: WidgetStateProperty.all(const Size(150, 50)),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
              child: (_isLoading)
                  ? const SizedBox(
                      height: 30,
                      width: 30,
                      child: CircularProgressIndicator(
                        color: Color(0xffFFFCF1),
                      ),
                    )
                  : const Text(
                      "Send link",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
