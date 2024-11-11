import 'package:flutter/material.dart';
import 'package:assumemate/components/listing_item.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ListingRequestScreen extends StatefulWidget {
  @override
  _ListingRequestScreenState createState() => _ListingRequestScreenState();
}

class _ListingRequestScreenState extends State<ListingRequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<dynamic>> pendingListings;
  late Future<List<dynamic>> approvedListings;
  final SecureStorage secureStorage = SecureStorage();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Fetch the listings for each tab
    pendingListings = fetchUserListings('PENDING');
    approvedListings = fetchUserListings('APPROVED');
  }

  Future<List<dynamic>> fetchUserListings(String status) async {
    final token = await secureStorage.getToken();
    final response = await http.get(
      Uri.parse(
          'http://192.168.254.137:8000/api/user/listings2/?status=$status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['listings'];
    } else {
      // Return an empty list and show a message instead of throwing an error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load $status listings'),
          duration: Duration(seconds: 3),
        ),
      );
      return []; // Return an empty list in case of failure
    }
  }

  Widget buildListingGrid(Future<List<dynamic>> futureListings) {
    return FutureBuilder<List<dynamic>>(
      future: futureListings,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
              child: Text('Failed to load listings: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No listings available'));
        } else {
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              mainAxisExtent: 190,
            ),
            physics: const BouncingScrollPhysics(),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var listing = snapshot.data![index];
              var content = listing['list_content'];
              return ListingItem(
                title: content['title'] ?? 'No Title',
                imageUrl: content['images'],
                description: content['description'] ?? 'No Description',
                listingId: listing['list_id'].toString(),
                assumptorId: listing['user_id'].toString(),
                price: content['price'].toString(),
              );
            },
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Listing Requests'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildListingGrid(pendingListings), // Grid for pending listings
          buildListingGrid(approvedListings), // Grid for approved listings
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
