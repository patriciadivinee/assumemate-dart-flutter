import 'package:assumemate/components/listing_item.dart';
import 'package:flutter/material.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HighlightedItemScreen extends StatefulWidget {
  const HighlightedItemScreen({super.key});

  @override
  State<HighlightedItemScreen> createState() => _HighlightedItemScreenState();
}

class _HighlightedItemScreenState extends State<HighlightedItemScreen> {
  List<dynamic> promoted = []; // Define promoted list
  final SecureStorage _secureStorage = SecureStorage();
  Map<int, String> userProfiles = {}; // Cache user profiles

  @override
  void initState() {
    super.initState();
    fetchPromoted();
  }

  Future<void> fetchPromoted() async {
    String? token = await _secureStorage.getToken();

    final response = await http.get(
      Uri.parse('${dotenv.env['API_URL']}/promote/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      try {
        List<dynamic> fetchedPromoted = json.decode(response.body);
        setState(() {
          promoted = fetchedPromoted;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unexpected data format')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load promoted listings')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        title: const Text('Highlights',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            )),
        backgroundColor: const Color(0xffFFFCF1),
      ),
      body: Padding(
          padding: const EdgeInsets.only(left: 10, right: 10, top: 5),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              mainAxisExtent: MediaQuery.of(context).size.width * .50,
            ),
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final favorite = promoted[index];

              final listId = favorite['list_id'];
              final listingId = listId['list_id']?.toString() ?? '';

              // Check if listing is valid before building
              if (listingId.isEmpty) {
                return SizedBox();
              }

              return ListingItem(
                listing: listId,
              );
            },
            itemCount: promoted.length,
          )),
    );
  }
}
