import 'package:flutter/material.dart';
import 'package:assumemate/components/listing_item.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ListingRequestScreen extends StatefulWidget {
  @override
  _ListingRequestScreenState createState() => _ListingRequestScreenState();
}

class _ListingRequestScreenState extends State<ListingRequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<dynamic>> pendingListings;
  late Future<List<dynamic>> approvedListings;
  late Future<List<dynamic>> rejectedListings;
  final SecureStorage secureStorage = SecureStorage();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    rejectedListings = fetchUserListings('REJECTED');
    pendingListings = fetchUserListings('PENDING');
    approvedListings = fetchUserListings('APPROVED');
  }

  Future<List<dynamic>> fetchUserListings(String status) async {
    final token = await secureStorage.getToken();

    final String? baseURL = dotenv.env['API_URL'];

    final response = await http.get(
      Uri.parse('$baseURL/assumptor/all/$status/app/listings/'),
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
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              mainAxisExtent: MediaQuery.of(context).size.width * .50,
            ),
            physics: const BouncingScrollPhysics(),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var listing = snapshot.data![index];

              return ListingItem(
                listing: listing,
              );
            },
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabTextStyle =
        GoogleFonts.poppins(textStyle: const TextStyle(fontSize: 13));

    return Scaffold(
        appBar: AppBar(
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            splashColor: Colors.transparent,
            icon: const Icon(
              Icons.arrow_back_ios,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: const Text('Listing Applications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xffFFFCF1),
          bottom: TabBar(
            labelColor: Colors.black,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: UnderlineTabIndicator(
              borderSide: const BorderSide(
                width: 4,
                color: Color(0xff4A8AF0),
              ),
              insets: const EdgeInsets.symmetric(
                horizontal: (30 - 4) / 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            controller: _tabController,
            tabs: [
              Tab(child: Text('Rejected', style: tabTextStyle)),
              Tab(child: Text('Pending', style: tabTextStyle)),
              Tab(child: Text('To Pay', style: tabTextStyle)),
            ],
          ),
        ),
        body: Container(
          padding: const EdgeInsets.all(10),
          child: TabBarView(
            controller: _tabController,
            children: [
              buildListingGrid(rejectedListings),
              buildListingGrid(pendingListings),
              buildListingGrid(approvedListings),
            ],
          ),
        ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
