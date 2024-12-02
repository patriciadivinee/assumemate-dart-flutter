import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RateUserPage extends StatefulWidget {
  final String user_id;

  RateUserPage(this.user_id);

  @override
  _RateUserPageState createState() => _RateUserPageState();
}

class _RateUserPageState extends State<RateUserPage> {
  final _formKey = GlobalKey<FormState>();
  double _rating = 0.0;
  String _comment = '';
  final String? baseURL = dotenv.env['API_URL'];
  final secureStorage = SecureStorage();

  Future<void> _submitRating() async {
    // Retrieve the token from secure storage
    String? token = await secureStorage.getToken();

    // Check if baseURL and token are available
    if (baseURL == null || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to submit feedback: missing configuration')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseURL/rate/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'to_user_id': widget.user_id,
          'rating_value': _rating,
          'review_comment': _comment,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback submitted successfully!')),
        );
      } else {
        print('Error: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit feedback')),
        );
      }
    } catch (e) {
      print('Exception caught: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Give Feedback'),
        backgroundColor: const Color.fromARGB(255, 38, 142, 226),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How would you rate this user?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      _rating > index
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 55,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = index + 1.0;
                      });
                      print('Rating set to: $_rating');
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              const Text(
                'Would you like to share more about your experience of this user?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Provide your feedback here',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                ),
                onChanged: (value) {
                  _comment = value;
                  print('Comment updated: $_comment');
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _submitRating(); // Call the Future function
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color.fromARGB(255, 38, 142, 226),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text(
                    'SUBMIT',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
