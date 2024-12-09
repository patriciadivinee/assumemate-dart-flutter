import 'package:assumemate/components/listing_item.dart';
import 'package:assumemate/logo/pop_up.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:assumemate/service/service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AssumptorListingScreen extends StatefulWidget {
  const AssumptorListingScreen({super.key});

  @override
  State<AssumptorListingScreen> createState() => _AssumptorListingScreenState();
}

class _AssumptorListingScreenState extends State<AssumptorListingScreen> {
  // List<Map<String, dynamic>> _listings = [];
  late Future<List<dynamic>> _activeListings;
  late Future<List<dynamic>> _reservedListings;
  late Future<List<dynamic>> _archivedListings;
  late Future<List<dynamic>> _soldListings;

  final ApiService apiService = ApiService();
  final SecureStorage secureStorage = SecureStorage();

  Future<List<dynamic>> fetchUserListings(String status) async {
    final token = await secureStorage.getToken();

    final String? baseURL = dotenv.env['API_URL'];

    final response = await http.get(
      Uri.parse('$baseURL/assumptor/all/$status/listings/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      print(data);
      return data['listings'];
    } else {
      // Return an empty list and show a message instead of throwing an error
      popUp(context, 'Failed to load $status listings');
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
  void initState() {
    _activeListings = fetchUserListings('ACTIVE');
    _reservedListings = fetchUserListings('RESERVED');
    _archivedListings = fetchUserListings('ARCHIVED');
    _soldListings = fetchUserListings('SOLD');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final tabTextStyle =
        GoogleFonts.poppins(textStyle: const TextStyle(fontSize: 13));

    return DefaultTabController(
      length: 4,
      child: Scaffold(
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
            title: const Text('Listings',
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
              tabs: [
                Tab(
                    child: Text(
                  'Active',
                  style: tabTextStyle,
                )),
                Tab(
                    child: Text(
                  'Reserved',
                  style: tabTextStyle,
                )),
                Tab(
                    child: Text(
                  'Sold',
                  style: tabTextStyle,
                )),
                Tab(
                    child: Text(
                  'Archive',
                  style: tabTextStyle,
                )),
              ],
            ),
          ),
          body: Container(
              padding: const EdgeInsets.all(10),
              child: TabBarView(
                children: [
                  buildListingGrid(_activeListings),
                  buildListingGrid(_reservedListings),
                  buildListingGrid(_soldListings),
                  buildListingGrid(_archivedListings),
                ],
              ))),
    );
  }
}
