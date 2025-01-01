import 'package:assumemate/format.dart';
import 'package:assumemate/logo/pop_up.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RateListPage extends StatefulWidget {
  final String user_id;
  final String list_id;
  final dynamic images;

  const RateListPage(
      {super.key,
      required this.user_id,
      required this.list_id,
      required this.images});

  @override
  State<RateListPage> createState() => _RateListPageState();
}

class _RateListPageState extends State<RateListPage> {
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
      popUp(context, 'Failed to submit feedback: missing configuration');
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
          'list_id': widget.list_id,
          'rating_value': _rating,
          'review_comment': _comment,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.of(context).pop(context);
        popUp(context, 'Feedback submitted successfully!');
      } else {
        print('Error: ${response.body}');
        popUp(context, 'Failed to submit feedback');
      }
    } catch (e) {
      print('Exception caught: $e');
      popUp(context, 'An error occured: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Give Feedback'),
        leading: IconButton(
          splashColor: Colors.transparent,
          icon: const Icon(
            Icons.arrow_back_ios,
          ),
          color: const Color(0xffFFFEF7),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
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
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.network(
                      widget.images[0]!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const Text(
                'How would you rate this listing?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      _rating > index
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 40,
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
              const SizedBox(height: 10),
              const Text(
                'Would you like to share more about your experience of this listing?',
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 10),
              TextField(
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Provide your feedback here',
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                  enabledBorder: borderStyle.copyWith(
                      borderRadius: BorderRadius.circular(5.0)),
                  focusedBorder: borderStyle.copyWith(
                      borderRadius: BorderRadius.circular(5.0)),
                  border: borderStyle.copyWith(
                      borderRadius: BorderRadius.circular(5.0)),
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
                    if (_rating > 0) {
                      if (_formKey.currentState!.validate()) {
                        _submitRating(); // Call the Future function
                      }
                    } else {
                      popUp(context, 'Please select rating for this listing');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color.fromARGB(255, 38, 142, 226),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text(
                    'SUBMIT',
                    style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
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
