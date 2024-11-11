// add_listing.dart
import 'package:flutter/material.dart';
import 'car_form.dart';
import 'restate.dart';
import 'motorform.dart';

class AddListing extends StatefulWidget {
  final String category;

  // Constructor to accept category
  AddListing({Key? key, required this.category}) : super(key: key);

  @override
  _AddListingState createState() => _AddListingState();
}

class _AddListingState extends State<AddListing> {
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
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Add Listing",
          style: TextStyle(
            fontSize: 20,
            color: Color(0xffFFFEF7),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Check the category passed to decide which form to display
            if (widget.category == 'Car')
              CarForm()
            else if (widget.category == 'Real Estate')
              Restate()
            else if (widget.category == 'Motorcycle')
              MotorForm()
            else
              Center(child: Text('Invalid Category')),
          ],
        ),
      ),
    );
  }
}