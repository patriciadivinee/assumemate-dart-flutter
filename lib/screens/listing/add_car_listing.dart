// add_listing.dart
import 'package:flutter/material.dart';
import 'car_form.dart'; // Import the new file for CarForm
import 'restate.dart';
import 'motorform.dart';

class AddListing extends StatefulWidget {
  @override
  _AddListingState createState() => _AddListingState();
}

class _AddListingState extends State<AddListing> {
  String? selectedCategory;

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
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedCategory,
              hint: Text('Select Category'),
              items: ['Car', 'Real Estate', 'Motorcycle']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
            ),
            if (selectedCategory == 'Car')
              CarForm() // Call the CarForm widget
            // Other forms can be built here based on the selected category
            else if (selectedCategory == 'Real Estate')
              Restate() // Placeholder for Real Estate form
            else if (selectedCategory == 'Motorcycle')
              MotorForm()
          ],
        ),
      ),
    );
  }
}
